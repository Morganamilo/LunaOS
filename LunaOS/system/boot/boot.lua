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


term.clear()
term.setCursorPos(1,1)
term.setTextColor(2048)
print("lunaOS Version " .. lunaOS.getProp("version"))
term.setTextColor(1)


function f1() 
	kernel.gotoPID(2)
	dofile("rom/programs/lua")
end

function f2()
	dofile("rom/programs/lua")
end


pid = kernel.newRootProcess( f1, nil, "LunaShell" )
kernel.newProcess( f2 )


--kernel.gotoPID(1)
--kernel.newProcess( function() for n = 1, 10 do print('i am 1  '..n) coroutine.yield() if n == 3 then print("n is 3 i shall be back") coroutine.yield('tevent') print("i am back") end end end, 1 )
--kernel.newProcess( function() for n = 1, 10 do print('i am 2  '..n) coroutine.yield() if n == 7 then print"n is 7 sending signal to 1"  kernel.queEventNow('tevent') end end end, 1 )


kernel.startProcesses(pid)

-- os.loadAPI("/p")
-- p.waitForAll(function() print('here i go') while true do print('weeee')  end end,
				-- function() print('here i go2') while true do print('weeee2')  end end)
				--]]