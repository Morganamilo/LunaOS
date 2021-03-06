local objectPath = '/LunaOS/system/GUI/objects'
local interfacePath = '/LunaOS/system/GUI/interfaces'
local toLoad = {}

_G.GUI={}

local function loadObject(file, dir)
	local parts = textUtils.split(file, ".")
	local child, parent, extension
	
	if #parts == 2 then
		child = parts[1]
		extension = "." .. parts[2]
	elseif #parts == 3 then
		child = parts[2]
		parent = parts[1]
		extension = "." .. parts[3]
	end
	
	if GUI[child] then return true end
	
	if (GUI[parent] or not parent) then 
		GUI[child] = os.loadClass(fs.combine(dir, file))
		return true
	end
	
	return false
end

local function loadDir(dir)
	repeat
		local allLoaded = true
		
		for _, file in pairs(fs.list(dir)) do
			if not fs.isDir(file) then
				local l = loadObject(file, dir) 
				allLoaded = l and allLoaded
			end
		end
	until allLoaded
end

loadDir(interfacePath)
loadDir(objectPath)
