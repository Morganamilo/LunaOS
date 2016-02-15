function assert(v, message, code)
	if code > 0 then code = code + 1 end
	if not v then error(message, code) end
	return v
end

function assertLog(v, message, code, logMessage, flag)
	if code > 0 then code = code + 1 end
	if not v then
		log(logMessage or message, flag or "Error")
		error(message, code)
	end
	return v
end