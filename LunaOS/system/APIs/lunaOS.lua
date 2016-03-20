local properties = jsonUtils.decodeFile("/LunaOS/system/properties.json")

function getProp(prop)
	return properties[prop]
end
