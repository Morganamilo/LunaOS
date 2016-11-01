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
	if var == nil and not required then return end
	
	if not (type(typ) == "string") then error("idk",2) end
	
	local errorMsg = "Error: " .. typ
	if not required then errorMsg = errorMsg .. " or nil" end
	errorMsg = errorMsg .. " expected, got " .. type(var)
	
	assert(type(var) == typ, errorMsg, getCode(code or 2))
end

function expectNamed(name, var, typ, required, code)
	if var == nil and not required then return end
	
	local errorMsg = "Error: " .. typ
	if not required then errorMsg = errorMsg .. " or nil" end
	errorMsg = errorMsg .. " expected for " .. name .. ", got " .. type(var)
	
	assert(type(var) == typ, errorMsg, getCode(code or 2))
end
