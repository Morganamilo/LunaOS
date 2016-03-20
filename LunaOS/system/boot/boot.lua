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
	dofile("rom/programs/lua")
end

function f2()
	dofile("rom/programs/lua")
end


pid = kernel.runRootFile("rom/programs/lua")
kernel.runFile("rom/programs/lua")
kernel.runFile("rom/programs/shell")


--kernel.gotoPID(1)
term.clear()
kernel.startProcesses(pid)