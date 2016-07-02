dofile("/LunaOS/system/APIs/override.lua")
dofile("/LunaOS/system/APIs/log.lua")
dofile("/LunaOS/system/APIs/multishell.lua")

os.loadAPI("/LunaOS/system/object/object.lua")

os.loadAPIDir("LunaOS/system/utils/")

log.init()
log.init = nil
os.initAPIs()

log.i("------- Finished loading utils -------")

os.loadAPI("/LunaOS/system/APIs/lunaOS.lua")
os.loadAPI("/LunaOS/system/APIs/time.lua")
os.loadAPI("/LunaOS/system/APIs/sha256.lua")
os.loadAPI("/LunaOS/system/kernel/kernel.lua")


os.loadAPI("/LunaOS/system/APIs/fs.lua")
os.loadAPI("/LunaOS/system/GUI/GUI.lua")
os.initAPIs()


log.i("------- Finished loading APIs -------")

kernel.setWindowHandler(os.loadAPILocal("/LunaOS/system/kernel/windowHandler.lua"))

function f1() 
_G.a=math.random(55)
	while true do 
	
	print(os.pullEvent())
	print(_G.a) end
end

function f2()
	while true do 
	print(os.pullEvent())
	print(a) end
end

function t(a)
	
	f = GUI.Frame(term.current())
	v = GUI.View()
	v2 = GUI.View(28, 6, 20, 10, "1")
	--v:setSize(5,5)
	v.backgroundColour = colourUtils.blits.grey
	default = GUI.Theme()

	sw1 = GUI.Switch(3,2,2,2)
	sw2 = GUI.Switch(3,8,2,2)
	sw3 = GUI.Switch(3,11,2,2)
	sw4 = GUI.RadioButton(3,14)
	pb= GUI.ProgressBar(3,17,40,1,"this is progress")
	pb.maxProgress = 20

	
	l1 = GUI.Label(10, 8, 10 , 4)
	--l2 = GUI.Button(30, 10, 10 , 4)
	tb = GUI.ToggleButton(3,5,5,2)
	
	sw1:applyTheme(default)
	sw2:applyTheme(default)
	sw3:applyTheme(default)
	sw4:applyTheme(default)
	
	tb:applyTheme(default)
	l1:applyTheme(default)
	--l2:applyTheme(default)
	pb:applyTheme(default)
	--cb = GUI.ComboBox(20,4,14,6, "8", "9")
	--sb = GUI.Scrollbar(cb)
	
	--l2.backgroundColour = "6"
	--function l2:onClick() self.backgroundColour = colourUtils.highlight(self.backgroundColour) end
	
	
	
	--sb:applyTheme(default)
	counter = 0
	
	b = GUI.Button(10,2,10,4,"this is a test")
	
	
	function b:onClick() counter = counter + 1  self.text = "i have been pressed " .. counter   .. " times"  pb.progress = counter end
	function b:onClick() v:setPos(5,5) end
	
	b:applyTheme(default)
	
	tf1 = GUI.TextField(28,2,20)
	tf2 = GUI.TextField(28,4,20)
	tf1:applyTheme(default)
	tf2:applyTheme(default)
	tf1.mask = "brandon is a fag"
	
	v:addComponent(sw1)
	v:addComponent(sw2)
	v:addComponent(sw3)
	v:addComponent(sw4)
	v:addComponent(b)
	v:addComponent(tb)
	v:addComponent(tf1)
	v:addComponent(tf2)
	v:addComponent(l1)
	--v:addComponent(l2)
	v:addComponent(pb)
	v:addComponent(v2)

	tg2 = GUI.ToggleButton(2,2,4,3)
	tg2:applyTheme(default)
	v2:addComponent(tg2)
	
	--v:addComponent(tb1) 
	--v:addComponent(tb2) 
	--v:addComponent(tb3) 
	--v:addComponent(tb4) GUI.Component.nonStatic.listeners

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
	
	f:addView(v,"1")
	f:gotoView("1")
	
	if a then f:mainLoop() else dofile("rom/programs/lua") end
		
end


local pid = kernel.runRootFile("rom/programs/shell")

kernel.runRootFile("rom/programs/lua")
kernel.newProcess(function() t(true) end , nil, "GUI")
kernel.newProcess(function() t()  end , nil, "GUI Shell")
kernel.runFile("rom/programs/shell")
kernel.runProgram("EventPrinter")
kernel.newProcess(f1, nil, "a")
kernel.newProcess(f1, nil, "b")
kernel.runProgram("LunaShell", 2)
kernel.runProgram("LunaShell", 2)



--kernel.gotoPID(1)
term.clear()
a,b =pcall(kernel.startProcesses,pid +1 )--]]