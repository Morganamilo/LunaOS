--the kernel allows multiple processes to be created
--only one process can run at a time
--process can pause to let another process run then continue
--when a process errors the process is killed and a report is sent back

local _processes = {} --table of all processes
local _runningHistory = {} --keeps the order of which process was open last and was open before that etcetera
--local _env = {} --contains the enviroment of each process
local _runningPID = nil --pid of the currently running process 
local _waitingFor = {}

local programDataPath = lunaOS.getProp("dataPath")
local fs = fs
local windowHandler = {}
local programPath = lunaOS.getProp("programPath")
local keyHandlerPath = "/LunaOS/system/kernel/keyHandler.lua"
keyHandler = os.loadAPILocal(keyHandlerPath)

--overide the default loadfile so we can give it acess to the default file system
local loadfile = function( _sFile )
    local file = fs.open( _sFile, "r" )
    if file then
        local func, err = loadstring( file.readAll(), fs.getName( _sFile ) )
        file.close()
        return func, err
    end
    return nil, "File not found"
end

function cirticalError(msg)
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

function getProgramDataPath()
	return programDataPath
end

function setWindowHandler(tbl)
	--windowHandler = tbl
end

--returns the stock enviroment for each process 
 local function getEnv(SU)
	local env = tableUtils.deepCopy(_ENV)
	
	env._G = env
	env._ENV = env
	
	--setfenv(1, env)
	--dofile("/LunaOS/system/apis/override.lua")
	
	if not SU then
		--dofile("/LunaOS/system/apis/userOverride.lua")
	end
	
	return env
end

function a(b) return _G[b] end
--func		is the fuction that becomes the processes thread
--name 	is the processes name for the user
--desc		is a description of the processes for the user
local function newProcessInternal(func, parent, name, desc, SU, dir)
	errorUtils.expect(func, 'function', true, 3)
	errorUtils.expect(parent, 'number', false, 3)
	errorUtils.expect(name, 'string', false, 3)
	errorUtils.expect(desc, 'string', false, 3)
	
	local PID = tableUtils.getEmptyIndex(_processes)
	local name = name or 'Un named'
	local desc = desc or ''
	
	if parent then
		--tells the parent it has children
		errorUtils.assert(_processes[parent], "Error: PID " .. parent .. " is invalid or does not exist", 3)
		_processes[parent].children[tableUtils.getEmptyIndex(_processes[parent].children)] = PID
	end
	
	--c = string.dump(func)
	--func = load(c)
	
	--local env = getEnv(SU)
	--_env[PID] = env -- sandboxes each process
	--setfenv(func, env)
	
	local wrappedFunc = function() func() local success, res = pcall(windowHandler.handleFinish, PID) if not success then cirticalError(res) end end
	--setfenv(function() 
		--dofile("/LunaOS/system/apis/override.lua")
		--if not SU then dofile("/LunaOS/system/apis/userOverride.lua") end
	--end, env)()
	
	local co = coroutine.create(wrappedFunc)
	local window = windowHandler.newWindow(PID)
	
	
	_processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU, dir = dir, window = window}
	log.i("Created new " .. (SU and "Root" or "User") .. " process with PID " .. PID)
	return PID
end

function newProcess(func, parent, name, desc)
	func = load(string.dump(func))
	
	local env = getEnv(SU)
	--_env[PID] = env -- sandboxes each process
	setfenv(func, env)
	
	return newProcessInternal(func, parent, name, desc, false)
end

function newRootProcess(func, parent, name, desc)
	func = load(string.dump(func))
	
	func = load(string.dump(func))
	local env = getEnv(SU)
	--_env[PID] = env -- sandboxes each process
	setfenv(func, env)
	
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to start a new process as root: Access denied", 2, nil, "Warning")
	return newProcessInternal(func, parent, name, desc, true)
end

function runFile(path, parent, name, desc, ...)
	local file, err = loadfile(path)
	errorUtils.assert(file, err, 2)
	setfenv(file, getEnv()) --sandBox
	
	return newProcessInternal(function() file(unpack(arg)) end, parent, name or fs.getName(path), desc, false)
end

function runRootFile(path, parent, name, desc, ...)
	local file, err = loadfile(path)
	errorUtils.assert(file, err, 2)
	setfenv(file, getEnv()) --sandBox
	
	return newProcessInternal(function() file(unpack(arg)) end, parent, fs.getName(path), desc, true)
