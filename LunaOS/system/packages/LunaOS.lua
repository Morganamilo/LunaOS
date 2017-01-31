local success = kernel.setSU(true)

if not success then
	error("Can not get SuperUser", 0)
end

local default = GUI.Theme()
local frame = GUI.Frame(term.current())

frame:applyTheme(default)

lunaOS.lock()
kernel.setBarVisable(true)

frame:mainLoop()
