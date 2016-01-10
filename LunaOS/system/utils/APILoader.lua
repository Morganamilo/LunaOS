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
	for _, file in pairs(fs.list(path)) do
		load(fs.combine(path, file), displaySuccess)
	end
end

function loadList(path, displaySuccess)
	local file, err = fs.open(path, 'r')
	if err then error(err, 2) end

	local currentLine
	
	while true do
		currentLine = file.readLine()
		if currentLine == nil then break end
		
		if fs.exists(currentLine) then 
			if fs.isDir(currentLine) then loadDir(currentLine, displaySuccess)
			else load(currentLine, displaySuccess) end
		end
	end
end

function load(path, displaySuccess)
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
end