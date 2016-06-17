local GUIPath = '/LunaOS/system/GUI/objects'
local toLoad = {}

local function loadObject(file)
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
		GUI[child] = os.loadClass(fs.combine(GUIPath, file))
		return true
	end
	
	return false
end

function init()
	repeat
		local allLoaded = true
		
		for _, file in pairs(fs.listFiles(GUIPath)) do
			local l = loadObject(file) 
			allLoaded = l and allLoaded
		end
	until allLoaded
end
