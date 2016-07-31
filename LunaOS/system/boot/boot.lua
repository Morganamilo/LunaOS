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
		
		lbl.text = a..' '..b..' '..c..' '..d..' '..e
	end
	
	eventListner = GUI.Label(1,1,30,1,"events")
	eventListner:applyTheme(default)
	eventListner.backgroundColour = colourUtils.blits.green
	eventListner:addEventListener("", setText)
	eventListner:addEventListener("terminate", function() f:stop() end)
	ls = GUI.Label(2,1,1,12,"123456789abc")
	
	v2 = GUI.ScrollView(2, 2, 49, 16, 100, 100) --1.1
	v = GUI.ScrollView(28, 6, 20, 8, 51, 18)
	--v = GUI.View(10, 3, 40, 10, "0")
	
	v2:addComponent(ls)
	ls:applyTheme(default)
	f:addComponent(eventListner)
	f:addComponent(v2)
	
	
	v3 = GUI.View(2,2,20,20)
	--v2:addComponent(v3)
	v3.backgroundColour = "-1"
	
	

	v:applyTheme(default)
	v2:applyTheme(default)
	v2.backgroundColour = "4"
	v2:addComponent(v)
	vl = GUI.Button(2,10,5,1,"test")
	vl:applyTheme(default)
	--v:addComponent(vl)
	
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
	tf1.mask = "brandon is a fag"
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