end

local function runProgramInternal(program, parent, su, args)
	errorUtils.expect(program, 'string', true, 3)
	
	local root = fs.combine(programPath, program)
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
	
	local PID = newProcessInternal(
		function() file(unpack(args)) end,
		parent,
		program,
		desc,
		su,
		root
	)
end

function runProgram(program, parent, ...)
	return runProgramInternal(program, parent, false, arg)
end

function runRootProgram(program, parent, ...)
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to start a new program as root: Access denied", 2, nil, "Warning")
	runProgramInternal(program, parent, true, arg)
end

--ruturns a copy of all processes excluding the thread
function getProcessCount()
	return #_processes
end

function getProcesses()
	local procs = {}
	
	for k, v in pairs(_processes) do
		procs[k] = tableUtils.copy(v)
		procs[k].co = nil
		procs[k].window = nil
	end
	
	return procs
end

function getProcess(n)
	errorUtils.expect(n, 'number', true, 2)
	if not _processes[n] then return end

	local proc = tableUtils.copy(_processes[n])
	proc.co = nil
	proc.window = nil
	return proc
	
end

function getRunning()
	return _runningPID
end

function getRunningProgramPath()
	if _runningPID then
		return _processes[_runningPID].dir
	end
end

function getRunningProgram()
	local path = getRunningProgramPath()
	
	if path then
		return fs.getName(path)
	end
end

function isSU()
	if not _runningPID then return true end --if the kernel is not in use give root
	return _processes[_runningPID].SU
end


