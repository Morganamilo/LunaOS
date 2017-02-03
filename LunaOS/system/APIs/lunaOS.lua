local properties = jsonUtils.decodeFile("/LunaOS/system/properties.json")

function getProp(prop)
	return properties[prop]
end

function isDebug()
	return properties["debug"]
end

function lock()
	if not password.hasPassword() then return end

	local PID = kernel.newProcess("/LunaOS/system/packages/keygaurd.lua")
	kernel.gotoPID(PID)
end
