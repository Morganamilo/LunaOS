--the kernel allows multiple processes to be created
--only one process can run at a time
--process can pause to let another process run then continue
--when a process errors the process is killed and a report is sent back

local fs = fs

local loadfile = function( _sFile )
    local file = fs.open( _sFile, "r" )
    if file then
        local func, err = loadstring( file.readAll(), fs.getName( _sFile ) )
        file.close()
        return func, err
    end
    return nil, "File not found"
end

local _private = {}
local windowHandler = {}

_private._processes = {}
_private._runningPID = nil --pid of the currently running process 
_private._runningHistory = {}
_private._waitingFor = {}
--local keyHandlerPath = "/LunaOS/system/kernel/keyHandler.lua"
windowHandler = {} --os.loadAPILocal(keyHandlerPath)

_private.programDataPath = lunaOS.getProp("dataPath")
_private.programPath = lunaOS.getProp("programPath")

function _private.cirticalError(msg)
	term.redirect(term.native())
	term.clear()
	term.setCursorPos(1,1)
	term.write("Critical Error")
	term.setCursorPos(1,2)
	print(msg)
	term.write("Press any key to shutdown")
	coroutine.yield("key")
	os.shutdown()
end

function _private.getEnv(SU)
	local env = tableUtils.deepCopy(_ENV)
	
	env._G = env
	env._ENV = env
	
	return env
end

function _private.newProcessInternal(func, parent, name, desc, SU, dir)
	errorUtils.expect(func, 'function', true, 3)
	errorUtils.expect(parent, 'number', false, 3)
	errorUtils.expect(name, 'string', false, 3)
	errorUtils.expect(desc, 'string', false, 3)
	
	local PID = tableUtils.getEmptyIndex(_private._processes)
	local name = name or 'Unnamed'
	local desc = desc or ''
	
	if parent then
		--tells the parent it has children
		errorUtils.assert(_private._processes[parent], "Error: PID " .. parent .. " is invalid or does not exist", 3)
		_private._processes[parent].children[tableUtils.getEmptyIndex(_private._processes[parent].children)] = PID
	end
		
	local wrappedFunc = function()
		func() 
		local success, res = pcall(windowHandler.handleFinish, PID) 
		if not success then
			_private.cirticalError(res)
		end 
	end
	
	local co = coroutine.create(wrappedFunc)
	local window = windowHandler.newWindow(PID)
	
	_private._processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU, dir = dir, window = window}
	log.i("Created new " .. (SU and "Root" or "User") .. " process with PID " .. PID)
	return PID
end

function _private.runProgramInternal(program, parent, su, args)
	errorUtils.expect(program, 'string', true, 3)
	
	local root = fs.combine(_private.programPath, program)
	local name
	
	errorUtils.assert(fs.isDir(root), "Error: Program does not exist", 2)
	
	fs.isFile = fs.exists
	
	if fs.isFile(fs.combine(root, program .. '.lua')) then
		name = program .. '.lua'
	elseif fs.isFile(fs.combine(root, program)) then
		name = program
	elseif fs.isFile(fs.combine(root, 'main.lua')) then
		name = 'main.lua'
	elseif fs.isFile(fs.combine(root, 'main')) then
		name = 'main'
	elseif fs.isFile(fs.combine(root, 'startup.lua')) then
		name = 'startup.lua'
	elseif fs.isFile(fs.combine(root, 'startup')) then
		name = 'startup'
	else
		error("Error: Missing startup file", 2)
	end
	
	local file, err = loadfile(fs.combine(root, name))
	errorUtils.assert(file, err, 3)
	setfenv(file, getfenv(1)) 
	
	local PID = _private.newProcessInternal(
		function() file(unpack(args)) end,
		parent,
		program,
		desc,
		su,
		root
	)
end

