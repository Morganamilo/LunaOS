View = object.class(GUI.Component)

function View:init(xPos, yPos, xSize, ySize, backgroundColour)
	local x, y = term.getSize()
	local xCursor, yCursor = term.getCursorPos()
	self.xPos = xPos or 1
	self.yPos = yPos or 1
	self.xSize = xSize or x
 	self.ySize = ySize or y
	self.backgroundColour = backgroundColour or "0"
	
	
	self.window = window.create(term.native(), self.xPos, self.yPos, self.xSize, self.ySize, true)
	term.setCursorPos(xCursor, yCursor)
	
	self.buffer = GUI.Buffer(self.window, 1, 1, self.xSize, self.ySize, self.backgroundColour)
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

function View:draw(window)
	self.buffer:clear(self.backgroundColour)
	
	for _, component in pairs(self.components) do
		component:onDraw(self.buffer)
	end
	
	self.xCursor, self.yCursor = term.getCursorPos()
	self.buffer:draw(ignoreChanged)
	term.setCursorPos(self.xCursor, self.yCursor)
end

function View:setPos(xPos, yPos)
	self.xPos = xPos
	self.yPos = yPos
	
	self.window.reposition(xPos, yPos)
end

function View:setSize(xSize, ySize)
	self.xSize = xSize
	self.ySize = ySize
	
	self.buffer:resize(xSize, ySize, "0")
	self.window.reposition(self.xPos, self.yPos, xPos, yPos)
end

function View:handleEvent()
	local event = {coroutine.yield()}
	
	--ajust the position of mouse events
	if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
	
		if event[3] < self.xPos or event[3] > self.xPos + self.xSize - 1 or event[3] < self.yPos or event[4] > self.yPos + self.ySize - 1 then
			return
		end
		
		event[3] = event[3] - self.xPos + 1
		event[4] = event[4] - self.yPos + 1
	end	
	
	for _, component in pairs(self.components) do
		component:handleEvent(event)
	end
end
