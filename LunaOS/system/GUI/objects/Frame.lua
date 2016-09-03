Frame = object.class()

Frame.running = false
Frame.components = {}
Frame.blink = false
Frame.cursorXPos = nil
Frame.cursorYPos = nil

function Frame:init(window)
	self.window = window or term.current()
	
	local x, y = self.window.getSize()
	
	self.xPos = 1
	self.yPos = 1
	self.xSize = x
 	self.ySize = y
	self.backgroundColour =  "0"
	
	self.buffer = GUI.Buffer(self.window, self.xPos, self.yPos, self.xSize, self.ySize, self.backgroundColour)
end

function Frame:getFrame()
	return self
end

function Frame:addComponent(component)
	errorUtils.assert(component:instanceOf(GUI.Drawable), "Error: Component must implement the Viewable interface")
	errorUtils.assert(component:instanceOf(GUI.EventHandler), "Error: Component must implement the EventHandler interface")
	table.insert(self.components, component)
	
	
	component:setParentPane(self)
end

function Frame:removeComponent(component)
	if component then
		local index = tableUtils.indexOf(self.components, component)
		
		if index then
			self.components[index] = nils
			table.remove(self.components, index)
		end
	end
end

function Frame:stop()
	self.running = false
end

function Frame:mainLoop()
	self.running = true
	
	while self.running do
		self:draw()
		local event = {coroutine.yield()}
		self:handleEvent(event)
	end
end

function Frame:handleEvent(event)
	for _, component in pairs(self.components) do
		component:handleEvent(event)
	end
end

function Frame:drawInternal()
	self.buffer:clear(self.backgroundColour)
	
	for _, component in pairs(self.components) do
		component:onDraw(self.buffer)
	end
end

function Frame:draw()
	term.setCursorBlink(false)
	self:drawInternal()
	self.buffer:draw()
	
	if self.cursorXPos and self.cursorYPos then
		term.setCursorBlink(self.blink)
		term.setCursorPos(self.cursorXPos, self.cursorYPos)
	end
end

function Frame:applyTheme(theme)
	self.backgroundColour = theme.frameBackgroundColour
end

function Frame:setFocus(component)
	if  self.focus and component ~= self.focus then
		self.focus:unFocus()
	end
	
	self.focus = component
end

function Frame:setCursorPos(xPos, yPos)
	self.cursorXPos = xPos
	self.cursorYPos = yPos
end

function Frame:setCursorBlink(blink)
	self.blink = blink
end

function Frame:unFocus()
	self.focus = nil
end

function Frame:getFocus()
	return self.focus
end

function Frame:getAbsolutePos()
	return 1, 1
end