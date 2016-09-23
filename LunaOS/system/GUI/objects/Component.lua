---Component is the base to all GUI components that can be added to a frame/view.
--It implements the drawable and eventHandler
--@author Morganamilo
--@copyright Morganamilo 2016
--@classmod Component

Component = object.class()
Component:implement(GUI.Drawable, GUI.EventHandler)

---The events that the Component is listening for.
--It hold the event name as its key and the function to be called when that event happens as its value.
Component.listeners = {}

---Whether the component is active. If a component is not active it can not recive events.
Component.active = true

---Whether the component can be seen. If a component is not visable it will not be drawn and can not recive events.
Component.visible = true

---Hanles an incoming event.
--Only handls the event if the component is both visable and active.
--It calls its lisreners and passes itself and the unpacked event through as an argument.
--@param data an event.
--@usage component:handleEvent(event)
function Component:handleEvent(data)
	if not (self.active and self.visible ) then return end
	
	--set listenerFunc to the function who's key is the event name
	local listenerFunc = self.listeners[data[1]]
	if listenerFunc then listenerFunc(self, unpack(data)) end --if we did get a function from that event name call it
	
	--special listener that is called for any event
	listenerFunc = self.listeners[""]
	if listenerFunc then listenerFunc(self, unpack(data)) end
end

---Adds an event listner to the listeners tables along with the function to call when the event happens.
--@param event The event to listen for.
--@param func The function to be called when the event fires.
--@usage component:addEventListener("key", function(event, key, held) print(key .. " is pressed"))
function Component:addEventListener(event, func)
	self.listeners[event] = func
end

---Removes an event from the listeners table.
--@param event The event to remove.
--@usage component:removeEventListener("key")
function Component:removeEventListener(event)
	self.listeners[event] = nil
end

---Calls the @{Component:draw} method but only if the component is visable.
--@param buffer The buffer passed to @{Component:draw}
--@usage component:onDraw(buffer)
function Component:onDraw(buffer)
	if self.visible then
		self:draw(buffer)
	end
end

---Draws the component to a buffer.
--This method is empty and is desinged to be overriden by subclasses.
--@usage component:draw(buffer)
function Component:draw(buffer)

end

---Gets the frame the component is placed on.
--Will fail if the comonent is not placed on a view/frame
--@usage local frame = component:getFrame()
function Component:getFrame()
		return self:getParentPane():getFrame()
end

---Gets the pane that the component is placed on.
--Will fail if the comonent is not placed on a view/frame
--@usage local parentPane = component:getParentPane()
function Component:getParentPane()
	return self.parentPane
end

---Sets the cursorPos of the frame
--@usage component:setCursorPos(3, 4)
function Component:setCursorPos(xPos, yPos)
	if self:getParentPane() then
		return self:getParentPane():setCursorPos(xPos, yPos)
	end
end

---Gets the cursorPos of the frame
--@return x and y coordinates of the parent pane.
--@usage local x, y = components:getCursorPos()
function Component:getCursorPos()
	if self:getParentPane() then
		return self:getParentPane():getCursorPos()
	end
end

---Sets the cursor blink of the frame.
--The cursor either blinks is either enabled or disabled there is no inbetween.
--@param blink true for the cursor to blink, false to make it not blink.
--@usage component:setCursorBlink(true)
function Component:setCursorBlink(blink)
	if self:getParentPane() then
		self:getParentPane():setCursorBlink(blink)
	end
end

---Gets whether an x and y coordinate is inside the bounds of the component.
--this method is empty and is designed to be overriden by subclasses.
--@param xPos The x position of the coordinate.
--@param yPos The y position of the coordinate.
--@return true if the xPos and yPos are inside the component.
--@usage local inBounds = component:isInBounds(5, 7)
function Component:isInBounds(xPos, yPos)
	return false
end

---Sets the parent pane of the component.
--The parent pane will usually be a frame/view.
--@param pane The pane to set as the components parent pane.
--@usage = component:setParentPane(frame)
function Component:setParentPane(pane)	
	self.parentPane = pane
end

---Sets the cursorColour of the frame.
--Will fail if the component is not placed on a pane.
--@param colour The colour to set the cursor
--@usage component:setCursorColour(colourUtils.blits.blue)
function Component:setCursorColour(colour)
	self:getFrame():setCursorColour(colour)
end

---Gets the absolute position of the component.
--Normaly the x and y position stored in a compoenent is relative to its pane.
--This method will always get the position relative to the frame insead of the parentPane.
--This method will fail if it is not placed on a pane.
--@return x coordinate relative to the frame, y coordinate relative to the frame
--@usage local xPos, yPos = component:getAbsolutePos()
function Component:getAbsolutePos()
	local xPos, yPos = self:getParentPane():getAbsolutePos()
	return xPos + self.xPos - 1, yPos + self.yPos - 1 
end


---Requests focus from the frame.
--This will cause every other component to lose focus.
--This method will fail if the component is not placed on a pane.
--@usage component:requestFocus()
function Component:requestFocus()
	self:getFrame():setFocus(self)
end

---Unfocuses the component.
--Will only unfocus itslef and do nothing if another component is focused.
--This method will fail if it is not placed on a pane.
--@usage component:unFocus()
function Component:unFocus()
	if self:isFocus() then
		self:getFrame():unFocus()
	end
end

---Gets whether or not the comonent is focued.
--@return true if the component is focued.
--@usage local isFocused = component:isFocus()
function Component:isFocus()
	return self:getFrame():getFocus() == self
end