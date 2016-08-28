local oldFs = fs
local permData
local permPath = lunaOS.getProp("permPath")
local dataPath = lunaOS.getProp("dataPath")

getName = oldFs.getName
getDir  = oldFs.getDir

--------------------------------------------------------------------------------------
--permissions
--------------------------------------------------------------------------------------

--store perm data in memory for faster access
--only use the file if we are changing a perm and not just reading 

--0 = nothing
--1 = read only
--2 = write only
--3 = read and write

 function getPermData()
	local file = errorUtils.assert(oldFs.open(permPath, "r"), "Error: File Permissions are missing", 0)
	local data = file.readAll()
	file.close()
	
	return errorUtils.assert(jsonUtils.decode(data), "Error: File permissions are corupt", 0)
end

local function saveData()
	local file = oldFs.open(permPath, "w")
	local data = jsonUtils.encode(permData)
	file.write(data)
	file.close()	
end

local function deletePerm(path)
	if oldFs.isDir(path) then
		for _,v in pairs(listAllSubObjects(path)) do
			permData[combine(v):lower()] = nil
		end
	end
	
	permData[combine(path):lower()] = nil
	
	saveData()
end

local function copyPerm(scr, dest)
	if oldFs.isDir(scr) then
		for _,v in pairs(listAllSubObjects(scr, 1)) do
			permData[combine(dest, v):lower()] = permData[combine(scr, v):lower()]
		end
	end
	
	permData[combine(dest):lower()] = permData[combine(scr):lower()]
	
	saveData()
end

function setPerm(path, perm)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.expect(perm, "number", true, 2)
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	errorUtils.assert(oldFs.exists(path), "Error: File does not exist", 2)
	errorUtils.assert(perm >= 0 and perm <= 3, "Error: Invalid permission", 2)
	
	permData[combine(path):lower()] = perm
	saveData()
end

function setPermTree(path, perm)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.expect(perm, "number", true, 2)
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	errorUtils.assert(perm >= 0 and perm <= 3, "Error: Invalid permission", 2)
	
	permData[combine(path):lower()] = perm
	
	for _,v in pairs(listAllSubObjects(path)) do
		permData[combine(v):lower()] = perm
	end
	
	saveData()
end

function getPerm(path)
	errorUtils.expect(path, "string", true, 2)
	
	if path == '' then return permData[fs.combine(path):lower()] or 1 end
	return permData[fs.combine(path):lower()] or getPerm(getDir(path))
end

function getEffectivePerm(path)
	errorUtils.expect(path, "string", true, 2)
	
	if path == '' then return getPerm(path) end
	
	local perm = 3
	while path ~= '' do
		local currentPerm = getPerm(path)
		if currentPerm == 0 then return 0
		elseif currentPerm == 2 and perm == 1 then return 0
		elseif currentPerm == 1 and perm == 2 then return 0
		elseif currentPerm < perm then perm = currentPerm end
		path = getDir(path)
	end
	
	return perm
end

function getPermTree(path)
	errorUtils.expect(path, "string", true, 2)
	if not oldFs.isDir(path) then return getPerm(path) end
	
	local objects = listAllSubObjects(path)
	local perm = 3
	
	for _,v in pairs(objects) do
		local currentPerm = getPerm(path)
		if currentPerm == 0 then return 0
		elseif currentPerm == 2 and perm == 1 then return 0
		elseif currentPerm == 1 and perm == 2 then return 0
		elseif currentPerm < perm then perm = currentPerm end
	end
	
	return perm
end

function hasReadPerm(path)
	if kernel.isSU() then return true end
	errorUtils.expect(path, "string", true, 2)
	
	local dataPath = kernel.getCurrentDataPath()
	if dataPath and isSubdirOf(dataPath, path) then 
		return true
	end
	
	local perm = getEffectivePerm(path)
	return perm == 1 or perm == 3
end

function hasReadPermTree(path)
	errorUtils.expect(path, "string", true, 2)
	if kernel.isSU() then return true end
	
	local dataPath = kernel.getCurrentDataPath()
	if dataPath and isSubdirOf(dataPath, path) then 
		return true
	end
	
	if not hasReadPerm(path) then return false end
	local permTree = getPermTree(path)
	return (permTree == 1 or permTree == 3)
end

