---The windowHandler is responsable for managing the window each process draws to.
--It handles where each processe's window is and what its size is
--It handles when a process ends or errors.
--It also provides an banner that can be used be the user to change or kill processes.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module windowHandler


---Size of the terminal in characters.
--@field xSize width of the ternminal.
--@field ySize height of the terminal.
local xSize, ySize = term.getSize()

---The native terminal.
local native = term.native()

---Ordered list of open processes.
--The list is sorted by age in ascending order.
local windowOrder = {}

---The kernel API but with acess to its private table.
local kernel

---Whether or not the banner is hiden.
local hidden = true


---Down arrow character.
local downArrow = "v"

---UP arrow character.
local upArrow = "^"

---x character with a space.
local x = "x "

---The banner that is placed outside of the process windows.
--It allows switching and killing processes.
local banner = window.create(native, 1, 1, xSize, 1, false)

---The area in which the process windows are placed.
local workingArea = window.create(native, 1,1, xSize, ySize, false)

---Buffer which we draw the banner to before drawing it to the screen.
local buffer = GUI.Buffer(banner, 1, 1, xSize, 1)

---Background colour.
local backgroundColour = colourUtils.blits.grey

---Text colour.
local textColour = colourUtils.blits.cyan

---Colour of the x character used to close programs.
local xColour = colourUtils.blits.grey

---Background colour of the selected process.
local selectedColour = colourUtils.blits.blue

---Background colour of the error screen.
local errorBackgroundColour = colours.grey

--Text colour of the error screen.
local errorTextColour = colours.lightGrey

---Text colour of the line number and error text of the error screen
local errorValuesColour = colours.cyan

--If we have the full character range use more fany characters
if term.has8BitCharacters() then
	downArrow = string.char(31)
	upArrow = string.char(30)
	x= string.char(215) .. ' '
end

---Allows the kernel to its private table to the window handler to give
--the window handler direct access to the kernels functions.
--We then combine the global kernel and the private table in a metatable so
--that we can access both from one kernel varible.
--@param p the private table of the kernel.
--@usage windowHandler.setPrivate(_private)
function setPrivate(p)
	local metaFunction =  function(t, k) if p[k] ~= nil then return p[k] else return _G.kernel[k] end end
	
	kernel = setmetatable({}, {__index = metaFunction})
end

---Gets the banner label at a given point and return the PID
--of the label we hit.
--If we hit the x then return -1.
--@param xPos the x position we want to find a label at
--@param yPos the x position we want to find a label at
--@return The PID of the process belonging to the label at the given point.
--@return -1 if the point we where given is the x.
--@return nil if we did not hit a label.
local function getLabelAt(xPos, yPos)
	--position we are at
	local pos = 0
	
	--loop through all processes
	for _, PID in ipairs(windowOrder) do
		local proc = kernel._processes[PID]
		
		--look at the next label
		pos = pos + #proc.name + 2
		
		--if its the focused label account for the x symbol
		if kernel._focus == PID then
			pos = pos + 2
		end
		
		--we hit the x
		if xPos == pos - 1 and kernel._focus == PID then
			return -1
		end
		
		--we hit a label
		if xPos <= pos then
			return PID
		end
	end
end

---Redraws the banner and all the components in the banner.
--Start by clearing the banner then redraw each label in order.
--If the label we are drawing is the selected one use the appropriate colours.
--Wont draw if the banner is hidden.
--Endures the cursor is restored afterwards.
--@usage windowHandler.updateBanner()
function updateBanner()
		local pos = 1
		buffer:clear(backgroundColour)
		
		--draw all the labels
		for _, PID in ipairs(windowOrder) do
				local proc = kernel._processes[PID]
				local padding = 2
				local colour
				
				if kernel._focus == PID then
					padding = padding + 1
					colour = selectedColour
				end
			
				buffer:writeStr(pos, 1, ' ' .. proc.name .. ' ', textColour, colour)
				
				pos = pos + #proc.name + 2
				
				if kernel._focus == PID then
					buffer:writeStr(pos, 1, x, xColour, colour)
					pos = pos + 2
				end
			end
	
	--draw the up arrow
	buffer:writeStr(buffer.xSize, 1, upArrow, textColour, backgroundColour)
	
	--if the banner is not hidden draw it to the screen
	if not hidden then
		buffer:draw()
		banner.setVisible(true)
		banner.setVisible(false)
	end
	
	--restore the cursor
	if term.current().restoreCursor then
		 term.current().restoreCursor()
	end
