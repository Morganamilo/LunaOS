local success = kernel.setSU(true)

if not success then
	error("Can not get SuperUser", 0)
end

local default = GUI.Theme()
local frame = GUI.Frame(term.current())
local button = GUI.Button(3,3,5,3,"test")
button:applyTheme(default)


frame:applyTheme(default)
frame:addComponent(button)

lunaOS.lock()


kernel.setFullscreen(false)
frame:draw()

kernel.newRootProcess("/LunaOS/system/bin/lua")
kernel.newRootProcess("/LunaOS/system/bin/lua")
kernel.newProcess("rom/programs/shell")
kernel.newProcess("/LunaOS/system/bin/shell")

frame:mainLoop()
