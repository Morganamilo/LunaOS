---JSON API for encoding and decoding json files.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module jsonUtils

---White space values.
--@table whitespace
local whitespace = {" ", "\t", "\n", "\r"}

---Escape values.
--contains values and their escaped counterpart.
local escapes = {["\\\""] = "\"", ["\\\\"] = "\\", ["\\b"] = "\b", ["\\f"] = "\f", ["\\n"] = "\n", ["\\r"] = "\r", ["\\t"] = "\t", ["\\/"] = "/"}

---Control characters
local control = {"\:","\,","\{", "\}", "\[", "\]"}

--define functions before hand as they are used out of order
local escape
local unescape
local isArray
local valueToJson
local keyToJson
local encodeInternal
local nextValue
local parseArray
local parseObject
local parseValue
local parsePair
local parseString
local parseNonString


---Escapes values in a string by replaceing all escape values with their escaped counterparts.
--@lfunction escape
--@param str A string to escape.
--@return An escaped version of the string.
--@usage escapedString = escape(string)
function escape(str)
	for k, v in pairs(escapes) do
		str = str:gsub(v, k)
	end
	
	return str
end

---Unscapes values in a string by replaceing all escaped values with their unescaped counterparts.
--@lfunction unescape
--@param str A string to unescape.
--@return An unescaped version of the string.
--@usage unescapedString = unescape(string)
function unescape(str)
	for k, v in pairs(escapes) do
		str = str:gsub(k, v)
	end
	
	return str
end

---Decides whether or not a lua table is equivlent to a json array or object.
--@lfunction isArray
--@param tbl A lua table.
--@return true if the tabe contains only number indexes, false otherwise.
--@usage local _isArray = isArray(tbl)
function isArray(tbl)
	local size = 0
	
	for k in pairs(tbl) do
		if type(k) ~= "number" then return false end
		size = math.max(k, size)
	end
	
	return size
end

---Converts a value to its json equivelent.
--String are escaped and surrounded by quotes,
--Numbers are un changed,
--Boleans are converted to a string,
--Tables are enoded recursivley,
--nill values are changed to null,
--Other values raise an error.
--@lfunction valueToJson
--@param value the value to encode.
--@param indentLevel the amount of Spaces currently indented to.
--@return the json counterpart of the given value.
--@raise Unserializable type error - if the valuse can not be serialized.
--@usage json = valueToJsonl("value", 2)
function valueToJson(value, indentLevel)
	local t = type(value)
			
	if t == "string" then
		return '"' .. escape(value) .. '"'
	elseif t == "number" then
		return value
	elseif t == "boolean" then
		return tostring(value)
	elseif t == 'table' then
		if indentLevel  then indentLevel = indentLevel + 2 end
		return encodeInternal(value, indentLevel)
	elseif t == "nil" then
		return "null"
	else
		error("Error: Unserializable type: " .. t, 0)
	end
end

---Converts a ket to its json counterpart.
--Strings are surrounded by quotes,
--Other values raise an error.
--@lfunction keyToJson
--@param key the key to encode.
--@return the json counterpart of the key.
--@raise invalid type error - if the key is not a string
--@usage json = keyToJson("key")
function keyToJson(key)
	if type(key) == "string" then
		return '"' .. escape(key) .. '"'
	else
		error("Error: Key must be string, got " .. type(key), 0)
	end
end

