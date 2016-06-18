Component = object.class()
Component:implement(GUI.Drawable, GUI.EventHandler)

Component.listeners = {} --a table of events that the Component is listening for
Component.active = true
Component.visible = true

function Component:handleEvent(data)
	--if not self.active then return end
	
	local listenerFunc = self.listeners[data[1]] --set listenerFunc to the function who key is the event name
	if listenerFunc then listenerFunc(unpack(data)) end --of we did get a function from that event name call it
end

function Component:addEventListener(event, func)
	self.listeners[event] = func
end

function Component:removeEventListener(event)
	self.listeners[event] = nil
end

function Component:onDraw(buffer)
	if self.visible then
		self:draw(buffer)
	end
end

function Component:draw()

end

function Component:requestFocus()
	os.queueEvent("focus", self)
end