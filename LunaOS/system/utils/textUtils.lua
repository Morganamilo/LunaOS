---The textUtils API provides function to manipulate strings.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module textUtils

---Splits a string by a seperator.
--@param str The string to split.
--@param sep The seperator.
--@return A table of strings. Created from the largest substrings of str which do not contain sep.
function split(str, sep)
	errorUtils.expect(str, "string", true)
	errorUtils.expect(sep, "string", true)
	
	local matches = {}
	
	for match in str:gmatch("[^%" .. sep .. "]+") do
		matches[#matches + 1] = match
	end
	
	return matches
end

---Removes leading spaces from a string.
--@param str The string.
--@return A substring of str with any spaces before the first non space character removed.
--@usage local noSpaces = textUtils.trimLeadingSpaces(str)
function trimLeadingSpaces(str)
	local _, e = str:find("^%s+")
	
	if not e then return str end
	return str:sub(e + 1)
end

---Removes trialing spaces from a string.
--@param str The string.
--@return A substring of str with any spaces after the last non space character removed.
--@usage local noSpaces = textUtils.trimLeadingSpaces(str)
function trimTrailingSpaces(str)
	local e = str:find("%s+$")
	
	if not e then return str end
	return str:sub(1, e - 1)
end

---Converts a string to a value that could be used to index a table using dot notation.
--Spaces are replaced with underscores.
--the string is truncated after the first dot.
--For example "a b.c" could not be used as a key to index a table so the string is edited to "a_b".
--@param str A string.
--@return a string that can be used to index a table using dot notations following the rules stated above.
--@usage local key = textUtils.toKey(str)
function toKey(str)
	return str:gmatch("[^%.]*")():gsub(" ","_")
end

---Temp function
function toWords(str)
    str = str..'"'
    local words = {}
    local inQuote = false
    for word in str:gmatch('(.-)"') do
        if inQuote then
            words[#words + 1] = word
        else
            for w in word:gmatch("[^ \t]+" ) do
                words[#words + 1] = w
            end
        end
        
        inQuote = not inQuote
    end
    
    return words
end

---Takes a string and trims it down to to the as many whole words it can fit inside the specified length.
--Returns the trimmed string and the rest of the discarded string as seperate returns value.
--@param str A string.
--@param length The length to trim the string down to.
--@return The string truncated upto the length specified including only whole words.
--@return The part of the string truncated, without leading whitespace
--@usage local words = textUtils.trim(str, 10)
function trim(str, length)
    --create a substring from the start of the string to length + 1 characters long
    local trimed = str:sub(1, length + 1)
    -- find the start of the last word
    local lastWord = trimed:find("[%w%p]+$")
  
    local nextStr
    local nextWord
  
    --if lastWord is nill then trimed must end in a space. if lastWord is 1 then there are no spaces.
    --if it ends in a space, there is no space or the string is less than length then there is no need to trim it down further.
    if lastWord == 1 or lastWord == nil or #str <= length then
        trimed = trimed:sub(1, length)
        nextStr = str:sub(length + 1)
    else
        -- create a substring from the begining upto the length only including full words.
        --if the whole word will not fit then ignore it
        trimed = trimed:sub(1, lastWord - 1)
        nextStr = str:sub(lastWord)
    end
  
    --remove leading spaces so that the next line does not begin with a space
    nextWord = nextStr:find("[%w%p]")  or  1
    nextStr = nextStr:sub(nextWord)
  
    return (trimed), nextStr
end

---Text wraps a string into a given height and width.
--Wraps the string over multiple lines only spliting the line between words or during a word if it is larger than the line.
--@param str The string to wrap.
--@param width The width of the wrapped text.
--@param height the height of the wrapped text.
--@param lines A table of lines that is appened by this function.
--@return A text wrapped version of the input string, appened on to lines.
--@usage local wraped = wrapInternal(str, 20, 10, {})
local function wrapInternal(str, width, height, lines)
    local nextStr = str
    local trimed
  
    repeat
        trimed, nextStr = trim(nextStr, width)
        lines[#lines + 1] = trimed
    until #nextStr == 0 or #lines >= height
  
    return lines
end

---Text wraps a string into a given height and width and handles '\n'.
--Wraps the string over multiple lines only spliting the line between words or during a word if it is larger than the line.
--@param str The string to wrap.
--@param width The width of the wrapped text.
--@param height the height of the wrapped text.
--@return A text wrapped version of the input string.
--@usage local wraped = textUtils.wrap(str, 20, 10)
function wrap(str, width, height)
  local lines = split(str, "\n") -- split the string by \n to get each line of the string
  local wrapped = {}
  
  --wraps each line of text within the given size limit
  for _, line in pairs(lines) do
    wrapped = wrapInternal(line, width, height, wrapped)
  end
 
  return wrapped
end

---Pops n characters off the ends of a string and returns both parts.
--@param str The string.
--@param n How many characters to pop. Default is 1.
--@return The string truncated by n characters.
--@return The truncated characters.
--@usage local str, last = textUtils.pop(str)
function pop(str, n)
	return str:sub(1, #str - (n or 1)), str:sub(#str - (n or 1) + 1, #str)
end
