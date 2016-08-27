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
windowHandler.setPrivate(_private)

_private._processes = {}
_private._runningPID = nil --pid of the currently running process 
_private._runningHistory = {}
_private._waitingFor = {}
--local keyHandlerPath = "/LunaOS/system/kernel/keyHandler.lua"
--windowHandler = {} --os.loadAPILocal(keyHandlerPath)

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
		
		keyHandler.handleKeyEvent(event)
		windowHandler.handleEvent(event)
		
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
	return _private.runProgramInternal(program, parent, true, arg)
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

function getCurrentPackage()
	if _private._runningPID then
		return _private._processes[_private._runningPID].package
	end
end

function getCurrentPackagePath()
	if _private._runningPID then
		return packageHandler.getPackagePath(_private._processes[_private._runningPID].package)
	end
end

function getCurrentDataPath()
	if getCurrentPackage() then
		return fs.combine(packageHandler.getDataPath(), getCurrentPackage())
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
	errorUtils.assertLog(isSU() or not _private._processes[PID].SU, "Error: process with PID " .. (_private._runningPID or "") .. " tried to kill root process", 2, nil, "Warning")
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	
	_private.killProcessInternal(PID)
end

function startProcesses(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], "Error: PID " .. PID .. " is invalid or does not exist", 2)
	errorUtils.assert(not _private._runningPID, "Error: kernel already running", 2)
	
	local current = term.current()
	
	gotoPID(PID)
	
	windowHandler.init()
	
	local data = {} --the events we are listening for
	
	while _private._runningPID do
		data = _private.next(data)
		data = _private.getYield(data)
	end
	
	term.redirect(current)
	term.setBackgroundColor(colors.black)
	term.setTextColor(1)
	term.clear()
	term.setCursorPos(1,1)
	
	--print("Craft OS")
	os.shutdown()
end