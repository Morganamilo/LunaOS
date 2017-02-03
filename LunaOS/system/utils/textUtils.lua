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
	local n = 1
	
	sep = "%" .. sep

	while true do
		local s, e = str:find(sep, n)

    if not s then
      matches[#matches + 1] = str:sub(n, #str)
      break
    end

		matches[#matches + 1] = str:sub(n, s - 1)

		n = e + 1
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
  for _, line in ipairs(lines) do
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

local function wrappedPrint(str, startYCursor)
    local xSize, ySize = term.getSize()
    local textPos = 1
    local x, y

    while textPos <= #str do
        x, y = term.getCursorPos()
        local gap = xSize - x

        term.write(str:sub(textPos, textPos + gap))
        textPos = textPos + gap + 1

        x, y = term.getCursorPos()

        if y >= ySize and x > xSize and startYCursor > 1 then
            term.scroll(1)
            startYCursor = startYCursor - 1
            term.setCursorPos(1, ySize)
        else
            term.setCursorPos(1, y + 1)
        end
    end

    if x then
        term.setCursorPos(x, y)
    end

    return startYCursor
end


function newRead(replace, history, autoComplete)
    local xSize, ySize = term.getSize()
    local startXCursor, startYCursor = term.getCursorPos()

    local text = ""
    local cursorPos = 0
    local longest = 0
    local historyIndex

    local completions
    local completionNumber

    history = history or {}
    history[#history + 1] = ""
    historyIndex = #history

    term.setCursorBlink(true)

    local function setCursor(pos)
        term.setCursorPos( ((startXCursor + pos - 1) % xSize) + 1, startYCursor + math.floor( (startXCursor + pos - 1) / xSize) )
    end

    local function addText(str)
        text = text:sub(1, cursorPos) .. str .. text:sub(cursorPos + 1)
        cursorPos = cursorPos + #str
    end

    local function redraw()
        local paddedText

        if type(replace) == "string" and #replace > 0 then
            paddedText = replace:rep(#text):sub(1, #text)
        else
            paddedText = text
        end

        term.setCursorPos(startXCursor, startYCursor)
        startYCursor = wrappedPrint(paddedText, startYCursor)

        local x, y = term.getCursorPos()

        if completions then
            local colour = term.getTextColour()

            term.setTextColour(colours.grey)
            startYCursor = wrappedPrint(completions[completionNumber], startYCursor)
            term.setTextColour(colour)

            paddedText = paddedText .. completions[completionNumber]
        end

         if #paddedText > longest then
            longest = #paddedText
        end

        startYCursor = wrappedPrint(string.rep(" ", longest - #paddedText), startYCursor)

        setCursor(cursorPos)
    end

    local function complete()
        if autoComplete then
            completions = autoComplete(text)

            if completions and #completions > 0 and #text > 0 and cursorPos == #text then
                completionNumber = 1
            else
                completions = nil
                completionNumber = nil
            end
        end
    end

    local function finishComplete()
        if completions then
            addText(completions[completionNumber])
        end
    end

    local function completeUp()
        if completions then
            completionNumber = (completionNumber % #completions) + 1
        end
    end

    local function compleDown()
        if completions then
            completionNumber = ((completionNumber - 2) % #completions) + 1
        end
    end

    local function historyUp()
        if historyIndex > 1 then
            history[historyIndex] = text
            historyIndex = historyIndex - 1
            text = history[historyIndex]
            cursorPos = #text
        end
    end

    local function historyDown()
        if historyIndex < #history then
            history[historyIndex] = text
            historyIndex = historyIndex + 1
            text = history[historyIndex]
        else
            text = ""
        end

        cursorPos = #text
    end


    while true do
        local event, a, b, c, d, e = os.pullEvent()

        if event == "term_resize" then
            xSize, ySize = term.getSize()
            redraw()
        end

        if event == "char" or event == "paste" then
            addText(a)
            complete()
            redraw()
        end

        if event == "mouse_click" or event == "mouse_drag" then
            startPoint = xSize * startYCursor + startXCursor
            newCursorPoint = xSize * c + b

            if newCursorPoint >= startPoint and newCursorPoint <= startPoint + #text then
                cursorPos = newCursorPoint - startPoint
            end

            complete()
            redraw()
        end

        if event == "key" then
            if a == keys.enter then
                cursorPos = #text
                term.setCursorPos(1, startYCursor + math.floor((cursorPos + startXCursor - 1) / xSize) + 1)

                local x, y = term.getCursorPos()
                if y > ySize then
                    term.scroll(y - ySize)
                    term.setCursorPos(1,ySize)
                end


                history[#history] = nil

                term.setCursorBlink(false)
                return text
            end

            if a == keys.left and cursorPos > 0 then
               cursorPos = cursorPos - 1
                complete()
                redraw()
            end

            if a == keys.right then
                if completions then
                    finishComplete()
                elseif cursorPos < #text then
                    cursorPos = cursorPos + 1
                end

                complete()
                redraw()
            end

            if a == keys.up then
                if completions then
                    completeUp()
                else
                    historyUp()
                end

                redraw()
            end

            if a == keys.down then
                if completions then
                    compleDown()
                else
                    historyDown()
                end

                redraw()
            end

            if a == keys.backspace and cursorPos >= 1 then
                text = text:sub(1, cursorPos - 1) .. text:sub(cursorPos + 1)
                cursorPos = cursorPos - 1
                complete()
                redraw()
            end

            if a == keys.delete and cursorPos <= #text then
                text = text:sub(1, cursorPos) .. text:sub(cursorPos + 2)
                complete()
                redraw()
            end

            if a == keys.home then
                cursorPos = 0
                complete()
                redraw()
            end

            if a == keys["end"] then --end is a key word :/
                cursorPos = #text
                complete()
                redraw()
            end

            if a == keys.tab and completions then
                local fullCompletions = {}

                for k, v in ipairs(completions) do
                    fullCompletions[k] = text .. v
                end

                completions = nil
                completionNumber = nil

                redraw()

                term.setCursorPos(1, startYCursor + math.floor((cursorPos + startXCursor - 1) / xSize) + 1)
                textutils.pagedTabulate(fullCompletions)

                 history[#history] = nil

                return ""
            end

            if a == keys.a and keyHandler.isKeyDown(29) then
                cursorPos = 0
                complete()
                redraw()
            end

            if a == keys.e and keyHandler.isKeyDown(29) then
                cursorPos = #text
                complete()
                redraw()
            end

            if a == keys.right and keyHandler.isKeyDown(29) then
                local nextWord = text:find("[^%s][%s]", cursorPos + 1)

                if nextWord then
                    cursorPos = nextWord
                else
                    cursorPos = #text
                end

                complete()
                redraw()
            end

            if a == keys.left and keyHandler.isKeyDown(29) then
                local nextWord = text:reverse():find("[%s][^%s]", #text - cursorPos )

                if nextWord then
                    cursorPos = #text - nextWord
                else
                    cursorPos = 0
                end

                complete()
                redraw()
            end

            if a == 1 and completions then
                completions = nil
                completionNumber = nil

                redraw()
            end
        end
    end
end
