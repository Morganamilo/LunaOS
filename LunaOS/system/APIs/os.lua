local isLoading = {}
local toInit = {}
local oldGetfenv = getfenv



local function loadAPIInternal(path, locally, req)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	
	local name = fs.getName(path):gmatch("([^.]+)")():gsub(" ", "_") --replace spaces with underscores and truncate after the first .
        
	if isLoading[path] then
			return false
	end
	
	isLoading[path] = true
	log.i("Loading API " .. path)
	
	local env = setmetatable({}, {__index = getfenv(), __metatable = ""})
	
	--compile error
	local APIFunc, err = loadfile(path)
	
	if APIFunc then
		setfenv(APIFunc, env)
		
		--runtime error
		local status, err2 = pcall(APIFunc)
		if not status then
			error("Error loading " .. path .. ": " .. err2, 2)
			log.e("Error loading " .. path .. ": " .. err2, 2)
		end
	else
		error("Error loading " .. path .. ": " .. err, 2)
		log.e("Error loading " .. path .. ": " .. err, 2)
		return false, err
	end
	
	local APITable = {}
	for k, v in pairs(env) do
			APITable[k] =  v
	end
	
	if req then
		for k, v in pairs(APITable) do
			_G[k] = v
		end
	elseif not locally then
		_G[name] = APITable
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