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
--kernel.newProcess( function() for n = 1, 10 do print('i am 1  '..n) coroutine.yield() if n == 3 then print("n is 3 i shall be back") coroutine.yield('tevent') print("i am back") end end end, 1 )
--kernel.newProcess( function() for n = 1, 10 do print('i am 2  '..n) coroutine.yield() if n == 7 then print"n is 7 sending signal to 1"  kernel.queEventNow('tevent') end end end, 1 )


kernel.startProcesses(pid)