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
local windowHandler = os.loadAPILocal("/LunaOS/system/kernel/windowHandler.lua")
local focusEvents = {"mouse_click", "mouse_up", "mouse_drag", "mouse_scroll", "char", "key", "paste", "terminate"}

windowHandler.setPrivate(_private)

_private._processes = {}
_private._focus = nil
_private._runningPID = nil --pid of the currently running process 
_private._runningHistory = {}
_private._waitingFor = {}

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

function _private.newProcessInternal(func, parent, name, desc, SU, package)
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
		local success, res = pcall(func) 
		
		if not success then
			windowHandler.handleError(_private._processes[_private._runningPID], res)
		else
			windowHandler.handleFinish()
		end
	end
	
	local co = coroutine.create(wrappedFunc)
	local window = windowHandler.newWindow(PID)
	
	_private._processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU, package = package, window = window}
	log.i("Created new " .. (SU and "Root" or "User") .. " process with PID " .. PID)

	windowHandler.updateBanner()
	
	return PID
end

function _private.runProgramInternal(program, parent, su, args)
	errorUtils.expect(program, 'string', true, 3)
	
	local root = packageHandler.getPackagePath(program)
	local name
	
	errorUtils.assert(root, "Error: Program does not exist", 2)
	
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
		program
	)
	
	return PID
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
	
	_private._focus = nil
	
	log.i("Finished killing: " .. PID)
	
	--decide the process that takes over
	local newRunning = _private._runningHistory[#_private._runningHistory] or tableUtils.lowestIndex(_private._processes)
	
	if newRunning then
		gotoPID(newRunning) 
	else
		_private._focus = nil
	end
end

function _private.getEvent()
	event = {coroutine.yield()} --the event we get + extra data
		
	keyHandler.handleKeyEvent(event)
	event = windowHandler.handleEvent(event)
	
	return event
end

function _private.pushEvent(PID, event)
	local waiting  = _private._waitingFor[PID]
	local currentProc = _private._processes[PID]
	
	if not waiting or (#event > 0 and (tableUtils.indexOf(waiting, event[1]) or #waiting == 0 or event[1] == 'terminate')) then
		_private._runningPID = PID
		windowHandler.redirect(PID)
		
		local data = _private.resume(currentProc.co, event)

		windowHandler.setCurrentWindow(PID)
		
		if  _private._processes[PID] then
			_private._waitingFor[PID] = data 
		end
		
		if coroutine.status(currentProc.co) == 'dead'  and _private._processes[PID] then --handle death
			_private.killProcessInternal(PID)
		end
	end
end

function _private.tick(event)
	local processes = {}
	
	for k, v in pairs(_private._processes) do
		processes[#processes + 1] = k
	end
	
	local endLoop = false
	
	for k, v in pairs(processes) do
		if not  _private._waitingFor[v] then
			_private.pushEvent(v, {})
		end
	end
	
	for k, v in pairs(processes) do
		if tableUtils.indexOf(focusEvents, event[1]) and v == _private._focus then
			endLoop = true
		end
		
		if _private._processes[v] and (not tableUtils.indexOf(focusEvents, event[1]) or v == _private._focus)then
			_private.pushEvent(v, event)
		end
		
		if endLoop then
			break
		end
	end

	windowHandler.redirect(_private._focus)
	
	if term.current().restoreCursor then
		 term.current().restoreCursor()
	end
end

function _private.resume(co, data)	
	data = { coroutine.resume(co, unpack(data)) }
	local success = table.remove(data, 1)
	return data
end

function _private.next(data)
	if  _private._waitingFor[_private._focus] then return _private._waitingFor[_private._focus]  end
	
	local currentProc = _private._processes[_private._focus]
	local event
	
	data = _private.resume(currentProc.co, data)
	
	if coroutine.status(currentProc.co) == 'dead' then --handle death
		_private.killProcessInternal(currentProc.PID)
		data = {}
	end
	
	return data
end

function _private.getYield(data)
	local proc = _private._focus
	local event
	
	repeat
		local success
		
		if proc ~= _private._focus then --if the process has changed since we starded the loop
			if _private._processes[proc] then _private._waitingFor[proc] = data end
			return data
		elseif _private._focus then
			_private._waitingFor[proc] = nil
		end
		
		event = {coroutine.yield()} --the event we get + extra data
		
		keyHandler.handleKeyEvent(event)
		event = windowHandler.handleEvent(event)
		
	until tableUtils.indexOf(data, event[1]) or #data == 0 and #event ~= 0 or event[1] == 'terminate'
	
	return event
end

----------------------------------------------------------------------------------------------------------------
--Public
----------------------------------------------------------------------------------------------------------------

function setBarVisable(visable)
	windowHandler.setHidden(not visable)
end


function die()
	_private.killProcessInternal(_private._runningPID)
end

function getProgramDataPath()
	return _private.programDataPath
end

function newProcess(func, parent, name, desc)
	return _private.newProcessInternal(func, parent, name, desc, false)
end

function newRootProcess(func, parent, name, desc)
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_private._focus or "") .. " tried to start a new process as root: Access denied", 2, nil, "Warning")
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
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_private._focus or "") .. " tried to start a new program as root: Access denied", 2, nil, "Warning")
	return _private.runProgramInternal(program, parent, true, arg)
end

--ruturns a copy of all processes excluding the thread
function getProcessCount()
	return #_private._processes
end

function getProcesses()
	local procs = {}
	
	for k, v in pairs(_private._processes) do
		procs[#procs + 1] = getProcess(k)
	end
	
	return procs
end

function getProcess(n)
	errorUtils.expect(n, 'number', true, 2)
	
	local proc = _private._processes[n]
	local stripedProc = {}
	
	if not proc then return end
	
	stripedProc.PID = proc.PID
	stripedProc.name = proc.name
	stripedProc.SU = proc.SU
	stripedProc.desc = proc.desc
	stripedProc.package = proc.package
	stripedProc.parent = proc.parent
	stripedProc.children = tableUtils.deepCopy(proc.children)
	return stripedProc
end

function getRunning()
	return _private._runningPID
end

function getCurrentPackage()
	if _private._focus then
		return _private._processes[_private._runningPID].package
	end
end

function getCurrentPackagePath()
	if _private._focus then
		return packageHandler.getPackagePath(_private._processes[_private._runningPID].package)
	end
end

function getCurrentDataPath()
	if getCurrentPackage() then
		return fs.combine(packageHandler.getDataPath(), getCurrentPackage())
	end
end

function requestSU()
	if not kernel.getCurrentPackagePath() then return false end
	
	if fs.getDir(kernel.getCurrentPackagePath()) == packageHandler.getSystemProgramPath() then
		_private._processes[_private._runningPID].SU = true
		return true
	end
	
	return false
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
	
	local old = _private._focus
	
	_private._focus = PID
	
	windowHandler.gotoWindow(old, PID)
	
	os.queueEvent("goto")
	coroutine.yield("goto")
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
	errorUtils.assertLog(isSU() or not _private._processes[PID].SU, "Error: process with PID " .. (_private._focus or "") .. " tried to kill root process", 2, nil, "Warning")
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	_private.killProcessInternal(PID)
end

function startProcesses(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	errorUtils.assert(not _private._focus, "Error: kernel already running", 2)
	
	local current = term.current()
	
	gotoPID(PID)
	
	windowHandler.init()
	
	local data = {} --the events we are listening for
	
	while _private._focus do
		_private.tick(data)
		data = _private.getEvent()
	end
	
	_private._runningPID = nil
	
	os.shutdown()
end