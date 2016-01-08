local _processes = {}

function getProcesses()
	return  _processes
end

function killProcess(PID)
	assert(_processes[PID], "Error: PID " .. PID .. " is invalid or does not exist")
	_processes[PID] = nil
end


--[[
func is the fuction everytime the process is called
time is how often the processes should run. a time of 2 would run every 2 seconds 
desc is a description of the processes for the user
--]]
function newProcess(func, time, desc)
	assert(type(func) == "function", "Error: function expected got " .. type(func))

	local PID = 1
	local time = time or 0
	local desc = desc or ""
	
	
	while _processes[PID] do --we set the PID of the process to the lowest avalible PID
		PID = PID + 1
	end
	
	local co = coroutine.create(func)
	_processes[PID] = {co = co, time = time, desc = desc, PID = PID}
end


function startProcesses()
	while true do
		local processes = {}
		local procData =  {}
		
		for _, proc in pairs(_processes) do --build linear table of processes incase a process has been killed leaving a gap it PIDs
			 processes[#processes + 1] = proc
			 if not processes[#processes].lastRun then processes[# processes].lastRun = 0 end
		end
		
		local procCount = #processes
		
		for n = 1, procCount do
			local time = os.clock()
			
			if processes[n].lastRun <= time - processes[n].time then --if atleast the specified time has passed
				processes[n].lastRun = time
				procData = {coroutine.resume( processes[n].co, table.unpack(procData))}
			
				if  processes[n] then
					if coroutine.status( processes[n].co) == "dead" then
						killProcess( processes[n].PID)
						processes[n] = nil
						procCount = procCount - 1
					end
				end
			end
		end
		
		if procCount <= 0 then break end
		os.sleep(0) --stops too long without yielding error
	end
end
