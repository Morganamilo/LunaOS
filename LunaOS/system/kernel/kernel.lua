--the kernel allows multiple processes to be created
--only one process can run at a time
--process can pause to let another process run then continue
--when a process errors the process is killed and a report is sent back

local _processes = {} --table of all processes
local _runningHistory = {} --keeps the order of which process was open last and was open before that etcetera
local _env = {} --contains the enviroment of each process
local _runningPID --pid of the currently running process 
local errorFunc

function setErrorHandle()
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to change error handler: Access denied", 2, nil, "Warning")
end


--returns the stock enviroment for each process 
function getEnv(SU)
	local env = tableUtils.deepCopy(_ENV)
	
	env._G = env
	env._ENV = env
	
	setfenv(1, env)
	--dofile("/LunaOS/system/apis/override.lua")
	
	if not SU then
		dofile("/LunaOS/system/apis/userOverride.lua")
	end
	
	return env
end



--outputs a process error to the screen
local function handleError(proc, data)
	log.e("Process " .. proc.name .. " (" ..  proc.PID .. ") has crashed: " .. data)
	term.setTextColor(colors.red)

	print("Error: process Has crashed")
	print("\tPID: ".. proc.PID)
	print("\tName: ".. proc.name)
	print("\tReason: ".. data)
	print("Returning to processes\n")
	
	term.setTextColor(colors.white)
	os.sleep(1)
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
	
	_processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU, dir = dir}
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

local function runProgramInternal(program, root, ...)
	local root = "/lunaos/programs/"
	local name
	local args = unpack(arg)
	args.n = nil
	
	if fs.isDir(root .. program) then
		if fs.isFile(fs.combine(root, program, program .. '.lua')) then
			name = program .. '.lua'
		elseif fs.isFile(fs.combine(root, program, program)) then
			name = program
		elseif fs.isFile(fs.combine(root, program, 'main.lua')) then
			name = 'main.lua'
		elseif fs.isFile(fs.combine(root, program, 'main')) then
			name = 'main'
		elseif fs.isFile(fs.combine(root, program, 'startup.lua')) then
			name = 'startup.lua'
		elseif fs.isFile(fs.combine(root, program, 'startup')) then
			name = 'startup'
		end
	end
	
	if not name then return end
	
	local PID = newProcessInternal(
		function() local file = loadfile(fs.combine(root, program, name)) setfenv(file, getfenv(1)) file(args) end,
		_runningPID,
		program,
		desc,
		su,
		fs.combine(root, program)
	)

	kernel.gotoPID(PID)
end

function runProgram(program, ...)
	runProgramInternal(program, false, arg)
end

function runRootProgram(program, ...)
	errorUtils.assertLog(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to start a new program as root: Access denied", 2, nil, "Warning")
	runProgramInternal(program, true, arg)
end

--ruturns a copy of all processes excluding the thread
function getProcesses()
	local procs = {}
	
	for k, v in pairs(_processes) do
		procs[k] = v
		procs[k].co = nil
	end
	return procs
end

function getProcess(n)
	local proc = tableUtils.copy(_processes[n])
	proc.co = nil
	return proc
	
end
function getRunning()
	return _runningPID
end

function getRunningProgram()
	if _runningPID then
		return _processes[_runningPID].dir
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
	
	_runningPID = PID
	
	--if the PID is already in the history move it to the top
	local index = tableUtils.isIn(_runningHistory, PID)
	if index then
		table.remove(_runningHistory, index)
	end
	
	_runningHistory[#_runningHistory + 1] = PID
	os.queueEvent('goto', unpack(arg))
	return coroutine.yield("goto")
end


local function getAllChildren(PID)
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
		log.i("killing " .. PID)
		_processes[v] = nil
		_env[PID] = nil
		
		--removes the process from the _runningHistory
		local index = tableUtils.isIn(_runningHistory, v)
		if index then
			table.remove(_runningHistory, index)
		end
	end
	
	log.i("Finished killing: " .. PID)
	print("killed " .. PID)
	
	--decide the process that takes over
	local newRunning = thisPoc.parent or _runningHistory[#_runningHistory]
	if newRunning then
		gotoPID(newRunning) 
	else
		_runningPID = nil
		os.queueEvent("stop")
		coroutine.yield("stop")
	end
end

--starts the specified pocess
function startProcesses(PID)
	--stop if a process is already running. gotoPID should be used instead
	if _runningPID then return end
	
	errorUtils.assert(_processes[PID], "Error: PID " .. tostring(PID) .. " is invalid or does not exist", 2)
	_runningHistory[#_runningHistory + 1] = PID
	_runningPID = PID
	
	local data = {}
	while _runningPID do
		local currentProc = _processes[_runningPID]
		data = { coroutine.resume(currentProc.co, unpack(data)) }
		success = data[1]
		table.remove(data, 1) --give success its own varible then remove it from the table

		if not success then
			handleError(currentProc, data[1])
		end

		if coroutine.status(currentProc.co) == "dead" then
			killProcess(currentProc.PID)
			--if table.getn(_processes) == 0 or not _runningPID then break end
			data = {} --data is wiped so it does not get passed to the next processes
		else
			 --process its yield if the process is still alive
			 local event
			 
			repeat
				event = {coroutine.yield()}
				if event[1] == "terminate" then 
					printError("Killed process " .. _runningPID)
					killProcess(_runningPID)
					break
					end
			until tableUtils.isIn(data, event[1]) or #data == 0
			
			data = event
		end
		
	end

		log.i("Kernel has finished running")
end
