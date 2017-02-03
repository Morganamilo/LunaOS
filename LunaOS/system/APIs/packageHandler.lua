local url = lunaOS.getProp("serverURL")

local tmp = lunaOS.getProp("tmpPath")
local dataPath = lunaOS.getProp("dataPath")
local systemDataPath = lunaOS.getProp("systemDataPath")
local packagePath = lunaOS.getProp("packagePath")
local fs = fs

local required = {"name", "desc", "version", "release", "author", "reslease", "main"}
--optional data, depend

local function verifyPackage(installData, packagePath)
	for k,v in pairs(required) do
		if not type(installData[v]) == "string" then
			return nil, "install.json: mising " .. v
		end
	end

	if installData.name:find("[\\/]") then
		return nil, "install.json: name can not inclide \\ or /"
	end

	if installData.main:find("[\\/]") then
		return nil, "install.json: main can not inclide \\ or /"
	end

	if not _G.fs.isFile(fs.combine(packagePath, installData.main)) then
		return nil, "install.json: [" .. package.main .. "] does not exist"
	end

	if type(installData.data) ~= "nil" and type(installData.data) ~= "table" then
		return nil, "install.json: invalid data"
	end

	if type(installData.depend) ~= "nil" and type(installData.depend) ~= "table" then
		return nil, "install.json: invalid depend"
	end

	for k, v in pairs(installData.data) do
		if type(v) ~= "string" then
			return nil, "install.json: data value is not a string"
		end

		if not _G.fs.isFile(fs.combine(packagePath, v)) then
			return nil, "install.json: [" .. v .. "] does not exist"
		end
	end

	for k, v in pairs(installData.depend) do
		if type(v) ~= "string" then
			return nil, "install.json: depend value is not a string"
		end
	end

	return true
end


function listInstalled()
	return fs.list(fs.combine(systemDataPath, "packages"))
end

function getPackageData(name)
	local filePath = _G.fs.combine(systemDataPath, "packages", name)

	if not fs.exists(filePath) or fs.isDir(filePath) then
		return nil, "Package does not exist"
	end

	local file = fs.open(filePath, "r")

	if not file then
		return nil, "Can not open package data"
	end

	local data = file.readAll()
	file.close()

	local success, json = pcall(jsonUtils.decode, data)

	if not success then
		return nil, "Can not unpack package"
	end

	return json
end


function installPackage(package)
	if not kernel.isSU() then
		return nil, "SuperUser is needed to install packages"
	end
	
	local packageName = fs.getName(package)
	local tmpPackage = fs.combine(tmp, package)
	local installer = fs.combine(tmpPackage, "install.json")
	
	if #packagePath <= 1 then
		return nil, "Invalid tmp path"
	end

	fs.delete(tmpPackage)
	lzip.unZipToDir(package, tmpPackage)

	if not _G.fs.isFile(installer) then
		return nil, "Missing insall.json"
	end

	local success, installData = pcall(jsonUtils.decodeFile, installer)

	if not success then
		return nil, "Can not unpack package"
	end
	
	if tableUtils.indexOf(getInstalled(), installData.name) then
		return nil, "Package already installed"
	end
	
	local res, err = verifyPackage(installData, tmpPackage)

	if not res then
		return nil, err
	end

	fs.delete(_G.fs.combine(dataPath, installData.name))
	fs.delete(_G.fs.combine(packagePath, installData.main))
	fs.delete(_G.fs.combine(systemDataPath, "packages", installData.name))

	if installData.data then
		for k, v in pairs(installData.data) do
			fs.move(fs.combine(tmpPackage, v), _G.fs.combine(dataPath, installData.name, v))
		end
	end

	fs.move(fs.combine(tmpPackage, installData.main), fs.combine(packagePath, installData.main))
	fs.move(fs.combine(tmpPackage, "install.json"), _G.fs.combine(systemDataPath, "packages", installData.name))

	fs.delete(tmpPackage)

	return true
end

function removePackage(name)
	if not kernel.isSU() then
		return nil, "SuperUser is needed to remove packages"
	end

	local data, err = getPackageData(name)

	if not data then
		return nil, err
	end

	fs.delete(_G.fs.combine(dataPath, name))
	fs.delete(_G.fs.combine(packagePath, data.main))
	fs.delete(_G.fs.combine(systemDataPath, "packages", name))

	return true
end
