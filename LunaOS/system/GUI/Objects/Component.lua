Component = object.class()

Component.nonStatic.listeners = {}

function Component:handleEvent(data)
	local event = table.remove(data, 1)
	local listenerFunc = self.listeners[event]
	
	if listenerFunc then listenerFunc(unpack(data)) end
end

function Component:addEventListener(event, func)
	self.listeners[event] = func
end

function Component:removeEventListener(event)
	self.listeners[event] = nil
end

function Component:onDraw()

end

function Component:requestFocus()
	os.queueEvent("focus", self)
end