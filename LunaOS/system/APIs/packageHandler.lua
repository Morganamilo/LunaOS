local programDataPath = lunaOS.getProp("dataPath")
local programPath = lunaOS.getProp("programPath")
local systemProgramPath = lunaOS.getProp("systemProgramPath")
local list = fs.list

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
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	errorUtils.assert(fs.exists(dir), "Error: Package does not exist", 2)
	
	local packageName = fs.getName(dir)
	
	if isPackage(packageName) then
		error("Error: Package already exists", 2)
	end
	
	fs.copy(dir, fs.combine(programPath, packageName))
end

function uninstallPackage(packageName)
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	
	if tableUtils.indexOf(fs.listDirs(systemProgramPath), packageName) then
		error("Error: Can't uninstall system package", 2)
	end
	
	if not tableUtils.indexOf(fs.listDirs(programPath), packageName) then
		error("Error: Package does not exits", 2)
	end
	
	fs.delete(fs.combine(programPath, packageName))
end

function isPackage(packageName)
	if tableUtils.indexOf(fs.listDirs(programPath), packageName) or tableUtils.indexOf(fs.listDirs(systemProgramPath), packageName) then
		return true
	end
	
	return false
end