---Encodes a table into json format.
--Can be encoded in both a compact and human readable format.
--@lfunction encodeInternal
--@param tbl The table to encode.
--@param indentLevel the indentLevel, should be nil to diable indentation or 0 to enable it.
--@return the json encoded table.
--@raise type error - if tbl is not a table
--@usage local json = encodeInternal(tbl)
function encodeInternal(tbl, indentLevel)
	errorUtils.assert(type(tbl) == "table", "Error: Table expected got " .. type(tbl), 2)
	local isA = isArray(tbl)
	local jsonStr = (isA and "[" or "{")
	local indent
	
	if indentLevel then 
		indent = string.rep("\t", indentLevel + 1)
	end
	
	if isA then
		for i = 1, isA do
			if indentLevel then jsonStr = jsonStr.. "\n ".. indent end
			jsonStr = jsonStr .. valueToJson(tbl[i], indentLevel) .. ","
		end
	else
		for k,v in pairs(tbl) do
			if indentLevel then jsonStr =  jsonStr .. "\n ".. indent end
			jsonStr =  jsonStr .. keyToJson(k) .. ":" .. valueToJson(v, indentLevel) .. ","
		end
	end
		
	if isA ~= 0 then jsonStr = jsonStr:sub(1,#jsonStr - 1) end --remove last comma
	
	if indentLevel then jsonStr = jsonStr .. "\n" .. string.rep("\t", indentLevel) end
	return jsonStr ..(isA and "]" or "}"), indentLevel 
end

---Encodes a table into json format.
--Can be encoded in both a compact and human readable format.
--@param tbl The table to encode.
--@param readable Whether or not th
--@return the json encoded table.
--@usage local str = jsonUtils.encode(tbl, true)
function encode(tbl, readable)
	local encoded = encodeInternal(tbl, readable and 0 or nil)
	return encoded
end

---Gets the next non whitespace value of a string starting from a given point.
--@lfunction nextValue
--@param str The string to Parse.
--@param start The point to start parsing from.
--@return The character found.
--@return The position of the character in the string.
--@raise end of input error - of not character is found.
--@usage local c, pos = nextValue("a        b     c       d", 6)
function nextValue(str, start)
	local isIn = tableUtils.indexOf
	
	for pos = start, #str do
		local c = str:sub(pos, pos)
		
		if not isIn(whitespace, c) then
			return c, pos
		end
	end
	
	error("Error: Unexpected end of input near" .. start, 0)
end

---Parse a json array and returns the array as a lua table.
--@lfunction parseArray
--@param str The string to parse.
--@param start the position in the string to start parsing.
--@return str A table equivelent of the json array.
--@return start The position after the end of the array.
--@raise unexpected character error - if array is missing a comma
--@usage local tbl, next = parseArray(str, start)
function parseArray(str, start)
	local array = {}
	local counter = 1
	
	local closeChar, closePos = nextValue(str, start + 1) 
	if closeChar == "]" then 
		closeChar, closePos = nextValue(str, closePos + 1)
		return array, closePos
	end
	
	while true do
		local c
		
		c, start = nextValue(str, start + 1)
		array[counter], start = parseValue(str, start)
		counter = counter + 1
		c, start = nextValue(str, start)
		
		if c == "]" then
			return array, start + 1
		elseif c ~= "," then
			error("Error: Expected ',' near" .. start, 0)
		end
	end
end

---Parse a json object and returns the object as a lua table.
--@lfunction parseObject
--@param str The string to parse.
--@param start the position in the string to start parsing.
--@return A table equivelent of the json object.
--@return The position after the end of the object.
--@raise unexpected character error - if object is missing a comma
--@usage local tbl, next = parseObject(str, start)
function parseObject(str, start)
	local c
	local object = {}
	
	if nextValue(str, start + 1) == "}" then return object, start + 2 end
	
	while true do
		local k, v
		
		c, start = nextValue(str, start + 1)
		
		k, v, start = parsePair(str, start)
		object[k] = v
		
		c, start = nextValue(str, start)
		
		if c == "}" then
			return object, start + 1
		elseif c ~= "," then
			error("Error: Expected ',' near " .. start, 0)
		end
	end
end

---Parses a key value pair in the format '"key":value'.
--@lfunction parsePair
--@param str The json string containing a key value pair.
--@param start The position of the pair in the string.
--@return The key used in the pair.
--@return The value of the pair
--@raise invalid key error - if key is not a string
	--<br>unexpected character error - if : is not between key and value
--@usage local key, value, next = parsePair(str, 45)
function parsePair(str, start)
	local key
	local val
	local c
	
	key, start = parseValue(str, start)
	c, start = nextValue(str, start)
	errorUtils.assert(type(key) == "string", "Error: key must be string near" .. start, 0)
	
	if c ~= ":" then
		error("Error: Expected ':' near " .. start, 0)
	else
		c, start = nextValue(str, start + 1) 
	end
	
	value, start = parseValue(str, start)
	
	return key, value, start
end

---Parse a value in a json array.
--@lfunction parseValue
--@param str The json string containing a json value.
--@param start The position of the value in the string.
--@return The value parsed.
--@return The position after the value
--@usage local value = parseValue(str, 43)
function parseValue(str, start)
	if str:sub(start, start) == "\"" then
		return parseString(str, start + 1)
	else
		return parseNonString(str, start)
	end
end

---Parse a string value in json
--@lfunction parseString
--@param str The json string.
--@param start the position of the string in the json string.
--@return The string.
--@return The position after the string.
--@usage local s = parseString(str, 43)
function parseString(str, start)
	for pos = start, #str do
		local c = str:sub(pos, pos)
		
		if c == "\"" then
			local isEscped = false
			
			for p = pos - 1, start +1, -1 do
				if str:sub(p,p) == "\\" then  isEscped = not isEscped
				else break end
			end
			
			if not isEscped then
				return unescape(str:sub(start, pos - 1)), pos + 1
			end
			
		end
	end
end

---Parse any value that is not a string.
--@lfunction parseNonString
--@param str the json string.
--@param start The position of the value in the string.
--@return the value.
--@return the position after the value.
--@raise invalid input error - if the json string ends or if the value is not serializable
--@usage local value = parseNonString(str, 45)
function parseNonString(str, start)
	local endPos
	local isIn = tableUtils.indexOf
	local prevC
	
	if str:sub(start, start) == "{" then
		return parseObject(str, start)
	elseif str:sub(start, start) == "[" then
		return parseArray(str, start)
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


---Decode a json string into a lua table.
--@param str The json string.
--@return a lua table equivelent to the json string.
--@raise no object error - if the first character of string is no { or [
--@usage tbl = jsonUtils.decode(str)
function decode(str)
	errorUtils.expect(str, "string", true)
	
	local result
	local c, start = nextValue(str, 1)
	
	if c == "{" then
		result = parseObject(str, start)
	elseif c == "[" then
		result = parseArray(str, start)
	else
		error("Error: No Object or Array", 2)
	end
	
	return result
end

---Decodes a json string directly from a file
--@param path Path to the file to decodr
--@return a lua table equivelent to the json string in the file.
--@raise no file error - if the path does not point to a file
--@usage tbl = jsonUtils.decodeFile("/config.json")
function decodeFile(path)
	errorUtils.expect(path, "string", true)
	errorUtils.assert(fs.exists(path) and not fs.isDir(path), "Error: not a flie", 2)
	
	local file = fs.open(path, 'r')
	local data = file.readAll()
	file.close()
	return decode(data)
end






