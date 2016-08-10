
----------------------------------------------------------------------------------------------------------------
--Window Handler
----------------------------------------------------------------------------------------------------------------

--all the functions that the kernel calls are subject to change
--this is just thrown together as a proof of concept and is very badly written

local xSize, ySize = term.getSize()
local native = term.native()
local windowOrder = {}
local extended = false
local kernel

local banner = window.create(native, 1, 1, xSize, 1, false)
local workingArea = window.create(native, 1,2, xSize, ySize - 1, false)

function setPrivate(p)
	kernel = setmetatable({}, {__index = function(t, k)
		if p[k] ~= nil then return p[k]
		else return _G.kernel[k] end
	end
	})
end

local function reposAll(newH)
	banner.reposition(1, 1, xSize, newH)
	
	for k, v in pairs(kernel._processes) do
		v.window.reposition(1, newH)
	end
end

local function getLabelAt(Xpos, Ypos)
	local length = 0
	
	for k,v in ipairs(windowOrder) do
		local parent = kernel._processes[v].parent
	
		
		if (not parent and Ypos == 1) or ((parent == kernel._runningPID or parent == kernel._processes[kernel._runningPID].parent and parent) and Ypos == 2)  then
		local start = length
		length = length + #kernel._processes[v].name + 2
		if kernel._runningPID == v then length = length + 2 end
		if Xpos > start and Xpos <= length  then return v, Xpos - start - 1 end
		end
	end
end

local function writeProcess(PID)
	if PID == kernel._runningPID then
		banner.setBackgroundColor(colors.gray)
		banner.setTextColor(colors. red)
		banner.write(' ' .. string.char(215)) --X
		
		if table.getn(kernel._processes[PID].children) > 0 then
			banner.write(string.char(extended and 30 or 31)) --down arrow
		else
			banner.write(' ')
		end
		
		banner.setTextColor(colors. blue)
	else
		banner.setBackgroundColor(colors.cyan)
		banner.write(' ')
		banner.setTextColor(colors. yellow)
	end

	banner.write( kernel._processes[PID].name .. ' ' )
	banner.setBackgroundColor(colors.cyan)
end

local function writeProcesses()
	banner.setCursorPos(1,1)
	banner.setBackgroundColor(colors.cyan)
	banner.clear()
	
	for k,v in ipairs(windowOrder) do
		if kernel._processes[v] and not kernel._processes[v].parent then
			-- banner.setTextColor(colors. white)
			-- banner.write(string.char(215) .. " ")
			-- banner.write(kernel._processes[v].name) --32 215
			-- banner.setTextColor(colors. red)
			-- if table.getn(kernel._processes[v].children)  > 0 then banner.write(string.char(31)) end
			writeProcess(v)
			
		end
	end
end

local function updateBanner()
	writeProcesses()
	
	if extended then
		banner.setCursorPos(1, 2)
		
		for k,v in pairs(windowOrder) do	
				if kernel._processes[v].parent == kernel._runningPID or (kernel._processes[kernel._runningPID].parent and kernel._processes[v].parent == kernel._processes[kernel._runningPID].parent) then
					writeProcess(k)
				end
		end
	end
	
	term.current().restoreCursor()
end

local function handleBannerEvent(event)
	local proc, pos = getLabelAt(event[3], event[4])
	if proc and event[1] == 'mouse_click' then
		if proc == kernel._runningPID then
			if pos == 1 then
				kernel.killProcessInternal(kernel._runningPID)
			elseif pos == 2 and table.getn(kernel._processes[kernel._runningPID].children) > 0 then
				extended = not extended
				reposAll(extended and 2 or 1)
			end
		else
				if event[2] == 1 then
					if (not kernel._processes[kernel._runningPID].parent and not kernel._processes[proc].parent) or ( kernel._processes[proc].parent ~= kernel._runningPID and kernel._processes[kernel._runningPID].parent ~= proc and kernel._processes[proc].parent ~= kernel._processes[kernel._runningPID].parent) then
						extended = false
						reposAll(1)
					end
					
					kernel.gotoPID(proc)
					
				else
					kernel.killProcessInternal(proc)
				end
		end
	end
	
	
	updateBanner()
end

function init()
	banner.setVisible(true)
	workingArea.setVisible(true)
	updateBanner()
end

--init()

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
	bannerX, bannerY = banner.getSize()
	
	
	if event[1] == "mouse_click" or
	   event[1] == "mouse_up" or
	   event[1] == "mouse_scroll" or
	   event[1] == "mouse_drag" then
		if event[4] > bannerY then
			
			event[4] = event[4] - bannerY 
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
	--log.e("Process " .. proc.name .. " (" ..  proc.PID .. ") has crashed: " .. data)
	
	if data == 'Terminated' then return end
	
	term.redirect(proc.window)
	term.setTextColor(colors.red)
	term.setBackgroundColor(4)
	term.clear()
	term.setCursorPos(1,1)

	print("Error: process Has crashed")
	print("\tPID: ".. proc.PID)
	print("\tName: ".. proc.name)
	print("\tReason: ".. (data or ''))
	print("Returning to processes\n") --coroutine.yield("terminate")
	print("Press any key to continue") --kernel.runProgram("lunashell")
	print(math.random(1000))
	
	coroutine.yield("key")--]] --kernel.gotoPID(kernel.newProcess(function() f() end))
end

function handleDeath(PID)
	tableUtils.removeValue(windowOrder, PID)
	updateBanner()
end

function handleFinish()
	local x, y = term.getSize()
	local currentX, currentY = term.getCursorPos()
	
	if currentY == y then term.scroll(1) end
	term.setCursorPos(1, y)
	term.write("This process has finished. Press any key to Close")
	coroutine.yield("key")
end

