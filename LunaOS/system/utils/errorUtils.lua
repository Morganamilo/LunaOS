strings = {
    permDenied = "Permission Denied",
    permDeniedFor = "Permission Denied for %s",
    fileError = "Error opening %s",
    noExist = "%s does not exist",
    fileNoExist = "%s does not exist",
    dirNoExist = "Directory %s does not exist",
    exists = "%s already exists",
    fileExists = "File %s already exists",
    dirExists = "Directory %s already exists",
    notFile = "Not a file %s",
    notDir = "Not a directory %s",
    PIDError = "PID %s is invalid or does not exist",
    expected = "%s expexted, got %s",
    expectedOrNil = "%s or nill expected, got %s",
    mustImplement = "Component must implement %s"
}

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
	
    local errorMsg

    if required then
        errorMsg = string.format(strings.expected, typ, type(var))
    else
        errorMsg = string.format(strings.expectedOrNil, typ, type(var))
    end

	assert(type(var) == typ, errorMsg, getCode(code or 2))
end

local function handler(errorText, errors)
    local _, err
    local level = 4

    errors[1] = errorText
    while true do
        _, err = pcall(error, "", level)

        if err == "stack trace:1: " then
           break
        end

        errors[#errors + 1] = err
        level = level + 1
    end

    errors[#errors] = nil
    errors[#errors] = nil
    errors[#errors] = nil
end

local function _stackCall(func, errors, res, args)
    local r =  {xpcall(function() return func(unpack(args)) end, function(errorText) return handler(errorText, errors) end, 0)}

    for k,v in pairs(r) do
        res[k] = v --stupid pass by value cause returning from load doesnt work
    end
end

function stackCall(func, ...)
    expect(func, "function", true, 2)

    local errors = {}
    local res = {}
    load("_stackCall(func, errors, res, arg)", "stack trace", "t", {_stackCall = _stackCall, func = func, arg = arg, errors = errors, res = res})()

    if not res[1] then
        return res[1], errors
    else
        return unpack(res)
    end
end
