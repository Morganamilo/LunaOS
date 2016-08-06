local keys = {}

function handleKeyEvent(event)
	if event[1] == "key" then
		keys[event[2]] = true
	elseif event[1] == "key_up" then
		keys[event[2]] = nil
	end
end

function getKeysDown()
	return tableUtils.copy(keys)
end

function isKeyDown(key)
	return keys[key] == true
end