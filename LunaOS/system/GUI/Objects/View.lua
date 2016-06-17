View = object.class()

function View:init(backgroundColour)
	local x, y = term.getSize()
	
	self.open = true
	self.backgroundColour = backgroundColour
	self.buffer = GUI.Buffer(term, 1,1, x, y, backgroundColour)
	self.components = {}
end

function View:addComponent(component)
	table.insert(self.components, component)
	
	component.setFocus = function(component) self.focus = component end
	component.isFocus = function(component) return self.focus == component end
end

function View:removeComponent(component)
	table.remove(self.components, tableUtils.isIn(self.components, component))
end

function View:draw(ignoreChanged)

	self.buffer:clear(self.backgroundColour)
	
	for _, component in pairs(self.components) do
		component:onDraw(self.buffer)
	end
	
	self.buffer:draw(ignoreChanged)
end

function View:close()
	self.open = false
end

function View:mainLoop()
	while self.open do
		for _, component in pairs(self.components) do
			self:draw()
			local event = {coroutine.yield()}	
			component:handleEvent(event)
		end
	end
end