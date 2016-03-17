local properties = jsonUtils.decodeFile("/lunaos/system/properties.json")

function getProp(prop)
	return properties[prop]
end