--pauses the current process and starts/resumes the specifid process
function gotoPID(PID, ...)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	log.i("Going to PID " .. PID)
	
	--if the PID is already in the history move it to the top
	local index = tableUtils.isIn(_runningHistory, PID)
	if index then
		table.remove(_runningHistory, index)
	end
	
	_runningHistory[#_runningHistory + 1] = PID
	
	local old = _runningPID and _processes[_runningPID].window or nil
	_runningPID = PID
	
	windowHandler.gotoWindow(old, _processes[PID].window)
	
	os.queueEvent('goto', unpack(arg))
	return coroutine.yield("goto")
end


function getAllChildren(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	local allChildren = {PID}
	local parentPID = _processes[PID].parent
	local i = 1
			
	while allChildren[i] do
		for _, v in pairs(_processes[allChildren[i]].children) do
			allChildren[#allChildren + 1] = v
		end
		
		i = i + 1
	end
	
	return allChildren
end

local function killProcessInternal(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	local thisPoc = _processes[PID]
	local children = getAllChildren(PID)
	local parent = _processes[thisPoc.parent ]
	
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
		_processes[v] = nil
		_waitingFor[v] = nil
		--_env[v] = nil 
		windowHandler.handleDeath(v)
		
		--removes the process from the _runningHistory
		local index = tableUtils.isIn(_runningHistory, v)
		if index then
			table.remove(_runningHistory, index)
		end
	end
	
	_runningPID = nil
	
	log.i("Finished killing: " .. PID)
	
	--decide the process that takes over
	local newRunning = thisPoc.parent or _runningHistory[#_runningHistory] or tableUtils.lowestIndex(_processes)
	if newRunning then
		gotoPID(newRunning) 
	else
		_runningPID = nil
		--os.queueEvent("stop")
		--coroutine.yield("stop")
	end
end

function killProcess(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assertLog(isSU() or not _processes[PID].SU, "Error: process with PID " .. (_runningPID or "") .. " tried to kill root proccess", 2, nil, "Warning")
	errorUtils.assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	killProcessInternal(PID)
end

local function resume(co, data)	
	data = { coroutine.resume(co, unpack(data)) }
	local success = table.remove(data, 1)
	return success, data
end

local function next(data)
	if  _waitingFor[_runningPID] then return _waitingFor[_runningPID]  end
	
	local currentProc = _processes[_runningPID]
	local success
	local event
	
	success, data = resume(currentProc.co, data)
	
	if not success then --handle error
		local success, res = pcall(windowHandler.handleError, currentProc, data[1])
		if not success then cirticalError(res) end
		
		data = {}
	end
	
	
	if coroutine.status(currentProc.co) == 'dead' then --handle death
		killProcessInternal(currentProc.PID)
		data = {}
	end
	
	return data
end

local function getYield(data)
	local proc = _runningPID
	local event
	
	repeat
		local success
		
		if proc ~= _runningPID then --if the process has changed since we starded the loop
			if _processes[proc] then _waitingFor[proc] = data end
			return data
		elseif _runningPID then
			_waitingFor[proc] = nil
		end
		
		event = {coroutine.yield()} --the event we get + extra data
		
		success = pcall(keyHandler.handleKeyEvent, event)
		if not success then cirticalError(event) end
		
		
		success, event = pcall(windowHandler.handleEvent, event)
		if not success then cirticalError(event) end
	until tableUtils.isIn(data, event[1]) or #data == 0 and #event ~= 0 or event[1] == 'terminate'
	
	return event
end

--starts the specified pocess
function startProcesses(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	errorUtils.assert(not _runningPID, "Error: kernel already running", 2)
	
	local current = term.current()
	
	gotoPID(PID)
	
	local success, res = pcall(windowHandler.init)
	if not success then cirticalError(res) end
	
	local data = {} --the events we are listening for
	
	term.native = term.current
	
	
	while _runningPID do
		data = next(data)
		data = getYield(data)
	end
	
	term.redirect(current)
	term.setBackgroundColor(colors.black)
	term.setTextColor(1)
	term.clear()
	term.setCursorPos(1,1)
	
	print("Craft OS")
	--os.shutdown()
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
	
	for k, v in pairs(_processes) do
		v.window.reposition(1, newH)
	end
end

local function getLabelAt(Xpos, Ypos)
	local length = 0
	
	for k,v in ipairs(windowOrder) do
		local parent = _processes[v].parent
	
		
		if (not parent and Ypos == 1) or ((parent == _runningPID or parent == _processes[_runningPID].parent and parent) and Ypos == 2)  then
		local start = length
		length = length + #_processes[v].name + 2
		if _runningPID == v then length = length + 2 end
		if Xpos > start and Xpos <= length  then return v, Xpos - start - 1 end
		end
	end
end

local function writeProcess(PID)
	if PID == _runningPID then
		banner.setBackgroundColor(colors.gray)
		banner.setTextColor(colors. red)
		banner.write(' ' .. string.char(215)) --X
		
		if table.getn(_processes[PID].children) > 0 then
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

	banner.write( _processes[PID].name .. ' ' )
	banner.setBackgroundColor(colors.cyan)
end

local function writeProcesses()
	banner.setCursorPos(1,1)
	banner.setBackgroundColor(colors.cyan)
	banner.clear()
	
	for k,v in ipairs(windowOrder) do
		if _processes[v] and not _processes[v].parent then
			-- banner.setTextColor(colors. white)
			-- banner.write(string.char(215) .. " ")
			-- banner.write(_processes[v].name) --32 215
			-- banner.setTextColor(colors. red)
			-- if table.getn(_processes[v].children)  > 0 then banner.write(string.char(31)) end
			writeProcess(v)
			
		end
	end
end

local function updateBanner()
	writeProcesses()
	
	if extended then
		banner.setCursorPos(1, 2)
		
		for k,v in pairs(windowOrder) do	
				if _processes[v].parent == _runningPID or (_processes[_runningPID].parent and _processes[v].parent == _processes[_runningPID].parent) then
					writeProcess(k)
				end
		end
	end
	
	term.current().restoreCursor()
end

local function handleBannerEvent(event)
	local proc, pos = getLabelAt(event[3], event[4])
	if proc and event[1] == 'mouse_click' then
		if proc == _runningPID then
			if pos == 1 then
				killProcessInternal(_runningPID)
			elseif pos == 2 and table.getn(_processes[_runningPID].children) > 0 then
				extended = not extended
				reposAll(extended and 2 or 1)
			end
		else
				if event[2] == 1 then
					if (not _processes[_runningPID].parent and not _processes[proc].parent) or ( _processes[proc].parent ~= _runningPID and _processes[_runningPID].parent ~= proc and _processes[proc].parent ~= _processes[_runningPID].parent) then
						extended = false
						reposAll(1)
					end
					
					kernel.gotoPID(proc)
					
				else
					killProcessInternal(proc)
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
		if _processes[_runningPID].parent then
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
