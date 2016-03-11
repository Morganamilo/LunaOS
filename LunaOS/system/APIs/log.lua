local clearAtBoot = true
local serverIsReachable = http.get('http://lunadb.ddns.net/') ~= nil

local function initFile()
	local file = fs.open("/LunaOS/system/LunaOS.log", "w")
	file.write("--- LunaOS Log ---\n")
	file.close()
end

local function writeToDB()
	local sql = "p=LunaOS&sql=INSERT%20INTO%20Logs%20(Time,Type,message)%20VALUES%20"
	local file = fs.open("/LunaOS/system/LunaOS.log","r")
	if not file then return end
	
	file.readLine() -- skip the first line
	
	while true do
		local line = file.readLine()
		if not line then break end
		
		local time = line:gmatch('%[.-,')():sub(2,-2)
		local type = line:gmatch('(,.-)%]')():sub(3)
		local message = line:gmatch('%].*')():sub(3)
		--sql = sql .. "('0','a','m'),"
		sql = sql .. "('" .. textutils.urlEncode(time:gsub("\\","\\\\"):gsub("'","\\'")) .. "','" .. 
			textutils.urlEncode(type:gsub("\\","\\\\"):gsub("'","\\'")) .. "','" .. 
			textutils.urlEncode(message:gsub("\\","\\\\"):gsub("'","\\'")) .. "'),"
	end
	
	sql = sql:sub(1,-2)
	if not http.post("http://lunadb.ddns.net/", sql) then print("db") end
	
end

log = {
	log = function(message, flag)
		if type(message) ~= "string" then error("Error: string expected got " .. type(message)) end
		if type(flag) ~= "string" then error("Error: string expected got " .. type(flag)) end
		
		flag = flag:gsub("%]","}"):gsub("%[","{")
	
		if not fs.exists("/LunaOS/system/LunaOS.log") or fs.isDir("/LunaOS/system/LunaOS.log") then
			initFile()
		end
	
		local file = fs.open("/LunaOS/system/LunaOS.log", "a")
		if file then
			if time and time.isRealTime then
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

if serverIsReachable then writeToDB() end
if clearAtBoot then initFile() end

setmetatable(log, {__call = function(t, message, flag) log.log(message, flag) end})
log("---------- Booting ----------","Boot")