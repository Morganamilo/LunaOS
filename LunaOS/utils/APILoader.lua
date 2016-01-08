function loadDir(path)
	for _, file in pairs(fs.list(path)) do
		load(path)
	end
end

function loadList(path)
	local file = fs.open(path, 'r')
	local currentLine
	
	while true do
		currentLine = file.readLine()
		if currentLine == nil then break end
		
		if fs.exists(currentLine) then 
			if fs.isDir(currentLine) then loadDir(currentLine)
			else load(currentLine) end
		end
	end
end

function load(path, displaySuccess)
	if os.loadAPI(path) then
		local name = fs.getName(path)
		local newName = name:gmatch("([^.]+)")()
		
		if name ~= newName[1] then
			_G[newName] = _G[name]
			_G[name] = nil
			
			if displaySuccess then print("Loaded " .. name .. " as " .. newName) end
		else
			if displaySuccess then print("Loaded " .. name) end
		end
	else
		error("Error: failed to load " .. name)
	end
end