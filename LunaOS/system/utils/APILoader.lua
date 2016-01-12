local function makeReadOnly(tbl)
	local tempTbl = {}
	local mt = {  
		__index = tbl,
		__newindex = function (t,k,v)
		error("Error: attempt to update a read-only table", 2)
		end
	}
	setmetatable(tempTbl, mt)
	return tempTbl
end

function loadDir(path, displaySuccess)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	if not fs.isDir(path) then error("Error: " .. path .. " is not a directory", 2) end
	
	for _, file in pairs(fs.list(path)) do
		if not fs.isDir(file) then
			load(fs.combine(path, file), displaySuccess)
		end
	end
end

function loadList(path, displaySuccess)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end

	local file, err = fs.open(path, 'r')
	if not file then error("Error: failed to open " .. path, 2) end

	local currentLine
	
	while true do
		currentLine = file.readLine()
		if currentLine == nil then break end
		
		if fs.exists(currentLine) then 
			if fs.isDir(currentLine) then loadDir(currentLine, displaySuccess)
			else load(currentLine, displaySuccess) end
		end
	end
	
	file.close()
end

function load(path, displaySuccess)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	if fs.getName(path):sub(1,1) == '.' then return end --ignore files starting with '.' 

	if os.loadAPI(path) then
		local name = fs.getName(path)
		local newName = name:gmatch("([^.]+)")():gsub(" ", "_")
		
		
		if name ~= newName[1] then
			_G[newName] = makeReadOnly(_G[name])
			_G[name] = nil
			
			if displaySuccess then print("Loaded " .. name .. " as " .. newName) end
		else
			if displaySuccess then print("Loaded " .. name) end
		end
	else
		error("Error: failed to load " .. path, 2)
	end
	
	os.sleep(.05)
end

function unload(API)
	os.unloadAPI(API)
end