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
	v = GUI.View(1)
	default = GUI.Theme()

	sw1 = GUI.Switch(3,2,2,2)
	sw2 = GUI.Switch(3,8,2,2)
	sw3 = GUI.Switch(3,11,2,2)
	sw4 = GUI.Switch(3,14,2,2)

	
	l = GUI.Label(10, 8, 10 , 4)
	tb = GUI.ToggleButton(3,5,5,2)
	
	sw1:applyTheme(default)
	sw2:applyTheme(default)
	sw3:applyTheme(default)
	sw4:applyTheme(default)
	
	tb:applyTheme(default)
	l:applyTheme(default)
	--cb = GUI.ComboBox(20,4,14,6, "8", "9")
	--sb = GUI.Scrollbar(cb)
	
	--sb:applyTheme(default)
	counter = 1
	
	b = GUI.Button(10,2,10,4,"this is a test")
	function b:onClick() self.text = "i have been pressed " .. counter   .. " times" counter = counter + 1 end
	b:applyTheme(default)
	
	tf = GUI.TextField(28,2,10,4)
	tf:applyTheme(default)
	
	v:addComponent(sw1)
	v:addComponent(sw2)
	v:addComponent(sw3)
	v:addComponent(sw4)
	v:addComponent(b)
	v:addComponent(tb)
	v:addComponent(tf)
	v:addComponent(l)
	
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
			
		l:setText(s .. " is selected")
	end
	
	if a then v:mainLoop() else dofile("rom/programs/lua") end
		
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