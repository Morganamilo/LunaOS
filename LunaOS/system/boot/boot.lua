--must load the APILoader before we can load other APIs
os.loadAPI('/LunaOS/system/utils/APILoader.lua')
_G['APILoader.lua'].loadList('/LunaOS/system/boot/APIs', true)




function f1() 
term.setCursorBlink(true)
	for n = 1, 10 do
	d, a = coroutine.yield("char", "mouse_click")
	print(a)
	end
	
end

function f2() 
	d = {"notning yet"}
	for n = 1, 10 do
		print("i am 2")
		--for n = 1, 10000 do print(n) end
		d = {coroutine.yield()} -- coroutine is spelt wrong so it will error here
	end
end


kernel.newProcess( f1 )
kernel.newProcess( f2, 1 )
kernel.newProcess( f2, 2 )
kernel.newProcess( f2, 3 )
kernel.newProcess( f2, 3 )
kernel.newProcess( f2, 3 )

--kernel.gotoPID(1)
--kernel.newProcess( function() for n = 1, 10 do print('i am 1  '..n) coroutine.yield() if n == 3 then print("n is 3 i shall be back") coroutine.yield('tevent') print("i am back") end end end, 1 )
--kernel.newProcess( function() for n = 1, 10 do print('i am 2  '..n) coroutine.yield() if n == 7 then print"n is 7 sending signal to 1"  kernel.queEventNow('tevent') end end end, 1 )


kernel.startProcesses()

-- os.loadAPI("/p")
-- p.waitForAll(function() print('here i go') while true do print('weeee')  end end,
				-- function() print('here i go2') while true do print('weeee2')  end end)