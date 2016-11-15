local programDataPath = lunaOS.getProp("dataPath")
local programPath = lunaOS.getProp("programPath")
local systemProgramPath = lunaOS.getProp("systemProgramPath")
local list = fs.list
local url = lunaOS.getProp("serverURL")
local permDenied = errorUtils.strings.permDenied

function getDataPath()
	return programDataPath
end

function getProgramPath()
	return programPath
end

function getSystemProgramPath()
	return systemProgramPath
end

function getPackagePath(packageName)
	if tableUtils.indexOf(list(systemProgramPath), packageName) then
		return fs.combine(systemProgramPath, packageName)
	elseif tableUtils.indexOf(list(programPath), packageName) then
		return fs.combine(programPath, packageName)
	end
end

function getPackageDataPath(packageName)
	if tableUtils.indexOf(list(programDataPath), packageName) then
		return fs.combine(programDataPath, packageName)
	end
end

function installPackage(dir)
	errorUtils.assert(kernel.isSU(), permDenied, 2)
	errorUtils.assert(fs.exists(dir), "Package does not exist", 2)
	
	local packageName = fs.getName(dir)
	
	if isPackage(packageName) then
		error("Package already exists", 2)
	end
	
	fs.copy(dir, fs.combine(programPath, packageName))
end

function uninstallPackage(packageName)
	errorUtils.assert(kernel.isSU(), permDenied, 2)
	
	if tableUtils.indexOf(fs.listDirs(systemProgramPath), packageName) then
		error("Can't uninstall system package", 2)
	end
	
	if not tableUtils.indexOf(fs.listDirs(programPath), packageName) then
		error("Package does not exits", 2)
	end
	
	fs.delete(fs.combine(programPath, packageName))
end

function isPackage(packageName)
	if tableUtils.indexOf(fs.listDirs(programPath), packageName) or tableUtils.indexOf(fs.listDirs(systemProgramPath), packageName) then
		return true
	end
	
	return false
end

--server stuff

function getAllPackages()
	local request, err = http.timedRequest(url .. "/repo", 2)
	
	if not request then
		return nil, err
	end
	
	return jsonUtils.decode(request.readAll())
end

function getPackageByName(name)
	local packages = getAllPackages()
	
	for _, package in pairs(packages) do
		if package.PackageName == name then
			return package
		end
	end
end


function getPackageByID(ID)
	local packages = getAllPackages()
	ID = tostring(ID)
	
	for _, package in pairs(packages) do
		if package.PackageID == ID then
			return package
		end
	end
end

function getVersionsByName(name)
	package = getPackageByName(name)
	
	if package then
		local request, err = http.timedRequest(url .. "/repo/" .. package.PackageID, 2)
		
		if not request then
			return nil, err
		end
		
		return jsonUtils.decode(request.readAll())
	end
end


function getVersionsByID(ID)
	local package = getPackageByID(ID)
	ID = tostring(ID)
	
	if package then
		local request, err = http.timedRequest(url .. "/repo/" .. package.PackageID, 2)
		
		if not request then
			return nil, err
		end
		
		return jsonUtils.decode(request.readAll())
	end
end

function getFilesList(packageID, versionID)
	local request, err = http.timedRequest(url .. "/repo/" .. packageID .. "/" ..versionID .. "/files", 2)
		
	if not request then
		return nil, err
	end

	return jsonUtils.decode(request.readAll())
end

function getFile(packageID, versionID, fileName)
	local request, err = http.timedRequest(url .. "/repo/" .. packageID .. "/" .. versionID .. "/files/" .. fileName, 2)
		
	if not request then
		return nil, err
	end

	return jsonUtils.decode(request.readAll())
end

function getDependencies(packageID, versionID)
	local request, err = http.timedRequest(url .. "/repo/" .. packageID .. "/" .. versionID .. "/dependencies", 2)
		
	if not request then
		return nil, err
	end

	return jsonUtils.decode(request.readAll())
end

function downloadPackage(name)
	errorUtils.assert(kernel.isSU(), "Super User is required to install packages", 1)
	errorUtils.assert(not isPackage(name), "Package is already insatlled", 1)
	
	local versions = getVersionsByName(name)
	local highestVersion = -1
	local files
	local path
	
	if not versions then
		return false, "Package does not exist"
	end
	
	for _, version in pairs(versions) do
		if tonumber(version.VersionID) > highestVersion then
			highestVersion = tonumber(version.VersionID)
		end
	end

	if highestVersion == -1 then
		return false, "No avalible versions"
	end

	files = getFilesList(package.PackageID, highestVersion)
	path = fs.combine("/LunaOS/data/tmp/package" .. name)
	
	fs.makeDir(path)

	for _, file in pairs(files) do
		local data = getFile(package.PackageID, highestVersion, file)
		local file = fs.open(fs.combine(path, data.FileName), "w")
		file.write(data.Data)
		file.close()
	end

	fs.move(path, fs.combine(getProgramPath(), name))
	
	return true
end