function _private.killProcessInternal(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	local thisPoc = _private._processes[PID]
	local children = getAllChildren(PID)
	local parent = _private._processes[thisPoc.parent ]
	
	if parent then
		--iterate over our parent's children until we find ourself
		for child = 1, #parent.children do
			if parent.children[child] == PID then
				log.i("Telling " .. parent.PID .. " it no longer has child " .. PID)
				table.remove(parent.children, child)
			end
		end
	end
	
	for _, v in pairs(getAllChildren(PID)) do
		log.i("killing " .. v)
		_private._processes[v] = nil
		_private._waitingFor[v] = nil
		--_env[v] = nil 
		windowHandler.handleDeath(v)
		
		--removes the process from the _runningHistory
		local index = tableUtils.indexOf(_private._runningHistory, v)
		if index then
			table.remove(_private._runningHistory, index)
		end
	end
	
	_private._runningPID = nil
	
	log.i("Finished killing: " .. PID)
	
	--decide the process that takes over
	local newRunning = thisPoc.parent or _private._runningHistory[#_private._runningHistory] or tableUtils.lowestIndex(_private._processes)
	if newRunning then
		gotoPID(newRunning) 
	else
		_private._runningPID = nil
		--os.queueEvent("stop")
		--coroutine.yield("stop")
	end
end


function _private.resume(co, data)	
	data = { coroutine.resume(co, unpack(data)) }
	local success = table.remove(data, 1)
	return success, data
end

function _private.next(data)
	if  _private._waitingFor[_private._runningPID] then return _private._waitingFor[_private._runningPID]  end
	
	local currentProc = _private._processes[_private._runningPID]
	local success
	local event
	
	success, data = _private.resume(currentProc.co, data)
	
	if not success then --handle error
		local success, res = pcall(windowHandler.handleError, currentProc, data[1])
		if not success then _private.cirticalError(res) end
		
		data = {}
	end
	
	
	if coroutine.status(currentProc.co) == 'dead' then --handle death
		_private.killProcessInternal(currentProc.PID)
		data = {}
	end
	
	return data
end

function _private.getYield(data)
	local proc = _private._runningPID
	local event
	
	repeat
		local success
		
		if proc ~= _private._runningPID then --if the process has changed since we starded the loop
			if _private._processes[proc] then _private._waitingFor[proc] = data end
			return data
		elseif _private._runningPID then
			_private._waitingFor[proc] = nil
		end
		
		event = {coroutine.yield()} --the event we get + extra data
		
		success, e = pcall(keyHandler.handleKeyEvent, event)
		
		if not success then _private.cirticalError(e) end
		
		success, event = pcall(windowHandler.handleEvent, event)
		if not success then _private.cirticalError(event) end
		
	until tableUtils.indexOf(data, event[1]) or #data == 0 and #event ~= 0 or event[1] == 'terminate'
	
	return event
end

----------------------------------------------------------------------------------------------------------------
--Public
----------------------------------------------------------------------------------------------------------------

--pauses the current process and starts/resumes the specifid process
function gotoPID(PID, ...)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	log.i("Going to PID " .. PID)
	
	--if the PID is already in the history move it to the top
	local index = tableUtils.indexOf(_private._runningHistory, PID)
	if index then
		table.remove(_private._runningHistory, index)
	end
	
	_private._runningHistory[#_private._runningHistory + 1] = PID
	
	local old = _private._runningPID and _private._processes[_private._runningPID].window or nil
	_private._runningPID = PID
	
	windowHandler.gotoWindow(old, _private._processes[PID].window)
	
	os.queueEvent('goto', unpack(arg))
	return coroutine.yield("goto")
end

function getProgramDataPath()
	return _private.programDataPath
end

function newProcess(func, parent, name, desc)
	func = load(string.dump(func))
	
	local env = _private.getEnv(SU)
	--_env[PID] = env -- sandboxes each process
	setfenv(func, env)
	
	return _private.newProcessInternal(func, parent, name, desc, false)
end

function newRootProcess(func, parent, name, desc)
	func = load(string.dump(func))
	
	func = load(string.dump(func))
	local env = _private.getEnv(SU)
	--_env[PID] = env -- sandboxes each process
	setfenv(func, env)
	
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_private._runningPID or "") .. " tried to start a new process as root: Access denied", 2, nil, "Warning")
	return _private.newProcessInternal(func, parent, name, desc, true)
end

function runFile(path, parent, name, desc, ...)
	local file, err = loadfile(path)
	errorUtils.assert(file, err, 2)
	setfenv(file, _private.getEnv()) --sandBox
	
	return _private.newProcessInternal(function() file(unpack(arg)) end, parent, name or fs.getName(path), desc, false)
end

function runRootFile(path, parent, name, desc, ...)
	local file, err = loadfile(path)
	errorUtils.assert(file, err, 2)
	setfenv(file, _private.getEnv()) --sandBox
	
	return _private.newProcessInternal(function() file(unpack(arg)) end, parent, fs.getName(path), desc, true)
end

function runProgram(program, parent, ...)
	return _private.runProgramInternal(program, parent, false, arg)
end

function runRootProgram(program, parent, ...)
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_private._runningPID or "") .. " tried to start a new program as root: Access denied", 2, nil, "Warning")
	_private.runProgramInternal(program, parent, true, arg)
