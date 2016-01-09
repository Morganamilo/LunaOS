--must load the APILoader before we can load other APIs
os.loadAPI('/LunaOS/utils/APILoader.lua')
_G['APILoader.lua'].loadList('LunaOS/boot/APIs')

os.sleep(0) --this makes it work, i have no idea why

-- function f1() for n = 1, 10 do print('i am 0')
-- coroutine.yield() 
-- if n == 5 then kernel.newProcess( function() for n = 1, 10 do print('i am 5') end end, 1) end
-- end end


--kernel.newProcess( function() for n = 1, 10 do print('i am 1') coroutine.yield() end end, 1 )
kernel.newProcess( function() for n = 1, 10 do print('i am 1') 
for n = 1, 1000 do print('   1') end
coroutine.yield() end end, 1 )


--kernel.newProcess( function() for n = 1, 10 do print('i am 1  '..n) coroutine.yield() if n == 3 then print("n is 3 i shall be back") coroutine.yield('tevent') print("i am back") end end end, 1 )
--kernel.newProcess( function() for n = 1, 10 do print('i am 2  '..n) coroutine.yield() if n == 7 then print"n is 7 sending signal to 1"  kernel.queEventNow('tevent') end end end, 1 )


kernel.startProcesses()

-- os.loadAPI("/p")
-- p.waitForAll(function() print('here i go') while true do print('weeee')  end end,
				-- function() print('here i go2') while true do print('weeee2')  end end)