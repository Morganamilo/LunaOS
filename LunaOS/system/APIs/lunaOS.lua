local properties = jsonUtils.decodeFile("/LunaOS/system/properties.json")
local locked = false

function getProp(prop)
	return properties[prop]
end

function isDebug()
	return properties["debug"]
end

function isLocked()
	return locked
end

function lock()
	if locked then return end
	if password.isPassword("") then return end
	
	kernel.setBarVisable(false)
	local PID = kernel.runProgram("keygaurd")
	
	locked = true
	kernel.gotoPID(PID)
end

function unlock()
	if not locked then return end
	
	errorUtils.assert(kernel.isSU(), errorUtils.strings.permDenied, 2)
	locked = false
	kernel.setBarVisable(true)
end
