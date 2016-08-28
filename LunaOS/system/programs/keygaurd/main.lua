kernel.requestSU()

local dataPath = kernel.getCurrentDataPath()
local default = GUI.Theme()
local frame = GUI.Frame(term.current())
local passwordField = GUI.TextField()
local image = GUI.Image()
local loginLabel = GUI.Label()
local infoLabel = GUI.Label(1,1, frame.xSize, 1, "LunaOS: v" .. lunaOS.getProp("version"))
local restart = GUI.Button()
local shutdown = GUI.Button()

local function tryPassword(self)
	local correct = password.isPassword(passwordField.text)
	
	if correct then
		lunaOS.unlock()
		kernel.die()
	else
		loginLabel.textColour = colourUtils.blits.red
		loginLabel.text = "Password Is Incorrect"
		passwordField:setText("")
	end
end

passwordField:applyTheme(default)
frame:applyTheme(default)
loginLabel:applyTheme(default)
infoLabel:applyTheme(default)
restart:applyTheme(default)
shutdown:applyTheme(default)

restart:setText("Restart")
restart:setSize(#restart.text,1)
restart:setPos(frame.xSize - restart.width + 1, frame.ySize - 1)
restart.backgroundColour = nil
restart.textColour = colourUtils.blits.cyan
restart.onClick = os.reboot

shutdown:setText("Shutdown")
shutdown:setSize(#shutdown.text,1)
shutdown:setPos(frame.xSize - shutdown.width + 1, frame.ySize)
shutdown.backgroundColour = nil
shutdown.textColour = colourUtils.blits.cyan
shutdown.onClick = os.shutdown5

loginLabel:setSize(32, 1)
loginLabel:setPos(math.floor(frame.xSize/2 - loginLabel.width/2), 9)
loginLabel.backgroundColour = nil
loginLabel:setText("Please Login")
loginLabel:setAlignment("center", "top")
loginLabel.textColour = colourUtils.blits.lightGrey

infoLabel.textColour = colourUtils.blits.grey
infoLabel:setAlignment("center", "top")

image:setImageFromFile(fs.combine(kernel.getCurrentPackagePath(), "logon.img"))
image:setPos(math.floor(frame.xSize/2 - image.width/2), 3)

passwordField:setSize(32)
passwordField:setPos(math.floor(frame.xSize/2 - passwordField.width/2), 11)
passwordField.hint = "Password:"
passwordField.mask = "*"
passwordField.onEnter = tryPassword

frame:addComponent(image)
frame:addComponent(passwordField)
frame:addComponent(loginLabel)
frame:addComponent(infoLabel)
frame:addComponent(shutdown)
frame:addComponent(restart)

passwordField:requestFocus()

frame:mainLoop()