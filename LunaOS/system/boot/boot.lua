term.clear()
term.setCursorPos(1,1)
dofile("/LunaOS/system/APIs/log.lua") -- load this first so we always have acess to log
dofile("/LunaOS/system/apis/override.lua")
os.loadAPI("LunaOS/system/object/object.lua")
os.loadAPI("/LunaOS/system/APIs/LunaOS.lua")
os.loadAPIDir("LunaOS/system/utils/") -- everything in utils must be safe to be called by non root processes
os.loadAPI("/LunaOS/system/APIs/time.lua")
os.loadAPI("/LunaOS/system/kernel/kernel.lua")
os.loadAPI("/LunaOS/system/APIs/fs.lua")
log.i("------- Finished loading APIs -------")

term.setTextColor(2048)
print("lunaOS Version " .. LunaOS.getVersion())
term.setTextColor(1)


function f1() 
	--_G.a = 55
	--print(_G.a)
	--print(_ENV.a)
	--print(a)
	--p = kernel.newProcess(f2)
	--kernel.gotoPID(p)
	--kernel.runProgram('lunashell', true)
	dofile("rom/programs/shell")
	--[[print(1)
	_G.a = 66
	print(_G.a)
	print(_ENV.a)
	print(a)
	print = nil
	print(5)
	kernel.gotoPID(2)
	print(1)
	print(_G.a)
	print(a)]]
	
end

function f2()
	print(_G.a)
	print(_ENV.a)
	print(a)
	dofile("rom/programs/shell")
	--[[
	print(_G.a)
	print(_ENV.a)
	print(a)
	kernel.gotoPID(1)
	print(2)
	_G.os.shutdown()
	print("zzzz")
	print("zzzz")
	print("zzzz")
	print("zzzz")
	print("zzzz")]]
	
	
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