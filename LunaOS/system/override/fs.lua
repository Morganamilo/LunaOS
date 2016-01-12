local oldFs = fs

-- exists = oldFs.exists --
-- isDir = oldFs.isDir --
-- isReadOnly = oldFs.isReadOnly--
-- getDrive = oldFs.getDrive--
-- getSize = oldFs.getSize--
-- getFreeSpace = oldFs.getFreeSpace--
-- makeDir = oldFs.makeDir--
-- move = oldFs.move--
-- copy = oldFs.copy--
-- delete = oldFs.delete--
-- open = oldFs.open--
-- find = oldFs.find--
-- complete = oldFs.complete--
-- list = oldFs.list--

getName = oldFs.getName
getDir = oldFs.getDir

local function getPerm(path) --gives the perm inside the given directory, otherwise jumps up a level and tries again
	errorUtils.assert(oldFs.exists(path), "Error: Path does not exists")
	
	local dir = path
	if not oldFs.isDir(path) then path = getDir(path) end --if we got sent a file jump up a level
	
	repeat
		if oldFs.exists(fs.combine(dir,".!perm")) then
			local file = oldFs.open(fs.combine(dir, ".!perm"), 'r')
			if file then
				local line = file.readLine()
				file.close()
				
				return line
			else
				error("Error opening file", 3)
			end
		end
		
		dir = getDir(dir)
	until (dir == '')
	
	return 0 --theres no permision file so give none
end

local function getLowestPerm(path)
	if not oldFs.isDir(path) then return getPerm(oldFs.getDir(path)) end --this function in made for directories, use this incase we get a file
	
	local allSubs = listAllSubDirs(path)
	local low = "2"
	
	for _, v in pairs(allSubs) do
		if not hasReadPerm(v) then return "0" end
		if not hasWritePerm(v) then low = "1" end
	end
	
	return low
end

function hasReadPerm(path)
	if kernel.isSU() then return true end --super user can read all
	
	local permData = getPerm(path)
	if permData == "1" or permData == "2" then return true end
	
	return false
end

function hasWritePerm(path)
	if oldFs.isReadOnly(path) then return false end --superuser cant write to rom and mounts
	if kernel.isSU() then return true end --otherwise superuser can write to all
	
	local permData = getPerm(path)
	if permData == "2" then return true end
	
	return false
end

function hasReadPermAllChildren(path) --like hasReadPerm but goes through all sub directories and given the lowest permission
	if kernel.isSU() then return true end
	
	local permData = getLowestPerm(path)
	if permData == "1" or permData == "2" then return true end
	
	return false
end

function hasWritePermAllChildren(path)	
	local permData = getLowestPerm(path)
	if permData == "2" then return true end
	
	return false
end

function isReadOnly(path) --this function is only really here for to keep the functionality of the default fs API
	if oldFs.isReadOnly(path) then return true end
	if kernel.isSU() then return false end
	
	local permData = getPerm(path)
	if permData then
		if permData == "0" or permData == "1" then return true end --0 is not read only but some programs will check using this function and returning false would make them assume they can write
	end
	
	return false
end

function setPerm(path, perm) --only superuser can set permissions
	errorUtils.assert(type(path) == "string", "Error: string expected got " .. type(path), 2)
	errorUtils.assert(type(perm) == "string", "Error: string expected got " .. type(perm), 2)
	
	local rawPerm
	
	if perm == "n" then rawPerm = "0"
	elseif perm == "r" then rawPerm = "1"
	elseif perm == "rw" then rawPerm = "2" 
	else error("Error: invalid permision value", 2) end
	
	if (not kernel.isSU()) or oldFs.isReadOnly("path") then error("Error: permision denied", 2) end
	
	errorUtils.assert(oldFs.isDir(path), "Error, not a directory", 2)
	
	local file = errorUtils.assert(oldFs.open(oldFs.combine(path, ".!perm"), 'w'), "Error opening file", 2)
	
	file.write(rawPerm)
	file.close()
	
	--we have writen the file, now overide the child directories
	for _, v in pairs(listAllSubDirs(path)) do
		if not oldFs.isReadOnly(fs.combine(v, ".!perm")) then
			if fs.exists(fs.combine(v, ".!perm")) then
				fs.delete(fs.combine(v, ".!perm"))
			end
		end
	end
	
	return true
end
 
function list(path)
	errorUtils.assert(oldFs.isDir(path), "Error, not a directory", 2)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)

	local list = oldFs.list(path)
	local correctedList = {}
	
	for _, v in pairs(list) do
		if hasReadPerm(fs.combine(path, file)) then
			correctedList[#correctedList + 1] = v
		end
	end
	
	return correctedList
end

function listDirs(path)
	errorUtils.assert(oldFs.isDir(path), "Error, not a directory", 2)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	
	local list = oldFs.list(path)
	local dirs = {}
	
	for _, v in pairs(list) do
		if oldFs.isDir(fs.combine(path, v)) then dirs[#dirs + 1] = v end
	end
	
	return dirs
end

function listFiles(path)
	errorUtils.assert(oldFs.isDir(path), "Error, not a directory", 2)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	local list = oldFs.list(path)
	local files = {}
	
	for _, v in pairs(list) do
		if fs.isFile(fs.combine(path, v)) then files[#files + 1] = v end
	end
	
	return files
end

function listAllSubDirs(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	
	local subDirs = {path}
	local i = 1
	
	while subDirs[i] do
		local currentPath = subDirs[i]
		local subs = listDirs(currentPath)
		
		for _, v in pairs(subs) do
				subDirs[#subDirs + 1] = combine(currentPath, v)
		end
		
		i = i + 1
	end
	
	table.remove(subDirs, 1)
	return subDirs
end

function combine(...)
	local combinedString = ''

	for _, v in ipairs(arg) do
		combinedString = oldFs.combine(combinedString, v)
	end
	
	return combinedString
end

function exists(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied1", 2)
	return oldFs.exists(path)
end

function isFile(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied2", 2)
	return (oldFs.exists(path) and not oldFs.isDir(path))
end

function isDir(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	return oldFs.isDir(path)
end

function getDrive(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	return oldFs.getDrive(path)
end

function getSize(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	return oldFs.getSize
end

function getFreeSpace(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	return oldFs.getFreeSpace(path)
end

function makeDir(path)
	errorUtils.assert(hasWritePerm(path), "Error permision denied", 2)
	oldFs.makeDir(path)
end

function move(scr, dest)
	errorUtils.assert(hasWritePermAllChildren(scr) and hasWritePermAllChildren(dest), "Error permision denied", 2)
	oldFs.move(scr, dest)
end

function copy(scr, dest)
	errorUtils.assert(hasReadPermAllChildren(path) and hasWritePermAllChildren(dest), "Error permision denied", 2)
	oldFs.copy(scr, dest)
end

function delete(path)
	errorUtils.assert(hasWritePermAllChildren(path), "Error permision denied", 2)
	oldFs.delete(path)
end

function open(path, mode)
	local check
	if mode == "r" or mode == "rb" then check = hasReadPerm(path)
	elseif mode == "w" or mode == "wb" or mode == "a" or mode == "ab" then hasWritePerm(path) end
	
	errorUtils.assert(check, "Error permision denied ", 2)
	return oldFs.open(path, mode)
end

function complete(path)
	errorUtils.assert(hasReadPerm(path), "Error permision denied", 2)
	return oldFs.complete(path)
end

function find(path)
	list = oldFs.find(path)
	local correctedList = {}
	
	for _, v in pairs(list) do
		if hasReadPerm(v) then correctedList[#correctedList + 1] = v end
	end
	
	return correctedList
end