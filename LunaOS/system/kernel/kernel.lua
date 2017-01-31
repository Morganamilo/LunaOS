---The kernel allows multiple processes to be created from either functions, files or programs
--Only one process can run at a time so each process runs then pauses to let another process run.
--Processes have two permission levels superuser and non superuser.
--Superuser process have full rights to running things as root, killing other processes
--and acessing the file system.
--System programs may choose to gain superser rights whenever they choose.
--Process choose when they pause, the kernel had no control over this. 
--If a Process runs for 10 seconds without pauseing it will error.
--When a process errors the process is killed and the error is shown to the user.
--Processes have:
--	<ul>
--		<li>a thread</li>
--		<li>a PID</li>
--		<li>a parent</li>
--		<li>a name</li>
--		<li>a description</li>
--		<li>a superuser value</li>
--		<li>a package</li>
--	</ul>
--@author Morganamilo
--@copyright Morganamilo 2016
--@module kernel

local format = string.format
local fileNoExist = errorUtils.strings.fileNoExist
local PIDError = errorUtils.strings.PIDError

---Save the term.native function.
local oldNative = term.native

---Save the old loadfile function
local oldLoadfile = loadfile

---Save the old file system so we can bypass the file permissions.
local fs = fs

---Whether the main process loop is running.
local _running = false

---The windowHandler is an API for managing the window each process exists in
--and how each window should be placed, drawn ect.
local windowHandler = os.loadAPILocal("/LunaOS/system/kernel/windowHandler.lua")

---A list of event thats should only be passed the the processed currently focused.
--This stops typing and other such actions being handled by all processes thinking the user
--is typing to them.
--@table focusEvents
local focusEvents = {"mouse_click", "mouse_up", "mouse_drag", "mouse_scroll", "char", "key", "key_up", "paste", "terminate", "monitor_totch"}

---Holds all private varibles and functions allowing them to be passed to the windowHandler
--without the functions being accessble to the user.
--@table _pivate
local _private = {}

---A list of All currently alive processes.
--@table _private._processes
_private._processes = {}

---The process curently in focus.
---@table _private._focus
_private._focus = nil

--the process that is currently running 
--it is not the one the user is using, it may be running in the background
_private._runningPID = nil --pid of the currently running process 


---Keeps a history of all process that have run and the order that they were run in
--@table _private._runningHistory
_private._runningHistory = {}

---Tracks what event each process is waiting for
--@table _private._waitingFor
_private._waitingFor = {}

---Path to program data
_private.dataPath = lunaOS.getProp("dataPath")

---Path to packages
_private.packagePath = lunaOS.getProp("packagePath")

--pass private values to the windowHandler
windowHandler.setPrivate(_private)

