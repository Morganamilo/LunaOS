local success = kernel.setSU(true)

if not success then
	error("Can not get SuperUser", 0)
end

local default = GUI.Theme()
local frame = GUI.Frame(term.current())

frame:applyTheme(default)

lunaOS.lock()

kernel.newRootProcess("/LunaOS/system/bin/lua")
kernel.newRootProcess("/LunaOS/system/bin/lua")
kernel.newProcess("rom/programs/shell")
kernel.newProcess("/LunaOS/system/bin/shell")

frame:mainLoop()
