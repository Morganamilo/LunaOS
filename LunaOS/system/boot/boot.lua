local oldPullEvent = os.pullEvent
os.pullEvent = coroutine.yield

term.setBackgroundColor(128)
term.clear()

local numToHex = {"1", "2", "3", "4", "5", "6", "7", "b", "9", "a", "b", "c", "d", "e", "f"}
numToHex[0] = "0"
numToHex[16] = "-"

local xSize, ySize = term.getSize()
local filesToLoad = 15
local loaded = 0
local imagePath = "LunaOS/system/boot/boot.img"
local image
local sleepTime = 0
local image

local function drawBar(text, percent)
	local width = 31
	local percent = math.floor((percent * width) + 0.5)
	
	local freeRoom = width - #text
	local prePad = math.floor(freeRoom/2)
	local postPad = width - (#text + prePad)
	
	text = string.rep(" ", prePad ).. text .. string.rep(" ", postPad)
	text = text:sub(1,width)
	
	local textColour = string.rep("0", width)
	local backgroundColour = string.rep("9", percent) ..  string.rep("8", width - percent) 
	
	term.setCursorPos(1 + math.floor(xSize/2 - width/2), 13)
	term.blit(text, textColour, backgroundColour)
end

local function drawText()
	local text = "Booting LunaOS..."
	local textPos = 1 + math.floor(xSize/2 - #text/2)
	
	term.setCursorPos(textPos, 11)
	term.setTextColour(colours.lightGrey)
	term.setBackgroundColour(colours.grey)
	term.write(text)
end


local function newSleep(time)
	if time > 0 then
		sleep(time)
	end
end

local function newDofile(file)
	drawBar("Loading: " .. fs.getName(file), loaded/filesToLoad)
	loaded = loaded + 1
	dofile(file)
	newSleep(sleepTime)
end

local function newLoadAPI(file)
	drawBar("Loading: " .. fs.getName(file), loaded/filesToLoad)
	loaded = loaded + 1
	os.loadAPI(file)
	newSleep(sleepTime)
end

local function newLoadAPIDir(file)
	drawBar("Loading: " .. fs.getName(file), loaded/filesToLoad)
	loaded = loaded + 1
	os.loadAPIDir(file)
	newSleep(sleepTime)
end

local function loadAPIs()
	newDofile("/LunaOS/system/APIs/override.lua")
	newDofile("/LunaOS/system/APIs/log.lua")
	newDofile("/LunaOS/system/APIs/multishell.lua")
	newDofile("/LunaOS/system/APIs/os.lua")
	
	newLoadAPI("/LunaOS/system/APIs/object.lua")
	newLoadAPIDir("LunaOS/system/utils/")

	log.init()
	log.init = nil
	os.initAPIs()

	log.i("------- Finished loading utils -------")

	newLoadAPI("/LunaOS/system/GUI/GUI.lua")
	os.initAPIs()

	newLoadAPI("/LunaOS/system/APIs/lunaOS.lua")
	newLoadAPI("/LunaOS/system/APIs/password.lua")
	newLoadAPI("/LunaOS/system/APIs/packageHandler.lua")
	newLoadAPI("/LunaOS/system/APIs/time.lua")
	newLoadAPI("/LunaOS/system/APIs/sha256.lua")
	newLoadAPI("/LunaOS/system/APIs/keyHandler.lua")
	newLoadAPI("/LunaOS/system/kernel/kernel.lua")
	newLoadAPI("/LunaOS/system/APIs/fs.lua")
	os.initAPIs()

	drawBar("Done", 1)

	log.i("------- Finished loading APIs -------")
end

local function decodeImage(image)
	local decodeImage = {size = {}, text = {}, textColour = {}, colour = {}}
	
	decodeImage.size[1] = string.byte(image:sub(1,1)) 
	decodeImage.size[2] = string.byte(image:sub(2,2)) 
	
	for n = 3, #image, 3 do
		local text = image:sub(n,n)
		local textColour = string.byte(image, n + 1)
		local colour = string.byte(image, n + 2)
		local l = #decodeImage.text + 1
		
		decodeImage.text[l] = text
		decodeImage.textColour[l] = numToHex[textColour]
		decodeImage.colour[l] = numToHex[colour]
	end
	
	return decodeImage
end

local function decodeFile(path)
	local file = fs.open(path, "rb")
	local image = ""
	
	while true do
		local char = file.read()
		
		if not char then
			break
		end
		
		image = image .. string.char(char)
	end
	file.close()
	
	return decodeImage(image)
end

local function drawImage()
	yPos = 2

	for y = 1, image.size[2] do
		local pixel = ""
		local text = ""
		local textColour = ""
		
		for x = 1, image.size[1] do
			pixel = pixel .. image.colour[x + ((y - 1)* image.size[1])] or " "
			text = text .. image.text[x + ((y - 1)* image.size[1])] or "0"
			textColour = textColour .. image.textColour[x + ((y - 1)* image.size[1])] or "0"
		end
		
		term.setCursorPos(1 + math.floor(xSize/2 - image.size[1]/2), y + 6)
		term.blit(text, textColour, pixel)
	end
end

image = decodeFile(imagePath)

drawImage()
drawText()
loadAPIs()

dofile("/LunaOS/system/boot/shellInit.lua")

--local pid = kernel.newProcess("/LunaOS/system/packages/LunaOS.lua")
lunaOS.lock()


kernel.newRootProcess("/LunaOS/system/packages/LunaOS.lua")
kernel.newRootProcess("/LunaOS/system/bin/lua")
kernel.newRootProcess("/LunaOS/system/bin/lua")
kernel.newProcess("rom/programs/shell")
kernel.newProcess("/LunaOS/system/bin/shell")
--kernel.runProgram("GUITest", nil, false)
--kernel.runProgram("GUITest", nil, true)
--kernel.runProgram("Explorer")

t = function() print(mathUtils.time(function() f:draw(true) end, 60)) end
os.pullEvent = oldPullEvent
kernel.startProcesses(1)
