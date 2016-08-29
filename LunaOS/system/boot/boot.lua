local oldPullEvent = os.pullEvent
os.pullEvent = coroutine.yield

term.setBackgroundColor(128)
term.clear()

local numToHex = {"1", "2", "3", "4", "5", "6", "7", "b", "9", "a", "b", "c", "d", "e", "f"}
numToHex[0] = "0"
numToHex[255] = "-"

local xSize, ySize = term.getSize()
local filesToLoad = 14
local loaded = 0
local imagePath = "LunaOS/system/boot/boot.img"
local image
local sleepTime = 0

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
	
	term.setCursorPos(1 + math.floor(xSize/2 - width/2), 11)
	term.blit(text, textColour, backgroundColour)
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


	log.i("------- Finished loading APIs -------")
end

function decodeImage(image)
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

function decodeFile(path)
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
		
		term.setCursorPos(1 + math.floor(xSize/2 - image.size[1]/2), 1 + math.floor(ySize/2 - image.size[2]/2) + y)
		term.blit(text, textColour, pixel)
	end
end

image = decodeFile(imagePath)

drawImage()
loadAPIs()

function gui(a)
	default = GUI.Theme()
	
	f = GUI.Frame()

	f:applyTheme(default)
	
	function setText(lbl, a,b,c,d,e)
		a = a or ""
		b = b or ""
		c = c or ""
		d = d or ""
		e = e or ""
		f = f or ""
		
		lbl.text = a..' '..b..' '..c..' '..d..' '..e .. "\n".. (tostring(f.focus) or "")
	end
	
	eventListner = GUI.Label(1,1,30,2,"events")
	eventListner:applyTheme(default)
	eventListner.backgroundColour = colourUtils.blits.green
	eventListner:addEventListener("", setText)
	eventListner:addEventListener("terminate", function() f:stop() end)
	ls = GUI.Label(2,1,1,12,"123456789abc")
	
	v2 = GUI.View(2, 2, 49, 17) --1.1
	v = GUI.ScrollView(1, 1, 51, 18, 70, 80)
	v3 = GUI.View(28, 3, 6, 16)
	
	v2:addComponent(ls)
	ls:applyTheme(default)
	f:addComponent(eventListner)
	--f:addComponent(v2)
	f:addComponent(v)
	
	
	--v3 = GUI.View(2,2,20,20)
	--v2:addComponent(v3)
	--v3.backgroundColour = "-1"
	
	

	v:applyTheme(default)
	v2:applyTheme(default)
	v3:applyTheme(default)
	v2.backgroundColour = "4"
	--v2:addComponent(v)
	vl = GUI.Button(2,10,5,1,"test")
	vl:applyTheme(default)
	v:addComponent(vl)
	
		v.backgroundColour = "0"
		
	oldf = f
	f = v
	
	sw1 = GUI.Switch(3,2,2,2)
	sw1:transform(-1,-1)
	sw2 = GUI.Switch(3,8,2,2)
	sw3 = GUI.Switch(3,11,2,2)
	sw4 = GUI.RadioButton(3,14)
	pb= GUI.ProgressBar(3,17,40,1,"this is progress")
	pb.maxProgress = 20

	
	l1 = GUI.Label(10, 8, 10 , 4)
	tb = GUI.ToggleButton(3,5,5,2)
	
	sw1:applyTheme(default)
	sw2:applyTheme(default)
	sw3:applyTheme(default)
	sw4:applyTheme(default)
	
	tb:applyTheme(default)
	l1:applyTheme(default)
	
	pb:applyTheme(default)
	
	sbh= GUI.HorizontalScrollbar(25, 14, 14, 1, 8)
	sb2= GUI.Scrollbar(23, 2, 1, 14, 8)

	
	
	

	
	
	
	
	sbh:applyTheme(default)
	sb2:applyTheme(default)
	
	
	
	
	counter = 0
	
	b = GUI.Button(10,2,10,4,"this is a test")
	
	
	function b:onClick() counter = counter + 1  self.text = "i have been pressed " .. counter   .. " times"  pb.progress = counter end
	
	
	
	b:applyTheme(default)
	
	tf1 = GUI.TextField(28,2,20)
	tf2 = GUI.TextField(28,4,20)
	tf1:applyTheme(default)
	tf2:applyTheme(default)
	tf1.mask = ""
	tf1.hint = "Username:"
	
	f:addComponent(sw1)
	f:addComponent(sw2)
	f:addComponent(sw3)
	f:addComponent(sw4)
	f:addComponent(b)
	f:addComponent(tb)
	f:addComponent(tf1)
	f:addComponent(tf2)
	f:addComponent(l1)
	f:addComponent(sbh)
	f:addComponent(sb2)
	
	
	
	
	
	f:addComponent(pb)
	

	tg2 = GUI.ToggleButton(2,2,4,3)
	tg2:applyTheme(default)
	
	
	
	
	
	

	group = GUI.Group(false, false)
	
	group:addComponent(sw1)
	group:addComponent(sw2)
	group:addComponent(sw3)
	group:addComponent(sw4)
	group:addComponent(tb)
	
	function group:onChange()
		local s
		local selected = group:getSelected()[1]
		
		if selected == sw1 then
			s = "switch one"
		elseif selected == sw2 then
			s = "switch two"
		elseif selected == sw3 then
			s = "switch three"
		elseif selected == sw4 then
			s = "switch four"
		elseif selected == tb then
			s = "the toggle button"
		else
			s = "nothing"
		end
			
		l1:setText(s .. " is selected")
	end
	
	f = oldf
	
	b6 = GUI.TextField(4,4,15,"test")
	--b6 = GUI.Button(4,4,15,3,"test")
	b6:applyTheme(default)
	v3:addComponent(b6)
	
	local open = 1
	v2:addComponent(b6)
	
	--mv = GUI.TabbedView(2,2,20,16)
	--mv:addView(v, "1")
	--mv:addView(v2, "2")
	--mv:addView(v3, "3")
	--f:addComponent(mv)
	--f:addComponent(v2)
	--mv:gotoView("1")
	
	function n()
		mv:gotoView(tostring(open))
		open = open + 1
	end
	
	--mv:addEventListener("key", n)
	
	
	if a then f:mainLoop() else dofile("rom/programs/lua") end
		
end

local pid = kernel.runRootProgram("LunaOS")
kernel.runRootFile("rom/programs/lua")
kernel.runRootFile("rom/programs/shell")
kernel.newProcess(function() gui(true) end , nil, "GUI")
kernel.newProcess(function() gui()  end , nil, "GUI Shell")


os.pullEvent = oldPullEvent

local a,b =pcall(kernel.startProcesses, pid)--]]
print(a,b)
sleep(5)