kernel.requestSU()

local dataPath = kernel.getCurrentDataPath()
local default = GUI.Theme()
local frame = GUI.Frame(term.current())
local passwordField = GUI.TextField()
local image = GUI.Image()
local loginLabel = GUI.Label()
local infoLabel = GUI.Label()
local restart = GUI.Button()
local shutdown = GUI.Button()
local timeLabel = GUI.Label()

local function tryPassword(self)
	local correct = password.isPassword(passwordField.text)
	
	if correct then
		lunaOS.unlock()
		kernel.die()
	else
		loginLabel.textColour = colourUtils.blits.red
		loginLabel:setText("Incorrect Password")
		passwordField:clear()
	end
end

function initComponents()
	passwordField:applyTheme(default)
	frame:applyTheme(default)
	loginLabel:applyTheme(default)
	infoLabel:applyTheme(default)
	restart:applyTheme(default)
	shutdown:applyTheme(default)
	timeLabel:applyTheme(default)

	restart:setText("Restart")
	restart:setSize(#restart.text,1)
	restart:setPos(frame.width - restart.width + 1, frame.height - 1)
	restart.backgroundColour = nil
	restart.heldBackgroundColour = nil
	restart.textColour = colourUtils.blits.cyan
	restart.heldTextColour = colourUtils.blits.lightGrey
	restart.onClick = os.reboot

	shutdown:setText("Shutdown")
	shutdown:setSize(#shutdown.text,1)
	shutdown:setPos(frame.width - shutdown.width + 1, frame.height)
	shutdown.backgroundColour = nil
	shutdown.heldBackgroundColour = nil
	shutdown.textColour = colourUtils.blits.cyan
	shutdown.heldTextColour = colourUtils.blits.lightGrey
	shutdown.onClick = os.shutdown

	loginLabel:setSize(32, 1)
	loginLabel:setPos(1+ math.floor(frame.width/2 - loginLabel.width/2), 11)
	loginLabel.backgroundColour = nil
	loginLabel:setText("Please Login")
	loginLabel:setAlignment("center", "top")
	loginLabel.textColour = colourUtils.blits.lightGrey

	timeLabel:setSize(32, 2)
	timeLabel:setPos(1+ math.floor(frame.width/2 - timeLabel.width/2), 4)
	timeLabel.backgroundColour = nil
	timeLabel:setText(time.timef("%a %B %d  %I:%M %P"))
	timeLabel:setAlignment("center", "top")
	timeLabel.textColour = colourUtils.blits.lightGrey

	infoLabel:setSize(frame.width, 1)
	infoLabel:setPos(1,1)
	infoLabel:setText("LunaOS: v" .. lunaOS.getProp("version"))
	infoLabel.textColour = colourUtils.blits.grey
	infoLabel:setAlignment("center", "top")

	image:setImageFromFile(fs.combine(kernel.getCurrentPackagePath(), "logon.img"))
	image:setPos(1 + math.floor(frame.width/2 - image.width/2), 7)

	passwordField:setSize(32)
	passwordField:setPos(1 + math.floor(frame.width/2 - passwordField.width/2), 13)
	passwordField.hint = "Password:"
	passwordField.mask = "*"
	passwordField.onEnter = tryPassword

	frame:addComponent(image)
	frame:addComponent(passwordField)
	frame:addComponent(loginLabel)
	frame:addComponent(infoLabel)
	frame:addComponent(shutdown)
	frame:addComponent(restart)

	if time.isRealTime() then
		frame:addComponent(timeLabel)
	end
	
	passwordField:requestFocus()
end

initComponents()
frame:mainLoop()