local fs = fs
local serverIsReachable
local configPath = "/LunaOS/data/system/config/log.cfg"

local config = {
	enabled = true,
	logPath = "/LunaOS/data/system/LunaOS.log",
	clearAtBoot = "true",
	serverPath = "http://lunadb.ddns.net",
	enabled = true,
	useServer = false,
}

local function initFile()
	local file = fs.open(config.logPath, "w")
	file.write("--- LunaOS Log ---\n")
	file.close()
end

local function writeToDB()
	if not config.useServer then return end
	local sql = "p=LunaOS&sql=INSERT%20INTO%20Logs%20(Time,Type,message)%20VALUES%20"
	local file = fs.open(congig.logPath,"r")
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
	
	http.post("http://lunadb.ddns.net/", sql)
	
end

log = {
	log = function(message, flag)
		if not config.enabled then return end
		if type(message) ~= "string" then error("String expected got " .. type(message)) end
		if type(flag) ~= "string" then error("String expected got " .. type(flag)) end
		
		flag = flag:gsub("%]","}"):gsub("%[","{")
		
		if not fs.exists(config.logPath) then
			initFile()
		end
	
		local file = fs.open(config.logPath, "a")
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
	s = function(message) log(message, "Severe") end,
	d = function(message) if lunaOS.isDebug() then log(message, "debug") end end
}

setmetatable(log, {__call = function(t, message, flag) log.log(message, flag) end})
 
function log.init()
	if not fs.exists(configPath) then
		local data = jsonUtils.encode(config, true)

		local file = fs.open(configPath, "w")
		file.write(data)
		file.close()
	end

	config = jsonUtils.decodeFile(configPath)
	serverIsReachable = http.timedRequest(config.serverPath, 2) ~= nil
	
	if serverIsReachable then writeToDB() end
	if clearAtBoot then initFile() end
	
	log("---------- Booting ----------","Boot")
end
