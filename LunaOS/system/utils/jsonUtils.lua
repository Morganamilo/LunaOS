local whitespace = {" ", "\t", "\n", "\r"}
local escapes = {["\\\""] = "\"", ["\\\\"] = "\\", ["\\/"] = "/", ["\\b"] = "\b", ["\\f"] = "\f", ["\\n"] = "\n", ["\\r"] = "\r", ["\\t"] = "\t"}
local control = {":",",","{", "}", "[", "]"}
local localFuncs = {}

function localFuncs.escape(str)
	for k, v in pairs(escapes) do
		str = str:gsub(v, k)
	end
	
	return str
end

function localFuncs.unescape(str)
	for k, v in pairs(escapes) do
		str = str:gsub(k, v)
	end
	
	return str
end

function localFuncs.isArray(tbl)
	local size = 0
	
	for k in pairs(tbl) do
		if type(k) ~= "number" then return false end
		size = math.max(k, size)
	end
	
	return size
end

function localFuncs.valueToJson(value, indentLevel)
	local t = type(value)
			
	if t == "string" then
		return '"' .. localFuncs.escape(value) .. '"'
	elseif t == "number" then
		return value
	elseif t == "boolean" then
		return tostring(value)
	elseif t == 'table' then
		if indentLevel  then indentLevel = indentLevel + 2 end
		return localFuncs.encodeInternl(value, indentLevel)
	elseif t == "nil" then
		return "null"
	else
		error("Error: Unserializable type: " .. t, 0)
	end
end

function localFuncs.keyToJson(key)
	if type(key) == "string" then
		return '"' .. localFuncs.escape(key) .. '"'
	else
		error("Error: Key must be string, got " .. type(key), 0)
	end
end

function localFuncs.encodeInternl(tbl, indentLevel)
	errorUtils.assert(type(tbl) == "table", "Error: Table expected got " .. type(tbl), 2)
	local isA = localFuncs.isArray(tbl)
	local jsonStr = (isA and "[" or "{")
	local indent
	
	if indentLevel then 
		indent = string.rep("\t", indentLevel + 1)
	end
	
	if isA then
		for i = 1, isA do
			if indentLevel then jsonStr = jsonStr.. "\n ".. indent end
			jsonStr = jsonStr .. localFuncs.valueToJson(tbl[i], indentLevel) .. ","
		end
	else
		for k,v in pairs(tbl) do
			if indentLevel then jsonStr =  jsonStr .. "\n ".. indent end
			jsonStr =  jsonStr .. localFuncs.keyToJson(k) .. ":" .. localFuncs.valueToJson(v, indentLevel) .. ","
		end
	end
		
	if isA ~= 0 then jsonStr = jsonStr:sub(1,#jsonStr - 1) end --remove last comma
	
	if indentLevel then jsonStr = jsonStr .. "\n" .. string.rep("\t", indentLevel) end
	return jsonStr ..(isA and "]" or "}"), indentLevel 
end

function encode(tbl, readable)
	local encoded = localFuncs.encodeInternl(tbl, readable and 0 or nil)
	return encoded
end

-------------------------------------------------------------

function localFuncs.nextValue(str, start)
	local isIn = tableUtils.isIn
	
	for pos = start, #str do
		local c = str:sub(pos, pos)
		
		if not isIn(whitespace, c) then
			return c, pos
		end
	end
	
	error("Error: Unexpected end of input near" .. start, 0)
end

function localFuncs.parseArray(str, start)
	local array = {}
	local counter = 1
	
	local closeChar, closePos = localFuncs.nextValue(str, start + 1) 
	if closeChar == "]" then 
		closeChar, closePos = localFuncs.nextValue(str, closePos + 1)
		return array, closePos
	end
	
	while true do
		local c
		
		c, start = localFuncs.nextValue(str, start + 1)
		array[counter], start = localFuncs.parseValue(str, start)
		counter = counter + 1
		c, start = localFuncs.nextValue(str, start)
		
		if c == "]" then
			return array, start + 1
		elseif c ~= "," then
			error("Error: Expected ',' near" .. start, 1)
		end
	end
end

function localFuncs.parseObject(str, start)
	local c
	local object = {}
	
	if localFuncs.nextValue(str, start + 1) == "}" then return object, start + 2 end
	
	while true do
		local k, v
		
		c, start = localFuncs.nextValue(str, start + 1)
		
		k, v, start = localFuncs.parsePair(str, start)
		object[k] = v
		
		c, start = localFuncs.nextValue(str, start)
		
		if c == "}" then
			return object, start + 1
		elseif c ~= "," then
			error("Error: Expected ',' near " .. start, 1)
		end
	end
end

function localFuncs.parsePair(str, start)
	local key
	local val
	local c
	
	key, start = localFuncs.parseValue(str, start)
	c, start = localFuncs.nextValue(str, start)
	errorUtils.assert(type(key) == "string", "Error: key must be string near" .. start, 0)
	
	if c ~= ":" then
		error("Error: Expected ':' near" .. start)
	else
		c, start = localFuncs.nextValue(str, start + 1) 
	end
	
	value, start = localFuncs.parseValue(str, start)
	
	return key, value, start
end

function localFuncs.parseValue(str, start)
	if str:sub(start, start) == "\"" then
		return localFuncs.parseString(str, start + 1)
	else
		return localFuncs.parseNonString(str, start)
	end
end

function localFuncs.parseString(str, start)
	for pos = start, #str do
		local c = str:sub(pos, pos)
		
		if c == "\"" then
			local isEscped = false
			
			for p = pos - 1, start +1, -1 do
				if str:sub(p,p) == "\\" then  isEscped = not isEscped
				else break end
			end
			
			if not isEscped then
				return localFuncs.unescape(str:sub(start, pos - 1)), pos + 1
			end
			
		end
	end
end

function localFuncs.parseNonString(str, start)
	local endPos
	local isIn = tableUtils.isIn
	local prevC
	
	if str:sub(start, start) == "{" then
		return localFuncs.parseObject(str, start)
	elseif str:sub(start, start) == "[" then
		return localFuncs.parseArray(str, start)
	end
	
	for pos = start, #str do
		local c = str:sub(pos, pos)
		
		if isIn(control, c) or isIn(whitespace, c) then
			endPos = pos
			break
		end
	end
	
	if not endPos then error("Error: Unexpected end of input near" .. start, 0) end
	prevC = str:sub(start, endPos - 1)
	
	if prevC == "null" then
		return nil, endPos
	elseif prevC == "true" then
		return true, endPos
	elseif prevC== "false" then
		return false, endPos
	elseif tonumber(prevC) then 
		return tonumber(prevC), endPos
	end
	
	error("Error: Invalid value near" .. start, 0)
end


function decode(str)
	errorUtils.assert(type(str) == "string", "Error: String expected got " .. type(str), 2)
	local result
	local c, start = localFuncs.nextValue(str, 1)
	
	if c == "{" then
		result = localFuncs.parseObject(str, start)
	elseif c == "[" then
		result = localFuncs.parseArray(str, start)
	else
		error("Error: No Object or Array", 2)
	end
	
	return result
end

function decodeFile(path)
	errorUtils.assert(fs.isFile(path), "Error: not a flie", 2)
	
	local file = fs.open(path, 'r')
	local data = file.readAll()
	file.close()
	return decode(data)
end






