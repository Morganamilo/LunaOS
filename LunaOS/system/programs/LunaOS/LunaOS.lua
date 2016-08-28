local default = GUI.Theme()
local frame = GUI.Frame(term.current())

frame:applyTheme(default)

lunaOS.lock()
frame:mainLoop()
