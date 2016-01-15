--the kernel allows multiple processes to be created
--only one process can run at a time
--process can pause to let another process run then continue
--when a process errors the process is kissed and a report is sent back

local _processes = {}
local _runningHistory = {}
local _env = {}
local _runningPID

local rootEnv = _G
local userEnv = _G

local externelHandleError
local showErrors = true

local function getEnv(SU)
	local env = tableUtils.copy(_ENV)
	env._G = env
	
	if not SU then
		env.print = function() print("nope") end
		env.y = "yp."
	end
	
	return env
end

function setShowErrors(bool)
	errorUtils.assert(type(bool) == "boolean", "Error: function expected got " .. type(func), 2)
	showErrors = bool
end

--allows an error to be handled by an extarnaly such as a GUI
function setErrorHandler(func)
	errorUtils.assert(type(func) == "function", "Error: function expected got " .. type(func), 2)
	externelHandleError = func
end


local function handleError(proc, data)
	--was not sure if i wanted errors to be coloured as it would force the text colour to be while after the error
	--although the crashed process may have had some colour set, and if it crashed before it set it back
	--then the colour would leak into another program
	term.setTextColor(colors.red)

	print("Error: process Has crashed")
	print("\tPID: ".. proc.PID)
	print("\tName: ".. proc.name)
	print("\tReason: ".. data)
	print("Returning to processes\n")
	
	term.setTextColor(1)
	os.sleep(1)
end


function getProcesses()
	return  _processes
end

function getRunning()
	return _runningPID
end

function isSU()
	if not _runningPID then return true end --if the kernel is not in use give root
	return _processes[_runningPID].SU
end


function killProcess(PID)
	errorUtils.assert(_processes[PID], "Error: PID " .. tostring(PID) .. " is invalid or does not exist", 2)
	errorUtils.assert(_processes[_runningPID].SU or not _processes[PID].SU,  "Error:  process with PID " .. tostring(_runningPID) .. " tried to kill process " .. PID .. ": Access denied" , 2)

	--ruturns  a table of the process and all its children and all its sub children and so on
	local function getAllChildren(PID)
		local allChildren = {PID}
		local parentPID = _processes[PID].parent
		local i = 1
		local highestPID
				
		while allChildren[i] do
			for _, v in pairs(_processes[allChildren[i]].children) do
				allChildren[#allChildren + 1] = v
			end
			
			i = i + 1
		end
		
		return allChildren
	end
	
	--only tell the parent of its death if there is a parent
	local parent = _processes[_processes[PID].parent]
	if parent then 
		for child = 1, #parent.children do
			if parent.children[child] == PID then 
				--print("removing link to " ..  PID .. " inside of " .. parent.PID)
				table.remove(parent.children, child)
			end
		end
	end
	
	for _, v in pairs(getAllChildren(PID)) do
		_processes[v] = nil
		_env[PID] = nil
	end
	
	--removes the process from the _runninHistory
	local index = tableUtils.isInTable(_runningHistory, PID)
	if index then
		table.remove(_runningHistory, index)
	end
	
	
	--when a process is killed the process that takes over is decided it the order as follows
				--its parent
				--the process that ran last and is still alive
				--the process with the highest PID
				--nil
				
	 if table.getn(_processes) > 0 then highestPID = table.getn(_processes)
	 else highestPID = nil end
	
	_runningPID = parentPID or _runningHistory[#_runningHistory] or highestPID
end


function gotoPID(PID)
	errorUtils.assert(_processes[PID], "Error: PID " .. tostring(PID) .. " is invalid or does not exist", 2)
	_runningPID = PID
	
	local index = tableUtils.isInTable(_runningHistory, PID)
	
	--if the PID is already in the history move it to the top
	if index then
		table.remove(_runningHistory, index)
	end
	
	_runningHistory[#_runningHistory] = PID
	os.queueEvent('switch')
	coroutine.yield()
end


--func		is the fuction everytime the process is called
--name 	in the processes name for the user
--desc		is a description of the processes for the user

local function newProcessInternal(func, parent, name, desc, SU)
	local PID = tableUtils.getEmptyIndex(_processes)
	local name = name or ''
	local desc = desc or ''
	
	errorUtils.assert(type(func) == "function", "Error: function expected got " .. type(func), 2)
	errorUtils.assert(type(name) == "string", "Error: string expected got " .. type(name), 2)
	errorUtils.assert(type(desc) == "string", "Error: string expected got " .. type(desc), 2)
	
	if parent then
		--tells the parent it has children
		errorUtils.assert(_processes[parent], "Error: PID " .. parent .. " is invalid or does not exist", 2)
		_processes[parent].children[#_processes[parent].children + 1] = PID
	end
	
	local env = getEnv(SU)
	_env[PID] = env -- sandboxes each process
	
	local co = coroutine.create(setfenv(func, env))
	
	_processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU}
	return PID
end


function newProcess(func, parent, name, desc)
	newProcessInternal(func, parent, name, desc, false)
end


function newRootProcess(func, parent, name, desc)
	errorUtils.assert(isSU(), "Error: process with PID " .. (_runningPID or "") .. " tried to start a new process as root: Access denied", 2)
	newProcessInternal(func, parent, name, desc, true)
end


function startProcesses()
	if #tableUtils.optimize(_processes) <= 0 or not _runningPID then return end

	local data = {}

	while true do
		local currentProc = _processes[_runningPID]
		data = {coroutine.resume(currentProc.co, unpack(data))}
		success = data[1]
		table.remove(data, 1) --removes sucess from the data
		
		if not success then
			if showErrors then handleError(currentProc, data[1]) end
			if externelHandleError then pcall(externelHandleError, currentProc, data[1]) end
		end
		
		if coroutine.status(currentProc.co) == "dead" then
			killProcess(currentProc.PID)
			data = {} --data is wiped so it does not get passed to the next processes
			if #tableUtils.optimize(_processes) <= 0 or not _runningPID then break end
		else --only process its yield if the process is still alive
			local waitingFor = data
			
			repeat 
				data = {coroutine.yield()}
				--if data[1] == "terminate" then killProcess(_runningPID) end
				if data[1] == "terminate" then error() end
			until (tableUtils.isInTable(waitingFor, data[1]) or #waitingFor == 0)
		end
	end
end
