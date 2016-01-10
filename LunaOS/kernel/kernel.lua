--the kernel allows multiple processes to be created
--only one process can run at a time
--process can pause to let another process run then continue
--when a process errors the process is kissed and a report is sent back

local _processes = {}
local _runnindHistory = {}
local _runnindPID = 1

local externelHandleError
local showErrors = true

function setShowErrors(bool)
	assert(type(bool) == "boolean", "Error: function expected got " .. type(func))
	showErrors = bool
end

function setErrorHandler(func)
	assert(type(func) == "function", "Error: function expected got " .. type(func))
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

function killProcess(PID)
	os.sleep(.2)
	local removeLinks = false

	local function killChildren(parentPID) --recursively kills all the children of given PID
		for child = 1, #_processes[parentPID].children do
			--print("killing child " .. (_processes[parentPID].children[child]))
			killProcess(_processes[parentPID].children[child])
		end
	end
	
	local function removeLinksToParent(childPID) --if a child dies, the parent needs to be told
		local parent = _processes[_processes[childPID].parent]
		
		for child = 1, #parent.children do
			if parent.children[child] == childPID then 
				print("removing link to " ..  childPID .. " inside of " .. parent.PID)
				table.remove(parent.children, child)
			end
		end
	end
	
	
	if PID then assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist") end
	
	local index = tableUtils.isInTable(_runnindHistory, PID)
	if index then
		table.remove(_runnindHistory, index)
	end
	
	if _processes[PID].parent then  removeLinksToParent(PID) end
	if #_processes[PID].children > 0 then killChildren(PID) end
	
	
	print('killed ' .. PID)
	_processes[PID] = nil
end


function gotoPID(PID)
	assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist")
	_runnindPID = PID
	
	local index = tableUtils.isInTable(_runnindHistory, PID)
	
	--if the PID is already in the history move it to the top
	if index then
		table.remove(_runnindHistory, index)
	end
	
	_runnindHistory[#_runnindHistory] = PID
	
end

--func		is the fuction everytime the process is called
--name 	in the processes name for the user
--desc		is a description of the processes for the user
function newProcess(func, parent, name, desc)
	assert(type(func) == "function", "Error: function expected got " .. type(func))
	
	if name then
		assert(type(name) == "string", "Error: string expected got " .. type(name))
	end
	
	if desc then
		assert(type(desc) == "string", "Error: string expected got " .. type(desc))
	end	

	local PID = tableUtils.getEmptyIndex(_processes)
	local name = name or ''
	local desc = desc or ''
	
	if parent then
		--tells the parent it has children
		assert(_processes[parent], "Error: PID " .. parent .. " is invalid or does not exist")
		_processes[parent].children[#_processes[parent].children + 1] = PID
	end
	
	local co = coroutine.create(func)
	_processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID}
	return PID
end

function startProcesses()
	local data = {}
	local waitingFor

	while #tableUtils.optimize(_processes) > 0 do
		local currentProc = _processes[_runnindPID]
	
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
			
			--when a process is killed the process that takes over is decided it the order as follows
				--its parent
				--the process that ran last and is still alive
				--the process with the highest PID
			_runnindPID = currentProc.parent or _runnindHistory[#_runnindHistory] or table.getn(_processes)
		end
		
		waitingFor = data
			
		repeat 
			data = {coroutine.yield()}
			--if data[1] == "terminate" then killProcess(_runnindPID) end
			if data[1] == "terminate" then error() end
		until (tableUtils.isInTable(waitingFor, data[1]) or #waitingFor == 0)
	end
end
