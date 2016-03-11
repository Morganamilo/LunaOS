local function getCode(code)
	if code == 0 or not code then return 0
	else return code + 1 end
end

function assert(v, message, code)
	code = getCode(code)
	if not v then error(message, code) end
	return v
end

function assertLog(v, message, code, logMessage, flag)
	code = getCode(code)
	if not v then
		log(logMessage or message, flag or "e")
		error(message, code)
	end
	return v
end

function expect(var, typ, required, code)
	if not var and not required then return end
	assert(type(var) == typ, "Error: " .. typ .. " expected got " .. type(var), getCode(code))
end