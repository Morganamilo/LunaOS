local filesToLoad = {
	'LunaOS/kernel/kernel.lua',
	'LunaOS/utils/tableUtils.lua'
}

local function loadAPI(path)
	if os.loadAPI(path) then
		local name = fs.getName(path)
		local newName = name:gmatch("([^.]+)")()
		
		if name ~= newName[1] then
			_G[newName] = _G[name]
			_G[name] = nil
			
			print("Loaded " .. name .. " as " .. newName)
		else
			print("Loaded " .. name)
		end
	else
		error("Error: failed to load " .. name)
	end
	
	
end

for _, v in pairs(filesToLoad) do
	loadAPI(v)
end

kernel.newProcess( function() for n = 1, 10 do print('i am 0') coroutine.yield() end end)
kernel.newProcess( function() for n = 1, 10 do print('i am 1') coroutine.yield() end end )
kernel.startProcesses()