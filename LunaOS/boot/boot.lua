--must load the APILoader before we can load other APIs
os.loadAPI('LunaOS/utils/APILoader.lua')
_G['APILoader.lua'].loadList('LunaOS/boot/APIs')

function f1() for n = 1, 10 do print('i am 0')
coroutine.yield() 
if n == 5 then kernel.newProcess( function() for n = 1, 10 do print('i am 5') coroutine.yield() end end, 1) end
end end

kernel.newProcess(f1, 1)
kernel.newProcess( function() for n = 1, 10 do print('i am 1') coroutine.yield() end end, 1 )
kernel.startProcesses()