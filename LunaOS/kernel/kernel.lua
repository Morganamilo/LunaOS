local _processes = {}
local _eventQue = {}
local jumpToPID


function getProcesses()
	return  _processes
end


function getEventQue()
	return  _eventQue
end


function killProcess(PID)
	assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist")
	print('killed ' .. PID)
	_processes[PID] = nil
end


function gotoPID(PID)
	jumpToPID = PID
	coroutine.yield()
end


function queEvent(event, ...)
	if isWainingfor(event) then
		_eventQue[tableUtils.getEmptyIndex(_eventQue)] = {event, ...}
	end
end


function queEventNow(event, ...)
	queEvent(event, ...)
	coroutine.yield() 
end


function getWaitingEvents()
	local events = {}
	
	for _, v in pairs(_processes) do
		event[#event + 1] = v.waitingFor[1]
	end
	
	return event
end


function isWainingfor(event)
	for _, v in pairs(_eventQue) do
		if v[1] == event then return false end
	end

	for _, v in pairs(_processes) do
		if v.waitingFor then
			if v.waitingFor[1] == event then return true end
		end
	end
	
	return false
end

--[[
processes should be run if:
	it has never range
	if it yielded nil
	or if an event in nte que matches its yield 
--]]
local function processesShouldBeRun(proc)
	if proc then
		if not proc.waitingFor then
			return true
		else
			for k, v in pairs(_eventQue) do
				if proc.waitingFor[1]  == v[1] then return true, k end
			end
		end
	end
	
	return false
end 


--[[
func		is the fuction everytime the process is called
time		is how often the processes should run. a time of 2 would run every 2 seconds 
desc		is a description of the processes for the user
--]]
function newProcess(func, time, desc)
	assert(type(func) == "function", "Error: function expected got " .. type(func))

	local PID = tableUtils.getEmptyIndex(_processes)
	local time = time or 0
	local desc = desc or ""
	
	local co = coroutine.create(func)
	_processes[PID] = {co = co, time = time, desc = desc, PID = PID}
	return PID
end


--process can still spawn new processes while inside startProcesses()
function startProcesses()
	repeat
		local processes = {}
		
		processes = tableUtils.optimize(_processes)
		
		local procCount = #processes
		
		for n = 1, procCount do
			local status
			local event 
			local pSBR, queKey = processesShouldBeRun(processes[n])
			
			if  pSBR  then
				local time = os.clock()
			
				if (processes[n].lastRun or 0) <= time - processes[n].time then --if atleast the specified time has passed
					processes[n].lastRun = time
					
					_processes[n].waitingFor = {coroutine.resume(processes[n].co, _eventQue[queKey])}
					print(unpack(_processes[n].waitingFor))
					
					if (_eventQue[queKey]) then
						_eventQue[queKey] = nil
						tableUtils.optimize(_eventQue)
					end
					
					--print(queKey)
				
					status = _processes[n].waitingFor[1]
					event =  _processes[n].waitingFor[2]
					
					_processes[n].waitingFor = tableUtils.range(_processes[n].waitingFor, 2, #_processes[n].waitingFor)
					if #_processes[n].waitingFor == 0 then _processes[n].waitingFor = nil end
			
					if coroutine.status( processes[n].co) == "dead" then
						killProcess( processes[n].PID)
						processes[n] = nil
						procCount = procCount - 1
					end
				end
			end
			
			local timer = os.startTimer(0.05)
			backroundData = {coroutine.yield()}
			
			if backroundData[1] ~= "timer" then 
				os.cancelTimer(timer)
				print(unpack(backroundData))
				queEvent(unpack(backroundData)) 
			end
		end
		
		os.sleep(0) --stops too long without yielding error
	until (procCount <= 0)
end