function hasWritePerm(path)
	errorUtils.expect(path, "string", true, 2)
	if kernel.isSU() and not oldFs.isReadOnly(path) then return true end
	
	local dataPath = kernel.getCurrentDataPath()
	if dataPath and isSubdirOf(dataPath, path) then 
		return true
	end
	
	local perm = getEffectivePerm(path)
	return perm >= 2 and not oldFs.isReadOnly(path)
end

function hasWritePermTree(path)
	errorUtils.expect(path, "string", true, 2)
	if kernel.isSU() and not oldFs.isReadOnly(path) then return true end
	
	if not hasWritePerm(path) then return false end
	local permTree = getPermTree(path)
	return (permTree >= 2)
end

function isReadOnly(path)
	errorUtils.expect(path, "string", true, 2)
	return not hasWritePerm(path)  or oldFs.isReadOnly(path)
end

-----------------------------------------------------------------------------------------
--overridden functions
-----------------------------------------------------------------------------------------

--local symLinks = {}

function isSubdirOf(dir, subdir)
	errorUtils.expect(dir, "string", true)
	errorUtils.expect(subdir, "string", true)

	dir = combine(dir):lower()
	subdir = combine(subdir):lower()
	
	while subdir ~= '' and #subdir > #dir do
		subdir = getDir(subdir)
		if dir == subdir then return true end
	end
	
	return false
end

function combine(...)
	local combinedString = ''

	for _, v in ipairs(arg) do
		combinedString = oldFs.combine(combinedString, v)
	end
	
	return combinedString
end

function isFile(path)
	errorUtils.expect(path, "string", true, 2)
	return (oldFs.exists(path) and not oldFs.isDir(path))
end

