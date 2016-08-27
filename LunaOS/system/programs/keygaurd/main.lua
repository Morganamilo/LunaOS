local dataPath = kernel.getCurrentDataPath()
local default = GUI.Theme()
local frame = GUI.Frame(term.current())
local passwordField = GUI.TextField()
local image = GUI.Image()
local label = GUI.Label()
local infoLabel = GUI.Label(1,1, frame.xSize, 1, "LunaOS: v" .. lunaOS.getProp("version"))

local function getSalt()
	local file = fs.open(fs.combine(dataPath, "salt"), "r")
	local data = file.readAll()
	file.close()
	
	return data
end

local function getPassword()
	local file = fs.open(fs.combine(dataPath, "hash"), "r")
	local data = file.readAll()
	file.close()
	
	return data
end

local function isPassword(password)
	local salt = getSalt()
	local hashedPassword = getPassword()
	local hash = sha256.hash(salt .. password)
	
	return hash == hashedPassword
end

local function tryPassword(self)
	local correct = isPassword(passwordField.text)
	
	if correct then
		kernel.killProcess(kernel.getRunning())
	else
		label.textColour = colourUtils.blits.red
		label.text = "Password Is Incorrect"
		passwordField:setText("")
	end
end

passwordField:applyTheme(default)
frame:applyTheme(default)
label:applyTheme(default)
infoLabel:applyTheme(default)

label:setSize(32, 1)
label:setPos(math.floor(frame.xSize/2 - label.width/2), 9)
label.backgroundColour = nil 
label:setText("Please Login")
label:setAlignment("center", "top")
label.textColour = colourUtils.blits.lightGrey

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
frame:addComponent(label)
frame:addComponent(infoLabel)

passwordField:requestFocus()

if #getPassword() == 0 then
	kernel.killProcess(kernel.getRunning())
end

frame:mainLoop()