function nextChar(str, start, finish, c, back, no)
	local inc = back and -1 or 1
	
	for n = start, finish, inc do
		if (str:sub(n,n) == c) ~= (no) then return n end 
	end
end

function trimTrailingSpaces(str)
	for i = #str, 1, -1 do
		if str:sub(i,i) ~= ' ' then return str:sub(1,i) end
	end
	
	return ''
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

function toContainer(str, width, height)
	local lines = {}
	local start = 1
	
	str = str:gsub("\t", "  ")
	
	while true do
	    local lineBreak = str:sub(start, start + width):find("\n")
	    if lineBreak then
	        lines[#lines + 1] = trimTrailingSpaces(str:sub(start, lineBreak + start - 2))
	        start = lineBreak + start
	    else
			local nextLine = nextChar(str, start + width, start, " ", true, false) or start + width
			
			lines[#lines + 1] = trimTrailingSpaces(str:sub(start, nextLine - 1))
			start = (nextChar(str, nextLine, #str, " ", false, true) or #str)
			
			if start + width >= #str then lines[#lines + 1] = trimTrailingSpaces(str:sub(start, #str)) break end
		end
		
		if #lines >= height then break end
	end
	
	return lines
end