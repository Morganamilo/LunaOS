dofile("/LunaOS/system/apis/override.lua")
dofile("/LunaOS/system/APIs/log.lua")

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

kernel.setWindowHandler(os.loadAPI("/lunaos/system/kernel/windowHandler.lua", true))

function f1() 
	dofile("rom/programs/lua")
end

function f2()
	dofile("rom/programs/lua")
end


pid = kernel.newRootProcess( f1, nil, "proc 1" )
kernel.newProcess( f2, nil, "proc 2" )


--kernel.gotoPID(1)
n = term.native()
kernel.startProcesses(pid)
	
	term.native()
	--term.redirect(n)
	term.setBackgroundColor(4)
	term.clear()
	term.write('bye')