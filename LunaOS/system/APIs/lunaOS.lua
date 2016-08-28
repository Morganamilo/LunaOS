local properties = jsonUtils.decodeFile("/LunaOS/system/properties.json")
local locked = false

function getProp(prop)
	return properties[prop]
end

function isLocked()
	return locked
end

function lock()
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	if locked then return end
	
	local PID = kernel.runRootProgram("keygaurd")
	kernel.setBarVisable(false)
	locked = true
	kernel.gotoPID(PID)
end

function unlock()
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	locked = false
end
