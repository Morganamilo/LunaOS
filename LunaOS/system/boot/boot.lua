dofile("/LunaOS/system/APIs/override.lua")
dofile("/LunaOS/system/APIs/log.lua")
dofile("/LunaOS/system/APIs/multishell.lua")

os.loadAPIDir("LunaOS/system/utils/")

log.init()
log.init = nil
os.initAPIs()

log.i("------- Finished loading utils -------")

os.loadAPI("/LunaOS/system/APIs/lunaOS.lua")
os.loadAPI("/LunaOS/system/APIs/time.lua")
os.loadAPI("LunaOS/system/object/object.lua")
os.loadAPI("/LunaOS/system/kernel/kernel.lua")


os.loadAPI("/LunaOS/system/APIs/fs.lua")
os.initAPIs()


log.i("------- Finished loading APIs -------")

kernel.setWindowHandler(os.loadAPI("/LunaOS/system/kernel/windowHandler.lua", true))

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


local pid = kernel.runRootFile("rom/programs/shell")

kernel.runRootFile("rom/programs/lua")
kernel.runFile("rom/programs/lua")
kernel.runFile("rom/programs/shell")
kernel.runProgram("EventPrinter")
kernel.newProcess(f1, nil, "a")
kernel.newProcess(f1, nil, "b")
kernel.runProgram("LunaShell", 2)
kernel.runProgram("LunaShell", 2)



--kernel.gotoPID(1)
term.clear()
a,b =pcall(kernel.startProcesses,pid)