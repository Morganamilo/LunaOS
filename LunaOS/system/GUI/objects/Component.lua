Component = object.class()
Component:implement(GUI.Drawable, GUI.EventHandler)

Component.listeners = {} --a table of events that the Component is listening for
Component.active = true
Component.visible = true

function Component:handleEvent(data)
	if not (self.active and self.visible ) then return end
	
	local listenerFunc = self.listeners[data[1]] --set listenerFunc to the function who key is the event name
	if listenerFunc then listenerFunc(self, unpack(data)) end --if we did get a function from that event name call it
	
	listenerFunc = self.listeners[""]  --special listener that is called for any event
	if listenerFunc then listenerFunc(self, unpack(data)) end
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

function Component:getFrame()
		return self:getParentPane():getFrame()
end

function Component:getParentPane()
	return self.parentPane
end

function Component:setCursorPos(xPos, yPos)
	if self:getParentPane() then
		return self:getParentPane():setCursorPos(xPos, yPos)
	end
end

function Component:getCursorPos()
	if self:getParentPane() then
		return self:getParentPane():getCursorPos()
	end
end

function Component:setCursorBlink(blink)
	if self:getParentPane() then
		return self:getParentPane():setCursorBlink(blink)
	end
end

function Component:isInBounds()
	return false
end

function Component:setParentPane(pane)	
	self.parentPane = pane
end

function Component:getAbsolutePos()
	local xPos, yPos = self:getParentPane():getAbsolutePos()
	return xPos + self.xPos - 1, yPos + self.yPos - 1 
end

function Component:requestFocus()
	self:getFrame():setFocus(self)
end

function Component:unFocus()
	if self:isFocus() then
		self:getFrame():unFocus()
	end
end

function Component:isFocus()
	return self:getFrame():getFocus() == self
end