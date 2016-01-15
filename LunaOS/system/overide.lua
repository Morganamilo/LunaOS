local isLoading = {}

--[[local oldError = error
function error(message, Level)
	log.e(message)
	oldError(message, level)
end--]]

log.i("Overiding default functions")

function os.loadAPI(path)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	local name = fs.getName(path):gmatch("([^.]+)")():gsub(" ", "_")
        
	if isLoading[path] == true then
			return false
	end
	
	isLoading[path] = true
	log.i("Loading API " .. path)
	
	local env = {}
		
	setmetatable(env, {__index = getfenv(), __metatable = ""})
	local APIFunc, err = loadfile(path)
	
	if APIFunc then
		setfenv(APIFunc, env)
		
		local status, err2 = pcall(APIFunc)
		if not status then
			log.e("Error loading " .. path .. ": " .. err2)
		end
		
	else
			log.e("Error loading " .. path .. ": " .. err)
			return false, err
	end
	
	local APITable = {}
	for k, v in pairs(env) do
			APITable[k] =  v
	end
	
	_G[name] = APITable
	
	isLoading[name] = nil
	log.i("Succsess: loaded " .. path .. " as " .. name)
	return true
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
					os.loadAPIDir(currentLine, displaySuccess)
				else 
					os.loadAPI(currentLine, displaySuccess)
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
			os.loadAPI(fs.combine(path, file), displaySuccess)
		end
	end
end

log.i("Succsess!")