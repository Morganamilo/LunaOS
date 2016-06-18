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

function t()
		v = GUI.View(1)
		tb1 = GUI.ToggleButton(3,3,10,3,"this is a test for text alignment i hope it works very well", "3", "8") 
		tb1.selectedBackgroundColour = "2"
		
		tb2= GUI.ToggleButton(3,7,10,3,"this is a test for text alignment i hope it works very well", "3", "8") 
		tb2.selectedBackgroundColour = "2"
		
		tb3 = GUI.ToggleButton(3,11,10,3,"this is a test for text alignment i hope it works very well", "3", "8") 
		tb3.selectedBackgroundColour = "2"
		
		tb4 = GUI.ToggleButton(3,15,10,3,"this is a test for text alignment i hope it works very well", "3", "8") 
		tb4.selectedBackgroundColour = "2"
		
		v:addComponent(tb1) 
		v:addComponent(tb2) 
		v:addComponent(tb3) 
		v:addComponent(tb4) 
		
		print(tb1.yPos)
		print(v.components[1].yPos)
		print(v.components[1]:isInComponent(3,3))
		--sleep(1)
		
		--dofile("rom/programs/lua")
		
		group = GUI.Group(false, true)
		
		group:addComponent(tb1)
		group:addComponent(tb2)
		group:addComponent(tb3)
		group:addComponent(tb4)
		
		v:mainLoop()
end


local pid = kernel.runRootFile("rom/programs/shell")

kernel.runRootFile("rom/programs/lua")
kernel.newProcess(t , nil, "c")
kernel.runFile("rom/programs/shell")
kernel.runProgram("EventPrinter")
kernel.newProcess(f1, nil, "a")
kernel.newProcess(f1, nil, "b")
kernel.runProgram("LunaShell", 2)
kernel.runProgram("LunaShell", 2)



--kernel.gotoPID(1)
term.clear()
a,b =pcall(kernel.startProcesses,pid +1 )--]]