end

--ruturns a copy of all processes excluding the thread
function getProcessCount()
	return #_private._processes
end

function getProcesses()
	local procs = {}
	
	for k, v in pairs(_private._processes) do
		procs[k] = tableUtils.copy(v)
		procs[k].co = nil
		procs[k].window = nil
	end
	
	return procs
end

function getProcess(n)
	errorUtils.expect(n, 'number', true, 2)
	if not _private._processes[n] then return end

	local proc = tableUtils.copy(_private._processes[n])
	proc.co = nil
	proc.window = nil
	return proc
	
end

function getRunning()
	return _private._runningPID
end

function getRunningProgramPath()
	if _private._runningPID then
		return _private._processes[_private._runningPID].dir
	end
end

function getRunningProgram()
	local path = getRunningProgramPath()
	
	if path then
		return fs.getName(path)
	end
end

function isSU()
	if not _private._runningPID then return true end --if the kernel is not in use give root
	return _private._processes[_private._runningPID].SU
end

--pauses the current process and starts/_private.resumes the specifid process
function gotoPID(PID, ...)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	log.i("Going to PID " .. PID)
	
	--if the PID is already in the history move it to the top
	local index = tableUtils.indexOf(_private._runningHistory, PID)
	
	if index then
		table.remove(_private._runningHistory, index)
	end
	
	_private._runningHistory[#_private._runningHistory + 1] = PID
	
	local old = _private._runningPID and _private._processes[_private._runningPID].window or nil
	_private._runningPID = PID
	
	windowHandler.gotoWindow(old, _private._processes[PID].window)
	
	os.queueEvent('goto', unpack(arg))
	return coroutine.yield("goto")
end

function getAllChildren(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	local allChildren = {PID}
	local parentPID = _private._processes[PID].parent
	local i = 1
			
	while allChildren[i] do
		for _, v in pairs(_private._processes[allChildren[i]].children) do
			allChildren[#allChildren + 1] = v
		end
		
		i = i + 1
	end
	
	return allChildren
end

function killProcess(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assertLog(isSU() or not _private._processes[PID].SU, "Error: process with PID " .. (_private._runningPID or "") .. " tried to kill root proccess", 2, nil, "Warning")
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	_private.killProcessInternal(PID)
end

function startProcessess(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	errorUtils.assert(not _private._runningPID, "Error: kernel already running", 2)
	
	local current = term.current()
	
	gotoPID(PID)
	
	local success, res = pcall(windowHandler.init)
	if not success then _private.cirticalError(res) end
	
	local data = {} --the events we are listening for
	
	term.native = term.current
	
	
	while _private._runningPID do
		data = _private.next(data)
		data = _private.getYield(data)
	end
	
	term.redirect(current)
	term.setBackgroundColor(colors.black)
	term.setTextColor(1)
	term.clear()
	term.setCursorPos(1,1)
	
	print("Craft OS")
	--os.shutdown()
end

 function startProcesses(PID)
	a,b = pcall(startProcessess, PID)
	print(b)
	sleep(10)
end
----------------------------------------------------------------------------------------------------------------
--Window Handler
----------------------------------------------------------------------------------------------------------------

--all the functions that the kernel calls are subject to change
--this is just thrown together as a proof of concept and is very badly written

local xSize, ySize = term.getSize()
local native = term.native()
local windowOrder = {}
local extended = false

local banner = window.create(native, 1, 1, xSize, 1, false)
local workingArea = window.create(native, 1,2, xSize, ySize - 1, false)

local function reposAll(newH)
	banner.reposition(1, 1, xSize, newH)
	
	for k, v in pairs(_private._processes) do
		v.window.reposition(1, newH)
	end
end

local function getLabelAt(Xpos, Ypos)
	local length = 0
	
	for k,v in ipairs(windowOrder) do
		local parent = _private._processes[v].parent
	
		
		if (not parent and Ypos == 1) or ((parent == _private._runningPID or parent == _private._processes[_private._runningPID].parent and parent) and Ypos == 2)  then
		local start = length
		length = length + #_private._processes[v].name + 2
		if _private._runningPID == v then length = length + 2 end
		if Xpos > start and Xpos <= length  then return v, Xpos - start - 1 end
		end
	end
end

local function writeProcess(PID)
	if PID == _private._runningPID then
		banner.setBackgroundColor(colors.gray)
		banner.setTextColor(colors. red)
		banner.write(' ' .. string.char(215)) --X
		
		if table.getn(_private._processes[PID].children) > 0 then
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

	banner.write( _private._processes[PID].name .. ' ' )
	banner.setBackgroundColor(colors.cyan)
end

local function writeProcesses()
	banner.setCursorPos(1,1)
	banner.setBackgroundColor(colors.cyan)
	banner.clear()
	
	for k,v in ipairs(windowOrder) do
		if _private._processes[v] and not _private._processes[v].parent then
			-- banner.setTextColor(colors. white)
			-- banner.write(string.char(215) .. " ")
			-- banner.write(_private._processes[v].name) --32 215
			-- banner.setTextColor(colors. red)
			-- if table.getn(_private._processes[v].children)  > 0 then banner.write(string.char(31)) end
			writeProcess(v)
			
		end
	end
end

local function updateBanner()
	writeProcesses()
	
	if extended then
		banner.setCursorPos(1, 2)
		
		for k,v in pairs(windowOrder) do	
				if _private._processes[v].parent == _private._runningPID or (_private._processes[_private._runningPID].parent and _private._processes[v].parent == _private._processes[_private._runningPID].parent) then
					writeProcess(k)
				end
		end
	end
	
	term.current().restoreCursor()
end

local function handleBannerEvent(event)
	local proc, pos = getLabelAt(event[3], event[4])
	if proc and event[1] == 'mouse_click' then
		if proc == _private._runningPID then
			if pos == 1 then
				_private.killProcessInternal(_private._runningPID)
			elseif pos == 2 and table.getn(_private._processes[_private._runningPID].children) > 0 then
				extended = not extended
				reposAll(extended and 2 or 1)
			end
		else
				if event[2] == 1 then
					if (not _private._processes[_private._runningPID].parent and not _private._processes[proc].parent) or ( _private._processes[proc].parent ~= _private._runningPID and _private._processes[_private._runningPID].parent ~= proc and _private._processes[proc].parent ~= _private._processes[_private._runningPID].parent) then
						extended = false
						reposAll(1)
					end
					
					kernel.gotoPID(proc)
					
				else
					_private.killProcessInternal(proc)
				end
		end
	end
	
	
	updateBanner()
end

function windowHandler.init()
	banner.setVisible(true)
	workingArea.setVisible(true)
	updateBanner()
end

--windowHandler.init()

function windowHandler.newWindow(PID)
	updateBanner()
	windowOrder[#windowOrder + 1] = PID
	
	return window.create(workingArea, 1, 1, xSize, ySize - 1, false)
end

function windowHandler.gotoWindow(oldWin, newWin)
	if oldWin then oldWin.setVisible(false) end
		newWin.setVisible(true)
		term.redirect(newWin)
		if _private._processes[_private._runningPID].parent then
			extended = true
			reposAll(2)
		end
		
		updateBanner()
		newWin.redraw()
end

function windowHandler.handleEvent(event)
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

function windowHandler.handleError(proc, data)
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

function windowHandler.handleDeath(PID)
	tableUtils.removeValue(windowOrder, PID)
	updateBanner()
end

function windowHandler.handleFinish()
	local x, y = term.getSize()
	local currentX, currentY = term.getCursorPos()
	
	if currentY == y then term.scroll(1) end
	term.setCursorPos(1, y)
	term.write("This process has finished. Press any key to Close")
	coroutine.yield("key")
end

