Frame = object.class()

Frame.running = false

function Frame:init(window)
	self.window = window or term.current()
	
	local x, y = self.window.getSize()
	
	self.xPos = 1
	self.yPos = 1
	self.xSize = x
 	self.ySize = y
	self.backgroundColour =  "0"
	
	
	--self.window = window.create(term.native(), self.xPos, self.yPos, self.xSize, self.ySize, true)
	--term.setCursorPos(xCursor, yCursor)
	
	self.buffer = GUI.Buffer(self.window, self.xPos, self.yPos, self.xSize, self.ySize, self.backgroundColour)
	self.components = {}
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
	table.remove(self.components, tableUtils.indexOf(self.components, component))
	component.parentPane = nil
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
	
	for _, component in pairs(self.components) do -- f = GUI.Frame()
		component:onDraw(self.buffer)
	end
end

function Frame:draw()
	self:drawInternal()
	self.xCursor, self.yCursor = term.getCursorPos()
	self.buffer:draw()
	term.setCursorPos(self.xCursor, self.yCursor)
end

function Frame:applyTheme(theme)
	self.backgroundColour = theme.frameBackgroundColour
end

function Frame:setFocus(component)
	self.focus = component
end

function Frame:getFocus()
	return self.focus
end
