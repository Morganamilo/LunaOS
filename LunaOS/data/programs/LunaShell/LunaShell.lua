args = {...}

local promptColour = 512
local promptBackColour = 128
local textColour = 1
local textBackColour = 128

local label = os.getComputerLabel()
local user = "user"

local dir = '/'

local history = {}

if args[1] then 
	term.setBackgroundColour(textBackColour)
end

local function writeText(str)
	term.setTextColour(textColour)
	term.setBackgroundColour(textBackColour)
	write(' ')
end

local function writePrompt(str)
	term.setTextColour(promptColour)
	term.setBackgroundColour(promptBackColour)
	write(os.getComputerLabel()  .. ':' .. dir .. '$')
end

local function readAndListen(history, ...)
	term.setCursorBlink(true)
	history = history or {}
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	local pos = 1
	local hisNum = #history + 1
	history[hisNum] = ""
	
	local function redraw()
		local str = history[hisNum] .. ' '
		term.setCursorPos(x,y)
		
		if pos + x - 1 > w then
			term.write(str:sub(pos - w  + x,  pos) .. string.rep(" ", math.max(w-x, 0)))
			term.setCursorPos(w, y)
		else
			term.write(str:sub(1, w) .. string.rep(" ", w-pos-x + 1))
			term.setCursorPos(x + pos - 1, y)
		end
	end
	
	repeat
		redraw()
		local event, d1, d2, d3, d4, d5 = coroutine.yield(unpack(arg))
		
		if event == 'char' then 
			history[hisNum] = history[hisNum]:sub(1, pos - 1) .. d1 .. history[hisNum]:sub(pos)
			pos = pos + 1
			
		elseif event == 'key' then
			
			if d1 == 14 and pos > 1 then --backspace
				history[hisNum] = history[hisNum]:sub(1, pos - 2) .. history[hisNum]:sub(pos)
				pos = pos - 1
			elseif  d1 == 203 and pos > 1 then --left
				pos = pos - 1
			elseif  d1 == 205 and pos <= #history[hisNum] then --right
				pos = pos + 1
            elseif d1 == 200 and hisNum > 1 then --up
				hisNum = hisNum - 1
				term.setCursorPos(x, y)
				term.write(string.rep(" ", w - x))
				pos = #history[hisNum] + 1
			elseif d1 == 208 and hisNum < #history then --down
				hisNum = hisNum + 1
				term.setCursorPos(x, y)
				term.write(string.rep(" ", w - x))
				pos = #history[hisNum] + 1
			elseif  d1 == 199 then --home
				pos = 1
			elseif  d1 == 207 then --end
				pos = #history[hisNum] + 1
			elseif  d1 == 211 then --delete
				history[hisNum] = history[hisNum]:sub(1, pos - 2) .. history[hisNum]:sub(pos)
			end
		elseif event == "paste" then
            -- Pasted text
            history[hisNum] = history[hisNum]:sub(1, pos) .. d1 .. history[hisNum]:sub(pos)
            pos = pos + #d1
		else
			return event, d1, d2, d3, d4, d5 
		end
		
	until d1 == 28
	
	redraw()
	if history[#history] == '' then history[#history] = nil end
	return history[hisNum] 
end
	
while true do
	writePrompt()
	writeText()
	local line = readAndListen(history, "key", "char", "mouse_click", "paste")
	words = textUtils.toWords(line)
	
	print('')
	
	if words[1] == 'lua' then dofile("rom/programs/lua") end
	if words[1] == 'exit' then break end
end