end

---Makes the banner visable or invisable
--If invisable also moved the working area up and extends it to the full screen size.
--Banner can not be set to visable if the OS is locked.
--@param state true to hide the banner false to show it.
--@usage windowHandler.setHidden(true)
function setHidden(state)
	--if its locked and we're trying to show the banner just return
	if lunaOS.isLocked() or state == hidden then return end
	
	local newPos = 2
	local newSize = ySize - 1
	
	if state then
		newPos = 1
		newSize = ySize
	end
	
	workingArea.setBackgroundColor(8)

	--hide the working area while we do ajustments
	--workingArea.setVisible(false)
	workingArea.reposition(1, newPos, xSize, newSize)
	
	--scroll the window if the cursor is already at the bottom of the terminal
	for k, v in pairs(kernel._processes) do
		local x, y = v.window.getCursorPos()
		
		if y > newSize then
			v.window.scroll(1)
			v.window.setCursorPos(x, newSize)
		end
		
		v.window.reposition(1, 1, xSize, newSize)
		v.window.redraw()
	end
	
	--notify we are resizing the terminal
	os.queueEvent("term_resize")
	
	--now that we've done the ajustments make it visable againg
	workingArea.setVisible(true)
	workingArea.redraw()
	
	--set the hidden varible
	hidden = state
	
	--redraw the banner
	updateBanner()
end

function getHidden()
	return hidden
end

function init()
	--banner.setVisible(true)
	workingArea.setVisible(true)
	term.current().redraw()
	term.current().setVisible(false)
	--updateBanner()
	--setHidden(true)
end

