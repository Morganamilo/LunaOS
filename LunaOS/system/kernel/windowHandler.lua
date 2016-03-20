--all the functions that the kernel calls are subject to change
--this is just thrown together as a proof of concept and is very badly written

local i = 0
local xSize, ySize = term.getSize()
local banner
local windows = setmetatable({}, {__mode = "v"})
local extended = false

local dead = coroutine.create(function() while true do print(3) end end)

function newWindow(PID) -- called when a new process is made
	windows[PID] = window.create(term.native(), 1, 4, xSize, ySize - 3, false)
	return windows[PID]
end

function init() --called when the main process loop starts
	banner = window.create(term.native(),1,1,xSize,3,true)
	updateBanner({})
end

function gotoWindow(oldWin, newWin)
		if oldWin then oldWin.setVisible(false) end
		newWin.setVisible(true)
		term.redirect(newWin)
		--newWin.restoreCursor()
end

function handleError(proc, data)
	--log.e("Process " .. proc.name .. " (" ..  proc.PID .. ") has crashed: " .. data)
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
	
	term.setTextColor(colors.white)
	--kernel.killProcess(proc.PID)
	--proc.co = cor
	coroutine.yield("key")--]] --kernel.gotoPID(kernel.newProcess(function() f() end))
end

function updateBanner(event)
	local restore = term.current().restoreCursor
	local term = banner
	local x, y = term.getCursorPos()
	
	term.setBackgroundColor(128)
	term.clear()
	term.setCursorPos(1,1)
	term.setTextColor(2048)
	term.write("lunaOS Version " .. lunaOS.getProp("version"))
	
	term.setCursorPos(xSize - #tostring(i) + 1,1)
	term.write(i)
	i = i + 1
	
	term.setCursorPos(1,2)
	
	for _, v in pairs(event) do
		term.write(v .. ' ')
	end
	
	term.setCursorPos(1, 3)
	
	for k,v in pairs(kernel.getProcesses()) do
		local colour = k == kernel.getRunning() and colors.green or 128
		term.setBackgroundColor(colour)
		term.write(k)
	end
	
	term.setBackgroundColor(128)
	
	term.setCursorPos(xSize - 1, 3)
	term.write(extended and "^" or "V")
	
	--term.setCursorPos(xSize, 3)
	term.write("X")
	
	
	
	restore()
end

function handleEvent(event) --called every time an event happens
	--event[1] i the event type, the rest of the table is extra data passed along
	if event[1] == "mouse_click" and event[2] == 1 and event[4] == 3 then
		if event[3] == xSize then
			--if we hit the X kill the program
			kernel.killProcess(kernel.getRunning())
		elseif event[3] == xSize - 1 then
			--extended
			extended = not extended
			if extended then banner.reposition(1,1,xSize,10) 
			else banner.reposition(1,1,xSize,3) end 
			
		elseif kernel.getProcess(event[3]) then
			--goto the prcess clicked
			kernel.gotoPID(event[3])
		end
	end
	
	updateBanner(event)
end