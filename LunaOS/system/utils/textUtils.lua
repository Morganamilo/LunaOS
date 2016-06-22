function split(str, sep)
	errorUtils.expect(str, "string", true)
	errorUtils.expect(sep, "string", true)
	
	local matches = {}
	
	for match in str:gmatch("[^%" .. sep .. "]+") do
		matches[#matches + 1] = match
	end
	
	return matches
end

function trimLeadingSpaces(str)
	local _, e = str:find("^%s+")
	
	if not e then return str end
	return str:sub(e + 1)
end

function trimTrailingSpaces(str)
	local e = str:find("%s+$")
	
	if not e then return str end
	return str:sub(1, e - 1)
end

function toKey(str)
	return str:gmatch("[^%.]*")():gsub(" ","_")
end

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

--takes a string, trims it down to to the as many whole words it can fit inside the length
--returns the trimmed string and the rest of the discarded string as seperate returns values
function trim(str, length)
  local trimed = str:sub(1, length + 1) --create a substring from the start of the string to length + q characters long
  local lastWord = trimed:find("[%w]+$") -- find the start of the last word
  
  local nextStr
  local nextWord
  
   -- if lastWord is nill then trimed must end in a space. if lastWord is 1 then there are no spaces.
  if lastWord == 1 or lastWord == nil or #str <= length then
    trimed = trimed:sub(1, length)
    nextStr = str:sub(length + 1)
  else 
  -- create a substring from the begining upto the length only including a word if the whole word will fit
    trimed = trimed:sub(1, lastWord - 1) 
    nextStr = str:sub(lastWord)
  end
  
  --remove leading spaces so that the next line does not begin with a space
  nextWord = nextStr:find("%w")  or  1
  nextStr = nextStr:sub(nextWord)
  
  return (trimed), nextStr
end

local function wrapInternal(str, width, height, lines)
  

  
	local next = str
  local trimed
  
  repeat
    trimed, next = trim(next, width)
    lines[#lines + 1] = trimed
  until not next or #next == 0 or #lines >= height
  
	return lines
end

function wrap(str, width, height)
  local lines = split(str, "\n") -- split the string by \n to get each line of the string
  local wrapped = {}
  
  --wrapes each line of text within the given size limit
  for _, line in pairs(lines) do
    wrapped = wrapInternal(line, width, height, wrapped)
  end
  
  return wrapped
end

function pop(str, n)
	return str:sub(1, #str - n or 1)
end