---Creates a new window for a given process.
--the window is added to the workingArea and starts off invisable.
--@param PID The PID of the process the window is to belong to.
--@return The window that was creted.
--@usage local window = windowHandler.newWindow(3)
function newWindow(PID)
	local y = ySize
	
	if not hidden then
		y = y - 1
	end
	
	local win = window.create(workingArea, 1, 1, xSize, y, false)
	
	updateBanner()
	windowOrder[#windowOrder + 1] = PID
	
	return win
end

---Goes to a window by setting the new window visable and the old one invisable.
--@param old The PID of the process currently running or nil if there is none.
--@param new the PID of the new running process.
--@usage windowHandler.gotoWindow(3,4)
function gotoWindow(old, new)
	local newWin = kernel._processes[new].window

	if old then 
		kernel._processes[old].window.setVisible(false)
	end
	
	newWin.setVisible(true)
	newWin.redraw()

	updateBanner()
end

---Redirects to a window just like term.redirect except only the PID of the
--process is needed.
--@param PID The pid of the process to redirect to.
--@usage windowHandler.redirect(3)
function redirect(PID)
	term.redirect(kernel._processes[PID].window)
end

---Handles a mouse event when clicked on the banner
--Allows the banner to react to being clicked on.
--If we left click a process we go to it.
--If we right click a process we close it.
--If we hit the x on a process we close it.
--@param event The event we are handling.
--@usage  windowHandler.handleBannerEvent({"mouse_click", 1, 2, 4})
local function handleBannerEvent(event)
	--hide / unhide
	if event[3] == buffer.xSize and event[1] == "mouse_click" then
		setHidden(not hidden)
		return
	end

	--get the label we hit
	local proc = getLabelAt(event[3], event[4])
	
		--if we hit the x kill it
		if proc == -1 and event[1] == 'mouse_click' then
			kernel.killProcessInternal(kernel._focus)
		--if we left click go to it
		elseif proc and event[1] == 'mouse_click' and event[2] == 1 then
			kernel.gotoPID(proc)
		--if we right click kill it
		elseif proc and event[1] == 'mouse_click' and event[2] == 2 then
			kernel.killProcessInternal(proc)
		end
	
	updateBanner()
end

---Handles any incoming event.
--The kernel will pass all events to this function where it may be modified
--then passed to each process.
--If we hit the banner then send the event to the handleBannerEvent function and return an empty event.
--This function will ajust events to that mouse clicks so that they align with the working area.
--For example if the working area is at 5,5 and we get a mouse click at 2,2 the event will be ajusted to 2+5,2+5 = 7,7.
--@param event The event we are handling.
--@return The ajusted event.
--@return An empty event if we hit the banner.
--@usage windowHandler.handleEvent({"mouse_click", 1, 3, 4})
function handleEvent(event)	
	--if its a mouse related event ajust as necessary
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
	
	--if the term resized then draw, i dont know why but everything breaks otherwise.
	if event[1] == "term_resize" and kernel._processes[kernel._focus] then
		updateBanner()
		kernel._processes[kernel._focus].window.redraw()
	end
	
	return event
end

---Shows an error screen for when a process errors.
--Gives the user information about the crash including process
--name and PID, error reaso and error line.
--If it was a terminate error then dont show the error screen.
--@param proc The process that has errored.
--@param data the reason the procces errored, default is empty string.
--@usage windowHandler.handleError(proc, data)
function handleError(proc, data)
    local xSixe, ySize = term.getSize()
	data = data or {"Unkown Error"}
	
	--log the error
	log.e("Process " .. proc.name .. " (" ..  proc.PID .. ") has crashed: " .. data[1])

	--if it was a terminate event then skip the error handling
	if data == 'Terminated' then return end
	
	--redirect to the processes main window
	term.redirect(proc.window)
	local x, y = term.getSize()
	local lines = {}
	--local errorLines = textUtils.wrap(data, 40,5)
	local errorLines = textUtils.wrap(data[1], xSize - 4, ySize - 4)
	
	--generate the error message
	 lines[#lines + 1] = "This process Has crashed"
	 lines[#lines + 1] = "The process " .. proc.name .. " with PID: " .. proc.PID
	 lines[#lines + 1] = "has encountered an error and needs to close"
	 lines[#lines + 1] = ""
	 
	 lines = tableUtils.combine(lines, errorLines)
	 
	 lines[#lines + 1] = ""
	 lines[#lines + 1] = "Press Enter to continue"
	 lines[#lines + 1] = "Press Spacebar for stacktrace"
	
	term.setBackgroundColor(errorBackgroundColour)
	term.clear()
	
	--display the error message
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

	
	--wait for the user to press a key so they can read the error message before killing the process.
	--wait or let them view the stacktrace if they want to
	local event, key

    repeat
        event, key = coroutine.yield("key")
    until event == "key" and (key == keys.enter or key == keys.space)

    if key == keys.space then
        term.clear()
        term.setCursorPos(1, 2)
        term.setTextColor(colours.lightGrey)
        print("Stack Trace #" .. #data .. ":")

        term.setTextColor(colours.cyan)

        print("  " .. data[1])

        for n = 2, #data - ySize + 6 do
            local x, y = term.getCursorPos()

            for m = 4, ySize - 2 do
                term.setTextColor(colours.cyan)
                term.setCursorPos(1, m)
                term.clearLine()
                print("    @" .. n+m-4 .. data[n + m - 4])
            end

            term.setTextColor(colours.lightGrey)
            write("Press space to scroll")

            repeat
                event, key = coroutine.yield("key")
            until event == "key" and key == keys.space
        end

        if #data - ySize + 3 < 2 then
            for n = 2, #data do
                print("    @" .. data[n])
            end
        end

        term.setTextColor(colours.lightGrey)
        write("Press Enter to continue")

        repeat
            event, key = coroutine.yield("key")
        until event == "key" and key == keys.enter
    end
end

---Hanles the death of a process.
--@param PID The PID of the process that has died.
--@usage windowHandler.handleDeath(3)
function handleDeath(PID)
	tableUtils.removeValue(windowOrder, PID)
	updateBanner()
end

--Handles when a process ends naturaly with no errors.
--We keep the process open and allow the user to close it by pressing any key.
--This is so that the user has a chance to read the output if the processes is
--command driven an executes quickly.
--@param The PID of the process that has finished.
--@usage windowHandler.handleFinish()
function handleFinish(PID)
	term.redirect(kernel._processes[PID].window)
	
	local x, y = term.getSize()
	local currentX, currentY = term.getCursorPos()
	
	term.setBackgroundColor(errorBackgroundColour)
	term.setTextColor(errorValuesColour)
	
	if currentY == y then term.scroll(1) end
	term.setCursorPos(1, y)
	term.write("This process has finished, press any key to close.")
	coroutine.yield("key")
end

