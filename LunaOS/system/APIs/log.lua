local clearAtBoot = true

local function initFile()
	local file = fs.open("/LunaOS/system/LunaOS.log", "w")
	file.write("--- LunaOS Log ---\n")
	file.close()
end

log = {
	log = function(message, flag)
		if not type(message) == String then error("Error: string expected got " .. type(message)) end
		if not type(flag) == String then error("Error: string expected got " .. type(flag)) end
	
		if not fs.exists("/LunaOS/system/LunaOS.log") or fs.isDir("/LunaOS/system/LunaOS.log") then
			initFile()
		end
	
		local file = fs.open("/LunaOS/system/LunaOS.log", "a")
		if file then
			if time and time.isRealTime then
				file.write(time.timef("[%Y-%m-%d %H:%M:%S, ") .. flag .. "] ".. message .. "\n")
			else
				file.write("[" .. os.clock() .. " " .. flag .. "] ".. message .. "\n")
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
if clearAtBoot then initFile() end

setmetatable(log, {__call = function(t, message, flag) log.log(message, flag) end})
log("---------- Booting ----------","Boot")