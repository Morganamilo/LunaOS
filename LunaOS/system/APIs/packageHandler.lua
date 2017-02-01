local url = lunaOS.getProp("serverURL")
local tmp = lunaOS.getProp("tmpDir")
local permDenied = errorUtils.strings.permDenied

function installPackage(package)
	if not kernel.isSU() then
		error("SuperUser is needed to install packages")
	end
	
	local packageName = fs.getName(package)
	local packagePath = fs.combine(tmp, package)
	local installer = fs.combine(tmp, "install.lua")
	
	fs.delete(packagePath)
	lzip.unZipToDir(package, packagePath)
	
	if not fs.isFile(installer) then
		error("Missing insall.lua")
	end
	
	dofile(installer)
end