function list(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	
	return oldFs.list(path)
end

function listDirs(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	
	local list = oldFs.list(path)
	local dirs = {}
	
	for _, v in pairs(list) do
		if oldFs.isDir(fs.combine(path, v)) then dirs[#dirs + 1] = v end
	end
	
	return dirs
end

function listFiles(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	
	local list = oldFs.list(path)
	local files = {}
	
	for _, v in pairs(list) do
		if fs.isFile(fs.combine(path, v)) then files[#files + 1] = v end
	end
	
	return files
end

--non recursive because of computercraft's low stack limit
function listAllSubObjects(path, includePath)
	errorUtils.expect(includePath, "number", false, 2)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	
	includePath = includePath or 2
	path = combine(path)
	
	local subObjects = {path}
	local i = 1
	
	while subObjects[i] do
		local currentPath = subObjects[i]
		local objects
		
		if hasReadPerm(currentPath) and oldFs.isDir(currentPath) then
			objects = oldFs.list(currentPath)
		
			for _, v in pairs(objects) do
					subObjects[#subObjects + 1] = combine(currentPath, v)
			end
		end
		
		i = i + 1
	end
	
	table.remove(subObjects, 1)
	
	if includePath == 0 then
		for i=1, #subObjects do
			subObjects[i] = getName(subObjects[i])
		end
	end
	
	if includePath == 1 then
		for i=1, #subObjects do
			subObjects[i] = subObjects[i]:sub(#path + 2)
		end
	end
	
	return subObjects
end

function listAllSubFiles(path, includePath)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.expect(includePath, "number", false, 2)
	errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	
	path = combine(path)
	includePath = includePath or 0
	
	local files = {}
	
	for _,v in pairs(listAllSubObjects(path, 2)) do
		if not isDir(v) then
			if includePath == 0 then v = getName(v) end
			if includePath == 1 then v = v:sub(#path + 2) end
			files[#files + 1] = v
		end
	end
	
	return files
end

function listAllSubDirs(path, includePath)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.expect(includePath, "number", false, 2)
	errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	errorUtils.assert(oldFs.isDir(path), "Error: Not a directory", 2)
	
	path = combine(path)
	includePath = includePath or 2
	
	local dirs = {}
	
	for _,v in pairs(listAllSubObjects(path, 2)) do
		if isDir(v) then
			if includePath == 0 then v = getName(v) end
			if includePath == 1 then v = v:sub(#path + 2) end
			dirs[#dirs + 1] = v
		end
	end
	
	return dirs
end

function exists(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(getDir(path)), "Error permission denied", 2)
	return oldFs.exists(path)
end

function isFile(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(getDir(path)), "Error permission denied", 2)
	return (oldFs.exists(path) and not oldFs.isDir(path))
end

function isDir(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(getDir(path)), "Error permission denied", 2)
	return oldFs.isDir(path)
end

function getDrive(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(getDir(path)), "Error permission denied", 2)
	return oldFs.getDrive(path)
end

function getSize(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(path), "Error permission denied", 2)
	return oldFs.getSize(path)
end

function getFreeSpace(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(getDir(path)), "Error permission denied", 2)
	return oldFs.getFreeSpace(path)
end

function makeDir(path)
	errorUtils.assert(hasWritePerm(path), "Error permission denied", 2)
	oldFs.makeDir(path)
	setPerm(path, getPerm(path))
end

function move(scr, dest)
	errorUtils.expect(scr, "string", true, 2)
	errorUtils.expect(dest, "string", true, 2)
	errorUtils.assert(hasWritePermTree(scr), "Error: permission denied", 2)
	errorUtils.assert(hasWritePermTree(dest), "Error: permission denied", 2)
	errorUtils.assert(fs.exists(scr), "Error: Source does not exist", 2)
	errorUtils.assert(not fs.exists(dest), "Error: Destination exists", 2)
	
	copyPerm(scr, dest)
	deletePerm(scr)
	oldFs.move(scr, dest)
end

function copy(scr, dest)
	errorUtils.expect(scr, "string", true, 2)
	errorUtils.expect(dest, "string", true, 2)
	errorUtils.assert(hasReadPermTree(scr), "Error: permission denied", 2)
	errorUtils.assert(hasWritePermTree(dest), "Error: permission denied", 2)
	errorUtils.assert(oldFs.exists(scr), "Error: Source does not exist", 2)
	errorUtils.assert(not oldFs.exists(dest), "Error: Destination exists", 2)
	
	copyPerm(scr, dest)
	oldFs.copy(scr, dest)
end

function delete(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasWritePermTree(path), "Error: permission denied", 2)
	
	deletePerm(path)
	oldFs.delete(path)
	
end

function open(path, mode)
	errorUtils.expect(path, 'string', true, 2)
	errorUtils.expect(mode, 'string', true, 2)
	
	if mode == 'r' or mode == 'rb' then
		errorUtils.assert(hasReadPerm(path), "Error: permission denied", 2)
	elseif mode == 'w' or mode == 'wb' or mode == 'a' or mode == 'ab' then
		errorUtils.assert(hasWritePerm(path), "Error: permission denied", 2)
		permData[combine(path):lower()] = getPerm(path)
	else
		error("Error: Unsupported mode")
	end
	
	return oldFs.open(path, mode)
end

function complete(name, path, includeFiles, includeSlash)
	errorUtils.expect(name, 'string', true, 2)
	errorUtils.expect(path, 'string', false, 2)
	errorUtils.expect(includeFiles, 'boolean', false, 2)
	errorUtils.expect(includeSlash, 'boolean', false, 2)
	errorUtils.assert(hasReadPerm(path), "Error permission denied", 2)
	
	return oldFs.complete(name, path, includeFiles, includeSlash)
end

function find(path)
	errorUtils.expect(path, "string", true, 2)
	errorUtils.assert(hasReadPerm(path), "Error permission denied", 2)
	
	local files = oldFs.find(path)
	local fixedFiles = {}
	
	for k, v in pairs(files) do
		if fs.hasReadPerm(fs.getDir(v)) then
			fixedFiles[#fixedFiles + 1] = v
		end
	end
	
	return fixedFiles
end

-------------------------------------------------------------------

--[[function makeSymlink(real, link)
	errorUtils.expect(real, 'string', true, 2)
	errorUtils.expect(link, 'string', true, 2)
	errorUtils.assert(hasWritePerm(link), "Error: permission denied", 2)
	errorUtils.assert(hasReadPerm(getDir(real)), "Error: permission denied", 2)
	errorUtils.assert(oldFs.exists(real), "Error: Source does not exist", 2)
	errorUtils.assert(not oldFs.exists(dest), "Error: Destination exists", 2)

	if oldFs.isDir(real) then
		oldFs.mkDir(link)
	else
		oldFs.open(link, 'w').close()
	end
	
	symLinks[combine(link):lower()] = combine(real):lower()
end

function unLink(link)
	errorUtils.expect(link, 'string', true, 2)
	errorUtils.assert(symLinks[combine(link):lower()], "Error: Not a link", 2)
	
	symLinks[combine(link):lower()] = nil
	oldFs.delete(link)
end]]

------------------------------------------------------------------------

permData = getPermData()
