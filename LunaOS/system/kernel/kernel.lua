--the kernel allows multiple processes to be created
--only one process can run at a time
--process can pause to let another process run then continue
--when a process errors the process is killed and a report is sent back

local _processes = {} --table of all processes
local _runningHistory = {} --keeps the order of which process was open last and was open before that etcetera
local _env = {} --contains the enviroment of each process
local _runningPID = nil --pid of the currently running process 
local _waitingFor = {}

local programDataPath = "/lunaos/data/data"
local fs = fs
local windowHandler
local programPath = lunaOS.getProp("programPath")


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
	term.clear()
	term.setCursorPos(1,1)
	term.write("Critical Error")
	term.setCursorPos(1,2)
	term.write(msg)
	term.setCursorPos(1,2)
	term.write("Press any key to shutdown")
	coroutine.yield("key")
	os.shutdown()
end

function getProgramDataPath()
	return programDataPath
end

function setWindowHandler(tbl)
	windowHandler = tbl
end

--returns the stock enviroment for each process 
local function getEnv(SU)
	local env = tableUtils.deepCopy(_ENV)
	
	env._G = env
	env._ENV = env
	
	setfenv(1, env)
	--dofile("/LunaOS/system/apis/override.lua")
	
	if not SU then
		--dofile("/LunaOS/system/apis/userOverride.lua")
	end
	
	return env
end


--func		is the fuction that becomes the processes thread
--name 	is the processes name for the user
--desc		is a description of the processes for the user
local function newProcessInternal(func, parent, name, desc, SU, dir)
	errorUtils.assert(type(func)  == "function", "Error: function expected got " .. type(func), 3)
	errorUtils.assert(type(name) == "string" or "nil", "Error: string expected got "       .. type(name), 3)
	errorUtils.assert(type(desc)  == "string" or "nil", "Error: string expected got "       .. type(desc), 3)
	
	local PID = tableUtils.getEmptyIndex(_processes)
	local name = name or ''
	local desc = desc or ''
	
	if parent then
		--tells the parent it has children
		errorUtils.assert(_processes[parent], "Error: PID " .. parent .. " is invalid or does not exist", 2)
		_processes[parent].children[tableUtils.getEmptyIndex(_processes[parent].children)] = PID
	end
	
	local env = getEnv(SU)
	_env[PID] = env -- sandboxes each process
	
	setfenv(func, env)
	--setfenv(function() 
		--dofile("/LunaOS/system/apis/override.lua")
		--if not SU then dofile("/LunaOS/system/apis/userOverride.lua") end
	--end, env)()
	
	local co = coroutine.create(func)
	local window = windowHandler.newWindow(PID)
	env.term.native = function() return window end
	
	_processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU, dir = dir, window = window}
	log.i("Created new " .. (SU and "Root" or "User") .. " process with PID " .. PID)
	return PID
end

function newProcess(func, parent, name, desc)
	return newProcessInternal(func, parent, name, desc, false)
end

function newRootProcess(func, parent, name, desc)
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to start a new process as root: Access denied", 2, nil, "Warning")
	return newProcessInternal(func, parent, name, desc, true)
end

function runFile(path, parent, name, desc)
	return newProcess(function() dofile(path) end, parent, name, desc)
end

function newRootFile(path, parent, name, desc)
	return newRootProcess(function() dofile(path) end, parent, name, desc)
end

local function runProgramInternal(program, su, ...)
	local root = fs.combine(programPath, program)
	local name
	local args = unpack(arg)
	args.n = nil
	
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
	
	local file = loadfile(fs.combine(root, name))
	setfenv(file, getfenv(1)) 
	
	local PID = newProcessInternal(
		function() file(args) end,
		nil,
		program,
		desc,
		su,
		root
	)
end

function runProgram(program, ...)
	return runProgramInternal(program, false, arg)
end

function runRootProgram(program, ...)
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to start a new program as root: Access denied", 2, nil, "Warning")
	runProgramInternal(program, true, arg)
end

--ruturns a copy of all processes excluding the thread
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
	errorUtils.assert(_processes[PID], "Error: PID " .. tostring(PID) .. " is invalid or does not exist", 2)
	log.i("Going to PID " .. PID)
	
	--if the PID is already in the history move it to the top
	local index = tableUtils.isIn(_runningHistory, PID)
	if index then
		table.remove(_runningHistory, index)
	end
	
	_runningHistory[#_runningHistory + 1] = PID
	
	local old = _runningPID and _processes[_runningPID].window or nil
	windowHandler.gotoWindow(old, _processes[PID].window)
	_runningPID = PID
	
	os.queueEvent('goto', unpack(arg))
	return coroutine.yield("goto")
end


function getAllChildren(PID)
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

function killProcess(PID)
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
		_env[v] = nil
		
		--removes the process from the _runningHistory
		local index = tableUtils.isIn(_runningHistory, v)
		if index then
			table.remove(_runningHistory, index)
		end
	end
	
	_runningPID = nil
	
	log.i("Finished killing: " .. PID)
	print("killed " .. PID)
	
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
		currentProc.co = coroutine.create(function() windowHandler.handleError(currentProc, data[1]) end)
		data = {}
	end
	
	if coroutine.status(currentProc.co) == 'dead' then --handle death
		killProcess(currentProc.PID)
		data = {}
	end
	
	return data
end

local function getYield(data)
	local proc = _runningPID
	local event
	
	repeat
		event = {coroutine.yield()} --the event we get + extra data
		
		if proc ~= _runningPID then --if the process has changed since we starded the loop
			if _processes[proc] then _waitingFor[proc] = data end
			return data 
		else
			_waitingFor[proc] = nil
		end
		
		local success, res = pcall(windowHandler.handleEvent, event)
		if not success then cirticalError(res) end
	until tableUtils.isIn(data, event[1]) or #data == 0
	
	return event
end

--starts the specified pocess
function startProcesses(PID)
	errorUtils.assert(_processes[PID], "Error: PID " .. tostring(PID) .. " is invalid or does not exist", 2)
	errorUtils.assert(not _runningPID, "Error: kernel already running", 2)
	gotoPID(PID)
	
	local success, res = pcall(windowHandler.init)
	if not success then cirticalError(res) end
	
	local data = {} --the events we are listening for
	
	while _runningPID do
		data = next(data)
		data = getYield(data)
	end
	
	os.shutdown()
end










