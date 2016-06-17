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

local function trim(str, len)
  local e 
  local trimed
  local next
  
  trimed = str:sub(1, len + 1) --trim to one more than the length
  e = trimed:find("[%w]+$") -- find the start of the last word
  
  if e == 1 or e == nil or #str <= len then -- if e is nill then is must end in a space   if e = 1 then there are no spaces
    trimed = trimed:sub(1, len)
    next = str:sub(len + 1):match("%w.+")
  else 
    trimed = trimed:sub(1, e - 1) -- return from the beggining upto but not including the start of the last word
    next = str:sub(e):match("%w.+")
  end
  
  return (trimed), next
  
end

local function wrapInternal(str, width, height, lines)
  
  if #str <= width then
    lines[#lines + 1] = str
    return lines
  end
  
	local next = str
  local trimed
  
  repeat
    trimed, next = trim(next, width)
    lines[#lines + 1] = trimed
  until not next or #next == 0 or #lines >= height
  
	return lines
end

function wrap(str, width, height)
  local lines = split(str, "\n")
  local wrapped = {}
  
  for _, line in pairs(lines) do
    wrapped = wrapInternal(line, width, height, wrapped)
  end
  
  return wrapped
end