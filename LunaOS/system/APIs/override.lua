--firstly gets loaded into the global enviroment
--then gets reloaded in to each process enviroment

local isLoading = {}
local toInit = {}
local oldfs = fs
local oldGetfenv = getfenv
local _has8BitCharacters = settings ~= nil

--[[function getfenv(level)
	local env = oldGetfenv(level)
	if env == _G then
		error("invalid level")
	end
	
	return 
end]]

--os.pullEvent = coroutine.yield


local function loadAPIInternal(path, locally, req)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 3) end
	
	local name = fs.getName(path):gmatch("([^.]+)")():gsub(" ", "_") --replace spaces with underscores and truncate after the first .
        
	if isLoading[path] then
			return false
	end
	
	isLoading[path] = true
	log.i("Loading API " .. path)
	
	local env = setmetatable({}, {__index = getfenv(), __metatable = ""})
	local APIFunc, err = loadfile(path)
	
	if APIFunc then
		setfenv(APIFunc, env)
		
		local status, err2 = pcall(APIFunc)
		if not status then
			error("Error loading " .. path .. ": " .. err2)
			log.e("Error loading " .. path .. ": " .. err2)
		end
		
	else
			error("Error loading " .. path .. ": " .. err)
			log.e("Error loading " .. path .. ": " .. err)
			return false, err
	end
	
	local APITable = {}
	for k, v in pairs(env) do
			APITable[k] =  v
	end
	
	if not locally then
		if req then
			for k, v in pairs(APITable) do
				_G[k] = v
			end
		else
			_G[name] = APITable
		end
	end
	
	isLoading[path] = nil
	if not locally then toInit[#toInit + 1] = name end
	log.i("Succsess: loaded " .. path .. " as " .. name)
	
	return locally and APITable or true
end

function os.loadAPI(path)
	return loadAPIInternal(path, false, false)
end

function os.loadAPILocal(path)
	return loadAPIInternal(path, true, false)
end

function os.require(path)
	return loadAPIInternal(path, false, true)
end

function os.loadClass(path)
	local name = fs.getName(path):gmatch("([^.]+)%.-[^.]-$")():gsub(" ", "_")
	return loadAPIInternal(path, true, false)[name]
end

function os.unloadAPI(name)
	if name ~= "_G" and type(_G[name] == "table") then
		_G[name] = nil
	end
end

function os.loadAPIList(path)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end

	local file = fs.open(path, 'r')
	if file then
		local currentLine
		
		while true do
			currentLine = file.readLine()
			if currentLine == nil then break end
			
			if fs.exists(currentLine) then 
				if fs.isDir(currentLine) then
					os.loadAPIDir(currentLine)
				else 
					os.loadAPI(currentLine)
				end
			end
		end
	
	file.close()
	end
end

function os.loadAPIDir(path)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	if not fs.isDir(path) then error("Error: " .. path .. " is not a directory", 2) end
	
	for _, file in pairs(fs.list(path)) do
		if not fs.isDir(file) then
			os.loadAPI(fs.combine(path, file))
		end
	end
end

function os.initAPIs()
	for _,v in pairs(toInit) do
		if _G[v].init then 
			local succsess, res =	pcall(_G[v].init)
			errorUtils.assert(succsess, res, 0)
		end
		
		_G[v].init = nil
	end
end

local oldSetComputerLabel = os.setComputerLabel
function os.setComputerLabel(label)
	errorUtils.expect(label, string, false, 2)
	errorUtils.assert(kernel.isSU(), "")
	
	oldSetComputerLabel(label)
end

local oldShutdown = os.shutdown
function os.shutdown()
	if kernel.isSU() then oldShutdown()
	else kernel.killProcess(kernel.getRunning()) end
end

local oldReboot = os.reboot
function os.reboot()
	if kernel.isSU() then oldReboot()
	else kernel.killProcess(kernel.getRunning()) end
end

function http.timedRequest(url, timeout, post, headers)
	local timeRequest = http.request(url, post, headers)
	local timer = os.startTimer(timeout)
	local event, url, data
		
	while true do
		local event, _url, data = coroutine.yield()
	
		if event == "http_success" and url == _url then
			os.cancelTimer(timer)
			return data
		elseif event == "timer" and _url == timer then
			return nil, "Timed out"
		elseif event == "http_failure" then
			os.cancelTimer(timer)
			return nil, data
		end
	end
	
end

function term.has8BitCharacters()
	--anything >= 192 errors
	return _has8BitCharacters
end

if not _has8BitCharacters then
	local oldTermWrite = term.write
	function term.write(str)
		for n = 1, #str do
			local b = string.byte(str, n)
			
			if n >= 192 then
				str =str:gsub(n, "?")
			end
		end
		
		oldTermWrite(str)
	end

	local oldTermBlit = term.blit
	function term.blit(str, textColour, backgroundColour)
		for n = 1, #str do
			local b = string.byte(str, n)
			
			if n >= 192 then
				str =str:gsub(n, "?")
			end
		end
		
		oldTermBlit(str, textColour, backgroundColour)
	end
end


