View = object.class()

function View:init(backgroundColour)
	local x, y = term.getSize()
	self.xCursor, self.yCursor = term.getCursorPos()
	
	self.open = true
	self.backgroundColour = backgroundColour
	self.buffer = GUI.Buffer(term, 1,1, x, y, backgroundColour)
	self.components = {}
end

function View:addComponent(component)
	errorUtils.assert(component:instanceOf(GUI.Drawable), "Error: Component must implement the Viewable interface")
	errorUtils.assert(component:instanceOf(GUI.EventHandler), "Error: Component must implement the EventHandler interface")
	table.insert(self.components, component)
	
	component.setFocus = function(component) self.focus = component end
	component.isFocus = function(component) return self.focus == component end
end

function View:removeComponent(component)
	table.remove(self.components, tableUtils.indexOf(self.components, component))
end

function View:draw(ignoreChanged)

	self.buffer:clear(self.backgroundColour)
	
	for _, component in pairs(self.components) do
		component:onDraw(self.buffer)
	end
	
	self.xCursor, self.yCursor = term.getCursorPos()
	self.buffer:draw(ignoreChanged)
	term.setCursorPos(self.xCursor, self.yCursor)
end

function View:close()
	self.open = false
end

function View:mainLoop()
	self:draw()
	
	while self.open do	
		local event = {coroutine.yield()}	
		
		for _, component in pairs(self.components) do
			component:handleEvent(event)
		end
		
		self:draw()
	end
end