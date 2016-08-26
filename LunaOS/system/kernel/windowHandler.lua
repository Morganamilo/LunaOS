
----------------------------------------------------------------------------------------------------------------
--Window Handler
----------------------------------------------------------------------------------------------------------------

--all the functions that the kernel calls are subject to change
--this is just thrown together as a proof of concept and is very badly written

local xSize, ySize = term.getSize()
local native = term.native()
local windowOrder = {}
local kernel
local hidden = false

local downArrow = string.char(31)
local upArrow = string.char(30)
local x = string.char(215) .. ' '

local banner = window.create(native, 1, 1, xSize, 1, false)
local workingArea = window.create(native, 1,2, xSize, ySize - 1, false)

local buffer = GUI.Buffer(banner, 1, 1, xSize, 1)

local backgroundColour = colourUtils.blits.grey
local textColour = colourUtils.blits.cyan
local xColour = colourUtils.blits.grey
local selectedColour = colourUtils.blits.blue

local errorBackgroundColour = colours.grey
local errorTextColour = colours.lightGrey
local errorValuesColour = colours.cyan

function setPrivate(p)
	local metaFunction =  function(t, k) if p[k] ~= nil then return p[k] else return _G.kernel[k] end end
	
	kernel = setmetatable({}, {__index = metaFunction})
end

local function getLabelAt(xPos, yPos)
	local pos = 0
	
	for _, PID in ipairs(windowOrder) do
		local proc = kernel._processes[PID]
		
		pos = pos + #proc.name + 2
		
		if kernel._runningPID == PID then
			pos = pos + 2
		end
		
		if xPos == pos - 1 and kernel._runningPID == PID then
			return -1
		end
		
		if xPos <= pos then
			return PID
		end
	end
end

local function updateBanner()
		local pos = 1
		buffer:clear(backgroundColour)
		
		for _, PID in ipairs(windowOrder) do
				local proc = kernel._processes[PID]
				local padding = 2
				local colour
				
				if kernel._runningPID == PID then
					padding = padding + 1
					colour = selectedColour
				end
			
				buffer:writeStr(pos, 1, ' ' .. proc.name .. ' ', textColour, colour)
				
				pos = pos + #proc.name + 2
				
				if kernel._runningPID == PID then
					buffer:writeStr(pos, 1, x, xColour, colour)
					pos = pos + 2
				end
			end
	
	buffer:writeStr(buffer.xSize, 1, upArrow, textColour, backgroundColour)
	
	if not hidden then
		buffer:draw()
	end
	
	term.current().restoreCursor()
end

local function setHidden(state)
	local newPos = 2
	local newSize = ySize - 1
	
	if state then
		newPos = 1
		newSize = ySize
	end
	
	workingArea.reposition(1, newPos, xSize, newSize)
	
	for k, v in pairs(kernel._processes) do
		local x, y = v.window.getCursorPos()
		
		if y > newSize then
			v.window.scroll(1)
			v.window.setCursorPos(x, newSize)
		end
		
		v.window.reposition(1, 1, xSize, newSize)
	end
	
	banner.setVisible(not state)
	
	hidden = state
end

local function handleBannerEvent(event)
	if event[3] == buffer.xSize and event[1] == "mouse_click" then
		setHidden(not hidden)
		return
	end

	local proc = getLabelAt(event[3], event[4])
	
		if proc == -1 and event[1] == 'mouse_click' then
			kernel.killProcessInternal(kernel._runningPID)
		elseif proc and event[1] == 'mouse_click' and event[2] == 1 then
			kernel.gotoPID(proc)
		elseif proc and event[1] == 'mouse_click' and event[2] == 2 then
			kernel.killProcessInternal(proc)
		end
	
	updateBanner()
end

function init()
	banner.setVisible(true)
	workingArea.setVisible(true)
	updateBanner()
	setHidden(true)
end

function newWindow(PID)
	updateBanner()
	windowOrder[#windowOrder + 1] = PID
	
	return window.create(workingArea, 1, 1, xSize, ySize - 1, false)
end

function gotoWindow(oldWin, newWin)
	if oldWin then oldWin.setVisible(false) end
		newWin.setVisible(true)
		term.redirect(newWin)
		if kernel._processes[kernel._runningPID].parent then
			extended = true
			reposAll(2)
		end
		
		updateBanner()
		newWin.redraw()
end

function handleEvent(event)	
	if event[1] == "mouse_click" or
	   event[1] == "mouse_up" or
	   event[1] == "mouse_scroll" or
	   event[1] == "mouse_drag" then
		
		if event[4] > 1 and not hidden then	
			event[4] = event[4] - 1
			return event
		elseif hidden and event[3] ~= buffer.xSize then
			return event
		else
			handleBannerEvent(event)
			updateBanner()
			return {}
		end
	end
	
	return event
end

function handleError(proc, data)
	data = data or ""
	
	log.e("Process " .. proc.name .. " (" ..  proc.PID .. ") has crashed: " .. data)
	
	if data == 'Terminated' then return end
	
	local x, y = term.getSize()
	local lines = {}
	local errorLines = textUtils.wrap(data, 40,5)
	
	 lines[#lines + 1] = "This process Has crashed"
	 lines[#lines + 1] = "The process " .. proc.name .. " with PID: " .. proc.PID
	 lines[#lines + 1] = "has encountered an error and needs to close"
	 lines[#lines + 1] = ""
	 
	 lines = tableUtils.combine(lines, errorLines)
	 
	 lines[#lines + 1] = ""
	 lines[#lines + 1] = "Press any key to continue"
	
	term.redirect(proc.window)
	term.setBackgroundColor(errorBackgroundColour)
	term.clear()
	
	for n, line in pairs(lines) do
		local lineLength = #line --+ #values[n]
		local cursorXPos = math.floor(x/2) - math.floor((lineLength)/2)
		local cursorYPos = math.floor(y/2) - math.floor(#lines/2) + n - 1
		term.setCursorPos(cursorXPos, cursorYPos)
		
		if n >= 5 and lines[n + 2]  then
			term.setTextColor(errorValuesColour)
		else
			term.setTextColor(errorTextColour)
		end
		
		term.write(lines[n])
	end
	
	coroutine.yield("key")
end

function handleDeath(PID)
	tableUtils.removeValue(windowOrder, PID)
	updateBanner()
end

function handleFinish()
	local x, y = term.getSize()
	local currentX, currentY = term.getCursorPos()
	
	term.setBackgroundColor(errorBackgroundColour)
	term.setTextColor(errorValuesColour)
	
	if currentY == y then term.scroll(1) end
	term.setCursorPos(1, y)
	term.write("This process has finished, press any key to close.")
	coroutine.yield("key")
end

