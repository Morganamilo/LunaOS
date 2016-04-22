function init()
	for _, file in pairs(fs.listFiles('/LunaOS/system/GUI/objects')) do
		local key = textUtils.toKey(fs.getName(file))
		GUI[key] = os.loadAPI(fs.combine('/LunaOS/system/GUI/objects', file), true)[key]
	end
end