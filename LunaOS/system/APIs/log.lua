local clearAtBoot
local logPath
local serverPath
local useServer
local enabled
local serverIsReachable
local fs = fs

local function initFile()
	local file = fs.open(logPath, "w")
	file.write("--- LunaOS Log ---\n")
	file.close()
end

local function writeToDB()
	if not useServer then return end
	local sql = "p=LunaOS&sql=INSERT%20INTO%20Logs%20(Time,Type,message)%20VALUES%20"
	local file = fs.open(logPath,"r")
	if not file then return end
	
	file.readLine() -- skip the first line
	
	while true do
		local line = file.readLine()
		if not line then break end
		
		local time = line:gmatch('%[.-,')():sub(2,-2)
		local type = line:gmatch('(,.-)%]')():sub(3)
		local message = line:gmatch('%].*')():sub(3)
		
		sql = sql .. "('" .. textutils.urlEncode(time:gsub("\\","\\\\"):gsub("'","\\'")) .. "','" .. 
			textutils.urlEncode(type:gsub("\\","\\\\"):gsub("'","\\'")) .. "','" .. 
			textutils.urlEncode(message:gsub("\\","\\\\"):gsub("'","\\'")) .. "'),"
	end
	
	sql = sql:sub(1,-2)
	
end

log = {
	log = function(message, flag)
		if not (enabled and logPath) then return end
		if type(message) ~= "string" then error("Error: string expected got " .. type(message)) end
		if type(flag) ~= "string" then error("Error: string expected got " .. type(flag)) end
		
		flag = flag:gsub("%]","}"):gsub("%[","{")
		
		if not fs.exists(logPath) then
			initFile()
		end
	
		local file = fs.open(logPath, "a")
		if file then
			if time and time.isRealTime() then
				file.write(time.timef("[%Y-%m-%d %H:%M:%S, ") .. flag .. "] ".. message .. "\n")
			else
				file.write("[" .. os.clock() .. ", " .. flag .. "] ".. message .. "\n")
			end
			
			file.close()
		end
	end,

	i = function(message)  log(message, "Info") end,
	e = function(message) log(message, "Error") end,
	c = function(message) log(message, "Config") end,
	w = function(message) log(message, "Warning") end,
	s = function(message) log(message, "Severe") end
}

setmetatable(log, {__call = function(t, message, flag) log.log(message, flag) end})
 
function log.init()
	local config = jsonUtils.decodeFile("LunaOS/data/system/log.json")
	
	clearAtBoot = errorUtils.assert(config.clearAtBoot ~= nil, "Error: Missing config data: clearAtBoot")
	logPath = errorUtils.assert(config.logPath, "Error: Missing config data: logPath")
	serverPath = errorUtils.assert(config.serverPath, "Error: Missing config data: serverPath")
	
	errorUtils.assert(config.enabled ~= nil, "Error: Missing config data: enabled")
	errorUtils.assert(config.useServer ~= nil, "Error: Missing config data: useServer")
	enabled = config.enabled
	useServer = config.useServer
	
	serverIsReachable = http.timedRequest(serverPath, 2) ~= nil
	
	if serverIsReachable then writeToDB() end
	if clearAtBoot then initFile() end
	
	log("---------- Booting ----------","Boot")
end