local oldLoadfile = _G.loadfile
function _G.loadfile(path, env)

	local func, err = oldLoadfile(path, env)

	if not func then
		return nil, err
	end

	if _running then
		local pStack = _private._processes[_private._runningPID].programStack

		return function(...)
			pStack[#pStack + 1] = fs.combine(path, "")
			local success, err = pcall(func, ...)
			pStack[#pStack] = nill

			if not success then
				error(err, 0)
			end
		end
	end

	return func
end

--Replaces the deafult term.native function with one that is aware of the current
--process and pretends that the processes window is the native one.
--@return The window of the currently running process. If there is no running process return the true native window.
--@usage locale window = term.native()
function term.native()
	if not _private._focus then
		return oldNative()
	end

	return _private._processes[_private._runningPID].window
end

---Overide the default loadString function so that it uses the old fileSystem.
--This allows the kernel to load any files whether ot not the user currently has
--acess to that file.
--@param path The path to the file that is to be loaded.
--@return Function generated from the file.
--@error "File not found"
--@usage local function, err = loadfile("/rom/programs/shell")
loadfile = function(path, env)
    local file = fs.open( path, "r" )

	if file then
        local func, err = load( file.readAll(), fs.getName( path ) , "t", env)
        file.close()
        return func, err
    end
	
    return nil, format(fileNoExist, path)
end

function os.run( _tEnv, _sPath, ... )
    local tArgs = { ... }
    local tEnv = _tEnv

	setmetatable( tEnv, { __index = _private._processes[_private._runningPID].env._G } )

    local fnFile, err = _G.loadfile( _sPath, tEnv )
    if fnFile then
        local ok, err = pcall( function()
            fnFile( table.unpack( tArgs ) )
        end )
        if not ok then
            if err and err ~= "" then
                printError( err )
            end
            return false
        end
        return true
    end
    if err and err ~= "" then
        printError( err )
    end
    return false
end

---Displays a an error message then shuts down the computer.
--This function should be used for when the kernel errors in such
--a way that the safest option is to stop and shutdown.
--@param msg The error string to be displayed
--@usage _private.ciritalError("oh no there was an error")
--@local
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

---Gets the process enivroment.
--A new copy of the current enviroment is used so that functions
--are sandboxed and can not access eachothers vaibles.
--@return The new enviroment table created.
--@local
function _private.getEnv()
	local env = tableUtils.deepCopy(_ENV)
	
	env.a = 34
	env._G.a = 23
	--env._G = env
	--env._ENV = env
	
	return env
end

---Creates a new process that can be run by the kernel.
--The process is added to @{_private._processes}
--The process is a table with fields
--	<ul>
--		<li>co</li>
--		<li>parent</li>
--		<li>children</li>
--		<li>name</li>
--		<li>desc</li>
--		<li>PID</li>
--		<li>SU</li>
--		<li>package</li>
--		<li>window</li>
--	</ul>
--@param func The function that is becomes the processes thread
--@param parent The processes parent, can be nil.
--@param name The name of the process, can be nil.
--@param desc The description of the process, can be nil,
--@param SU Whether or not the process has superuser rights.
--@param package The package the process belongs to, can be nil.
--@return The PID of the newley created process.
--@raise bad argument error - if an argument is mismatched or missing. invalid PID error - if parent does not exits.
--@usage _private.newProcessInternal(func, nil, "a process", "this process is amazing", true, nil)
--@local
function _private.newProcessInternal(path, parent, name, desc, SU, ...)
	--check some arguments are the correct types
	errorUtils.expect(path, 'string', true, 3)
	errorUtils.expect(parent, 'number', false, 3)
	errorUtils.expect(name, 'string', false, 3)
	errorUtils.expect(desc, 'string', false, 3)
	
	---@warning Using the same function for multiple processes breaks sandboxing because they share local varibles.
	local PID = tableUtils.getEmptyIndex(_private._processes)
	local env = _private.getEnv()
	
	name = name or fs.getName(path):match("^[^%.]+") or ""
	desc = desc or ''
	
	if parent then
		--make sure the parent is a valid PID
		errorUtils.assert(_private._processes[parent], format(PIDError, parent), 3)
		--tells the parent it has children
		_private._processes[parent].children[tableUtils.getEmptyIndex(_private._processes[parent].children)] = PID
	end
	
	local func = function()
		_G.loadfile(path, env)(unpack(arg))
	end

	--function that goes on to create the thread
	--pcall th function for saftey and let windowHandler
	--take control of the thread if the function ends
	--or errors
	local wrappedFunc = function()
        local success, res = errorUtils.stackCall(func)

		if not success then
			windowHandler.handleError(_private._processes[_private._runningPID], res)
		else
			windowHandler.handleFinish(_private._runningPID)
		end
	end
	
	
	local co = coroutine.create(wrappedFunc)
	local window = windowHandler.newWindow(PID)
	
	--the actual process
	_private._processes[PID] = {co = co, parent = parent, children = {}, name = name, desc = desc, PID = PID, SU = SU, window = window, programStack = {}, env = env}
	
	--log the great birth of process mc process face
	log.i("Created new " .. (SU and "Root" or "User") .. " process with PID " .. PID)

	windowHandler.updateBanner()
	
	return PID
end

---Creates a new process with a given function, parent, name and description.
--@see _private.newProcessInternal
--@param func The function that the process runs.
--@param parent The parent PID of the new process.
--@param name The name of the new process.
--@param desc The description of the new process.
--@return The PID of the new process.
--@usage kernel.newProcess(func, 1, "new process", "this is a new process")
function newProcess(path, parent, name, desc, ...)
	return _private.newProcessInternal(path, parent, name, desc, false, ...)
end

---Creates a new process as root with a given function, parent, name and description.
--Must have root to call this funtion
--@see _private.newProcessInternal
--@see newProcess
--@param func The function that the process runs.
--@param parent The parent PID of the new process.
--@param name The name of the new process.
--@param desc The description of the new process.
--@return The PID of the new process.
--@raise permission error - if current process is not root.
--@usage kernel.newRootProcess(func, 1, "new process", "this is a new process")
function newRootProcess(path, parent, name, desc, ...)
	errorUtils.assertLog(isSU(), "Process with PID " .. (_private._runningPID or "") .. " tried to start a new process as root: Access denied", 2, nil, "Warning")
	return _private.newProcessInternal(path, parent, name, desc, true, ...)
end

-----Similar to @{_private.newProcessInternal} except runs
----a program instead of a function.
----Processes created with this function are given a package field.
----This allows the process to access protected files that belong to its Package.
----@param program The program to be ran.
----@param parent The processes parent, can be nil.
----@param su Whether or not the process has superuser rights.
----@param args The arguments passed to the program.
----@return The PID of the newley created process.
----@raise bad argument error - if an argument is mismatched or missing. program does not exit error - if the program does not exist.
----@usage _private.newProgramInternal("Explorer", nil, true, "/rom")
----@local
--function _private.runProgramInternal(program, parent, su, args)
--	errorUtils.expect(program, 'string', true, 3)
--
--	--the package path
--	local root = packageHandler.getPackagePath(program)
--	local name
--
--
--    if not root then
--        return nil, "Program does not exist"
--    end
--
--
--	local isFile = _G.fs.isFile
--
--	--first try to open programName.lua
--	if isFile(fs.combine(root, program .. '.lua')) then
--		name = program .. '.lua'
--	--second try programName
--	elseif isFile(fs.combine(root, program)) then
--		name = program
--	--third try main.lua
--	elseif isFile(fs.combine(root, 'main.lua')) then
--		name = 'main.lua'
--	--fourth try main
--	elseif isFile(fs.combine(root, 'main')) then
--		name = 'main'
--	--fith try startup.lua
--	elseif isFile(fs.combine(root, 'startup.lua')) then
--		name = 'startup.lua'
--	--sixth try startup
--	elseif isFile(fs.combine(root, 'startup')) then
--		name = 'startup'
--	else
--		--theres not startup file we can run so error
--
--        return nil, "Missing startup file"
--	end
--
--	--we got a file so lets try load it
--	local file, err = loadfile(fs.combine(root, name))
--
--	--if we didnt get a file so error
--	if not file then
--        return nil, err
--    end
--
--	_private.sandbox(file)
--
--	--make the process
--	local PID = _private.newProcessInternal(
--		function() file(unpack(args)) end,
--		parent,
--		program,
--		desc,
--		su,
--		program
--	)
--
--	return PID
--end

---Kills the given process and all its children recursivley.
--Also removes the given process from the parents children.
--@param PID The PID of the process to be killed.
--@usage _private.killProcessInternal(3)
--@raise bad argument error - if an argument is mismatched or missing. invalid PID error - if PID does not exist.
--@local
function _private.killProcessInternal(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], format(PIDError, PID), 2)
	
	local thisPoc = _private._processes[PID]
	local children = getAllChildren(PID)
	local parent = _private._processes[thisPoc.parent ]
	
	if parent then
		--iterate over our parent's children until we find ourself
		--then remove ourself from our parents children
		for child = 1, #parent.children do
			if parent.children[child] == PID then
				log.i("Telling " .. parent.PID .. " it no longer has child " .. PID)
				table.remove(parent.children, child)
			end
		end
	end
	
	--kill all the children :(
	for _, v in pairs(children) do
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
	--set the focus to the process that ran last
	--otherwise set it to the process with the lowest PID
	local newRunning = _private._runningHistory[#_private._runningHistory] or tableUtils.lowestIndex(_private._processes)
	
	if newRunning then
		gotoPID(newRunning) 
	else
		_private._focus = nil
	end
end


---Gets the next event and passes it to windowHandler and keyHandler.
--@return The event that was yielded using coroutine.yield.
--@usage local event = _private.getEvent()
--@local
function _private.getEvent()
	--the event we get + extra data
	event = {coroutine.yield()}
		
	keyHandler.handleKeyEvent(event)
	event = windowHandler.handleEvent(event)
	
	return event
end

---Pushes a given event to a given PID.
--Only push the event to the process if the process is not waiting for any specific event.
--or the event is one of the events the process is waiting for.
--This function ensures the process writes to its own window.
--It then sets @{_private._waitingFor}[PID] to the events the process yielded.
--Kills the process if it dies.
--@param PID the PID of the process to push an event to.
--@param event The event to push.
--@usage _private._pushEvent(2, {"key", 5, false})
--@local
function _private.pushEvent(PID, event)
	local waiting  = _private._waitingFor[PID]
	local currentProc = _private._processes[PID]
	
	--make sure the process wants the event
	if not waiting or (#event > 0 and (tableUtils.indexOf(waiting, event[1]) or #waiting == 0 or event[1] == 'terminate')) then
		_private._runningPID = PID
		windowHandler.redirect(PID)
		
		--resume the thread and get its yeild
		local data = _private.resume(currentProc.co, event)

		--windowHandler.setCurrentWindow(PID)
		
		if  _private._processes[PID] then
			_private._waitingFor[PID] = data 
		end
		
		if coroutine.status(currentProc.co) == 'dead'  and _private._processes[PID] then --handle death
			_private.killProcessInternal(PID)
		end
	end
end

---Pushes an event to all processes.
--If the event is in @{focusEvents} only push it to the focused process.
--The event is pushed one by one to each process using @{_private.pushEvent}.
--@param event The event to push to all processes.
--@usage _private.tick({"mouse_click", 1, 3, 4})
--@local
function _private.tick(event)
	--a list of all PIDs in use
	local processes = {}
	local isFocusEvent = tableUtils.indexOf(focusEvents, event[1])
	
	--fil ptocesses table
	for PID, _ in pairs(_private._processes) do
		processes[#processes + 1] = PID
	end
	
	--loop through all processes
	for _, PID in pairs(processes) do
		--if the process has never been ran before give it its inital event
		if not  _private._waitingFor[PID] then
			_private.pushEvent(PID, {})
		end
	end
	
	--if its a focus event then push it to the focused process
	if isFocusEvent then
		if _private._processes[_private._focus] then
			_private.pushEvent(_private._focus, event)
		end
		
	--otherwise push it to all processes
	else
		for _, PID in pairs(processes) do
			if _private._processes[PID] then
				_private.pushEvent(PID, event)
			end
		end
	end

	--redirect window back to the focued process
	windowHandler.redirect(_private._focus)
	
	--restore the cursor
	if term.current().restoreCursor then
		 term.current().restoreCursor()
	end
end

---Resumes a coroutine, passing an event to it.
--@param co A coroutine.
--@param data The data to pass.
--@return the data return fron the coroutine with the success value removed.
--@usage data = _private.resume(co, data)
function _private.resume(co, data)	
	data = { coroutine.resume(co, unpack(data)) }
	local success = table.remove(data, 1)
	return data
end

---Sets the visability of the top bar.
--@param visable The visablility of the top bar.
--@usage kernel.setBarVisable(true)
function setBarVisable(visable)
	windowHandler.setHidden(not visable)
end

function getBarVisable()
	return not windowHandler.getHidden()
end
---Kill the currently running process.
--@usage kernel.die()
function die()
	_private.killProcessInternal(_private._runningPID)
end

---Gets the total amout of alive processes.
--@return The total amout of alive processes.
--@usage local count = kernel.getProcessCount()
function getProcessCount()
	local count

	for _ in pairs(_private._processes) do
		count = count + 1
	end

	return count
end

---Gets a specified process.
--Only a copy of the process is returned, not the table itself.
--The fields of the process returned are:
--	<ul>
--		<li>package</li>
--		<li>desc</li>
--		<li>SU</li>
--		<li>children</li>
--		<li>PID</li>
--		<li>name   </li>
--	</ul>
--@param PID The PID of the process.
--@raise bad argument error - if an argument is mismatched or missing.
--@return The copy of the process.
--@usage local proc = kernel.getProcess(4)
function getProcess(PID)
	errorUtils.expect(PID, 'number', true, 2)
	
	local proc = _private._processes[PID]
	local stripedProc = {}
	
	if not proc then return end
	
	stripedProc.PID = proc.PID
	stripedProc.name = proc.name
	stripedProc.SU = proc.SU
	stripedProc.desc = proc.desc
	stripedProc.programStack = prog.programStack
	stripedProc.parent = proc.parent
	stripedProc.children = tableUtils.deepCopy(proc.children)
	
	return stripedProc
end

---Gets a list of all processes.
--Iterates through all process using @{getProcess}[PID] and adds it to a table.
--@return A table of all processes.
--@usage local processes == kernel.getProcesses()
function getProcesses()
	local procs = {}
	
	for k, _ in pairs(_private._processes) do
		procs[#procs + 1] = getProcess(k)
	end
	
	return procs
end

---Gets the currently running process.
--@return The currently running process.
--@usage local running = kernel.getRunning()
function getRunning()
	return _private._runningPID
end

function getRunningProgram()
	local stack = _private._processes[_private._runningPID].programStack
	return stack[#stack]
end

function getDataPath()
	local path = getRunningProgram()

	if fs.combine(fs.getDir(path), "") == fs.combine(_private.packagePath, "") then
		return fs.combine(_private.dataPath, fs.getName(path))
	end
end

---Change the superuser value for the running process
--@return true if SU was edited
--@usage kernel.setSU()
function setSU(su)
	local ps = _private._processes[_private._runningPID].programStack
	local running = ps[#ps]

	if kernel.isSU() or _G.fs.getPerm(running) == 4 then
		_private._processes[_private._runningPID].SU = (su and true or false)
		return true
	end
	
	return false
end

---Returns whether the currently running process has superuser permissions.
--If the kernel is not running then return true no matter what.
--@return true if currently running process has superuser permissions, false otherwise.
--@usage local SU = kernel.isSU()
function isSU()
	if not _running then return true end --if the kernel is not in use give root
	return _private._processes[_private._runningPID].SU
end

---Changes the currently focused process to a given process.
--A yield is forced so that the focus changes straight away.
--@param PID The PID of the process to switch to.
--@usage kernel.gotoPID(4)
function gotoPID(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], format(PIDError, PID), 2)

	if not _running then
		return
	end
	
	local old = _private._focus
	
	log.i("Going to PID " .. PID .. " from " .. tostring(old))

	if PID == old then
		return
	end
	--if the PID is already in the history remove it
	local index = tableUtils.indexOf(_private._runningHistory, PID)
	
	if index then
		table.remove(_private._runningHistory, index)
	end
	
	--appent the runningHistory with the PID
	_private._runningHistory[#_private._runningHistory + 1] = PID
	
	--set the focus to the PID
	_private._focus = PID
	
	--tell windowHandler we've switched winows
	windowHandler.gotoWindow(old, PID)
	
	---@warning When this function is called mid thread a goto event is pushed globally.
	--This is not intentional and may be changed.
	os.queueEvent("goto")
	coroutine.yield("goto")
end

---Gets all children of a process including itself.
--@param PID the PID of the process you want the children of.
--@return A list of all children of the given process.
--@raise bad argument error - if an argument is mismatched or missing. invalid PID error - if PID does not exist.
--@usage local children = kernel.getAllChildren(3)
function getAllChildren(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], format(PIDError, PID), 2)
	
	local allChildren = {PID}
	local i = 1
			
	while allChildren[i] do
		for _, v in pairs(_private._processes[allChildren[i]].children) do
			allChildren[#allChildren + 1] = v
		end
		
		i = i + 1
	end
	
	return allChildren
end

---Kills a specified Process.
--The proces may only kill another if it has superuser permissions or it attempts to kill itself.
--@param PID the PID of the process to be killed
--@raise bad argument error - if an argument is mismatched or missing. invalid PID error - if PID does not exist. permissions error - if the process lacks permission to kill the process.
--@usage kernel.killProcess(1)
function killProcess(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assertLog(isSU() or _private._runningPID == PID, "Process with PID " .. (_private._focus or "") .. " tried to kill process", 2, nil, "Warning")
	errorUtils.assert(_private._processes[PID], format(PIDError, PID), 2)
	
	_private.killProcessInternal(PID)
end

---Sets the name of a process.
--If the process if not the one currently running and you are not super user
--then the name will not change.
--@param PID The PID of the process to change.
--@param title What to change the name to.
--@return true if the name eas changed, false otherwise.
--@usage kernel.setTitle(1, "my program")
function setTitle(PID, title)
	if isSU() or PID == _private._runningPID then
		_private._processes[PID].name = tostring(title)
		windowHandler.updateBanner()
		return true
	end

	return false
end

---Starts the main process loop.
--The initially focused process is given as an argument.
--This function can only be called once to ensure a process
--can not call it again possible breaking the kernel.
--This function uses @{_private.tick} and @{_private.getEvent} to get and push events.
--If the main loop is ever to stop the computer will shutdown.
--@param PID the PID of the process to be initally focused.
--@raise bad argument error - if an argument is mismatched or missing. invalid PID error - if PID does not exist. kernel already running error - if the kernel is already running.
--@usage kernel.startProcesses(1)
function startProcesses(PID)
	errorUtils.expect(PID, 'number', true, 2)
	errorUtils.assert(_private._processes[PID], format(PIDError, PID), 2)
	errorUtils.assert(not _running, "kernel already running", 2)
	
	--kernel is now running
	_running = true
	
	--goto the starting process
	gotoPID(PID)
	
	--initalize the window handler
	windowHandler.init()
	
	local data = {} --the events we are listening for
	
	--if we run our of processes stop the loop and shutdown
	while _private._focus do
		_private.tick(data)
		data = _private.getEvent()
	end
	
	--set _rinning to false to we're guaranteed superuser permissions
	_running = false
	
	--shutdown so that the user does not gain control of the computer, bypassing security
	os.shutdown()
end



--setup debug function if debug mode is enabled.
if lunaOS.isDebug() then
	debug = {}

	function debug.getPrivate()
		return _private
	end

	function debug.real_G()
		return _G
	end
	
	function debug.real_ENV()
		return _ENV
	end

    function debug.crash()
        _private = nil
    end

	debug.explode = debug.crash
end
