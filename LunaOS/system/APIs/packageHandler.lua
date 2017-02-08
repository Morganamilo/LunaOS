local url = lunaOS.getProp("serverURL")

local tmp = lunaOS.getProp("tmpPath")
local dataPath = lunaOS.getProp("dataPath")
local systemDataPath = lunaOS.getProp("systemDataPath")
local packagePath = lunaOS.getProp("packagePath")
local APIPath = lunaOS.getProp("APIPath")
local manifestPath = lunaOS.getProp("manifestPath")
local fs = fs

local required = {"name", "desc", "version", "release", "author"}
local optional = {"data", "api", "main"}
--optional data, depend, api



local function verifyPackage(installData, packageData)
	if type(installData.name) ~= "string" then
		return nil, "Missing required field: name"
	end

	if type(installData.desc) ~= "string" then
		return nil, "Missing required field: desc"
	end

	if type(installData.version) ~= "string" then
		return nil, "Missing required field: version"
	end

	if not installData.release then
		return nil, "Missing required field: release"
	end

	if type(installData.release) ~= "number" or math.floor(installData.release) ~= installData.release then
		return nil, "realease must be an integer"
	end

	if type(installData.author) ~= "string" then
		return nil, "Missing required field: author"
	end

	for _, field in pairs(optional) do
		print(field)
		if type(installData[field]) ~= "table" and type(installData[field]) ~= "nil" then
			return nil, field .. " should either be nil or table"
		end
		if installData[field] then
			for _, path in pairs(installData[field]) do
				print(path)
				if type(path) ~= "string" then
					return nil, field .. ": " .. path .. " should be string"
				end

				if path:find("%.%.") then
					return nil, field .. ": " .. path .. " can not contain '..'"
				end

				if path:find("[\\/]") then
					return nil, field .. ": " .. path .. " can not contain directories"
				end

				if not packageData.files[fs.combine(path, "")] then
					return nil, "Missing: " .. path
				end
			end
		end

	end

	--make sure its not already installed
	if tableUtils.indexOf(getInstalled(), installData.name) then
		return nil, "Package already installed"
	end


--	for path, data in pairs(installData.main) do
--		if path:find("[\\/]") then
--			return nil, "main files can not contain directories"
--		end
--
--		if fs.exists(fs.combine(packagePath, path)) then
--			return nil, "main: " .. path .. "already exists"
--		end
--	end
	return true
end


function getInstalled()
	local packageData = jsonUtils.decodeFile(manifestPath)
	local names = {}


	for k, v in pairs(packageData) do
		names[#names + 1] = v.name
	end

	return names
end

function getPackageData(name)
	local packageData = jsonUtils.decodeFile(manifestPath)

	for k, v in pairs(packageData) do
		if v.name == name then
			return v
		end
	end

	return false
end

function installPackage(package)
	if not kernel.isSU() then
		return nil, "SuperUser is needed to install packages"
	end
	
	--get the name
	local fileName = fs.getName(package)
	local success, packageData = pcall(jsonUtils.decodeFile, package)

	if not success then
		return nil, "Can not unpack package"
	end
	
	local installDataJSON = packageData.files["install.json"]

	if not installDataJSON then
		return nil, "Missing install.json"
	end
	
	local success, installData = pcall(jsonUtils.decode, installDataJSON)
	if not installData then
		return nil, "Can not unpack install.lua"
	end

	local success, res = verifyPackage(installData, packageData)
	if not success then
		return nil, res
	end
--
--	if installData.data then
--		for k, v in pairs(installData.data) do
--			local file = fs.open(fs.combine(dataPath, installData.name))
--
--			if not file then
--				error("Can not open " .. fs.combine(dataPath, installData.name), "w")
--			end
--
--			file.write(data)
--		end
--	end
--
--	if installData.APIs then
--		for k, v in pairs(installData.APIs) do
--			fs.move(fs.combine(tmpPackage, v), _G.fs.combine(APIPath, v))
--		end
--	end
--
--	if installData.main then
--		for k, v in pairs(installData.main) do
--			fs.move(fs.combine(tmpPackage, v), _G.fs.combine(APIPath, v))
--		end
--	end
--
--	fs.move(fs.combine(tmpPackage, installData.main), fs.combine(packagePath, installData.main))
--	fs.move(fs.combine(tmpPackage, "install.json"), _G.fs.combine(systemDataPath, "packages", installData.name))
--
--	fs.delete(tmpPackage)

	local manifest = jsonUtils.decodeFile(manifestPath)
	manifest[#manifest + 1] = installData
	jsonUtils.encodeToFile(manifest, manifestPath, true)

	if installData.data then
		for k, v in pairs(installData.data) do
			local path = fs.combine(dataPath, v)
			local file = fs.open(path, "w")
			if not file then
				error("Can not open " .. path)
			end
			file.write(packageData.files[v])
			file.close()
		end
	end

	if installData.main then
		for k, v in pairs(installData.main) do
			local path = fs.combine(packagePath, v)
			local file = fs.open(path, "w")
			if not file then
				error("Can not open " .. path)
			end
			file.write(packageData.files[v])
			file.close()
		end
	end

	if installData.apis then
		for k, v in pairs(installData.apis) do
			local path = fs.combine(APIPath, v)
			local file = fs.open(path, "w")
			if not file then
				error("Can not open " .. path)
			end
			file.write(packageData.files[v])
			file.close()
		end
	end

	return true
end

function removePackage(name)
	if not kernel.isSU() then
		return nil, "SuperUser is needed to remove packages"
	end

	local installData, err = getPackageData(name)

	if not installData then
		return nil, err
	end


	if installData.data then
		for k, v in pairs(installData.data) do
			local path = fs.combine(dataPath, v)
			fs.delete(path)
		end
	end

	if installData.main then
		for k, v in pairs(installData.main) do
			local path = fs.combine(packagePath, v)
			fs.delete(path)
		end
	end

	if installData.apis then
		for k, v in pairs(installData.apis) do
			local path = fs.combine(APIPath, v)
			fs.delete(path)
		end
	end

	local manifestData = jsonUtils.decodeFile(manifestPath)
	local index

	for k, v in pairs(manifestData) do
		if v.name == name then
			index = k
			break
		end
	end

	table.remove(manifestData, index)
	jsonUtils.encodeToFile(manifestData, manifestPath)

	return true
end

if not fs.exists(manifestPath) then
	local file = fs.open(manifestPath, "w")
	file.write("[]")
	file.close()
end
