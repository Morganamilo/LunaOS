View = object.class(GUI.Component)

function View:init(xPos, yPos, xSize, ySize, backgroundColour)
	local x, y = term.getSize()
	local xCursor, yCursor = term.getCursorPos()
	
	self.xPos = xPos or 1
	self.yPos = yPos or 1
	self.xSize = xSize or x
 	self.ySize = ySize or y
	self.backgroundColour = backgroundColour or "0"
	
	self.visible = true
	
	--self.window = window.create(term.native(), self.xPos, self.yPos, self.xSize, self.ySize, true)
	term.setCursorPos(xCursor, yCursor)
	
	self.buffer = GUI.Buffer(term.current(), self.xPos, self.yPos, self.xSize, self.ySize, self.backgroundColour)
	self.components = {}
end

function View:addComponent(component)
	errorUtils.assert(component ~= self, "Error: View can not be added to itself")
	errorUtils.assert(component:instanceOf(GUI.Drawable), "Error: Component must implement the Viewable interface")
	errorUtils.assert(component:instanceOf(GUI.EventHandler), "Error: Component must implement the EventHandler interface")
	table.insert(self.components, component)
	
	component.parentPane = self
end

function View:removeComponent(component)
	table.remove(self.components, tableUtils.indexOf(self.components, component))
	component.parentPane = self
end

function View:drawInternal()
	local oldSetCursorPos = term.setCursorPos
	local oldGetCursorPos = term.getCursorPos
	
	local xAjust = self.xPos - 1
	local yAjust = self.yPos - 1
	
	self.buffer:clear(self.backgroundColour)
	
	term.setCursorPos = function(xPos, yPos)
		oldSetCursorPos(xPos + xAjust, yPos + yAjust)
	end
	
	term.getCursorPos = function()
		local x, y = oldGetCursorPos()
		return x - xAjust, y - yAjust
	end
	
	for _, component in pairs(self.components) do
		component:onDraw(self.buffer)
	end
	
	term.setCursorPos = oldSetCursorPos
	term.getCursorPos = oldGetCursorPos
	
	self.xCursor, self.yCursor = term.getCursorPos()
	
	term.setCursorPos(self.xCursor, self.yCursor)
end

function View:draw(buffer)
	self:drawInternal()
	buffer:drawBuffer(self.buffer)
end

function View:setPos(xPos, yPos)
	self.xPos = xPos
	self.yPos = yPos
	
	self.buffer.xPos = xPos
	self.buffer.yPos = yPos
	
	--self.window.reposition(xPos, yPos)
end

function View:setSize(xSize, ySize)
	self.xSize = xSize
	self.ySize = ySize
	
	self.buffer:resize(xSize, ySize, "0")
end

function View:ajustEvent(event, xAjust, yAjust)
	--ajust the position of mouse events and cursor positions	
	if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
		
		event[3] = event[3] + xAjust
		event[4] = event[4] + yAjust
	end
	
	return event
end

function View:handleEvent(event, force)
	local xAjust = -self.xPos + 1
	local yAjust = -self.yPos + 1
	
	if not force then
		if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
			--if the event is out of the range of the view then dont process any further
			if event[3] < self.xPos or event[3] > self.xPos + self.xSize - 1 or event[3] < self.yPos or event[4] > self.yPos + self.ySize - 1 then
				return 
			end
		end
	end
	
	event = self:ajustEvent(event, xAjust, yAjust)
	
	local oldSetCursorPos = term.setCursorPos
	local oldGetCursorPos = term.getCursorPos
	
	term.setCursorPos = function(xPos, yPos)
		oldSetCursorPos(xPos + xAjust, yPos + yAjust)
	end
	
	term.getCursorPos = function()
		local x, y = oldGetCursorPos()
		return x - xAjust, y - yAjust
	end
	
	for _, component in pairs(self.components) do
		component:handleEvent(event)
	end
	
	term.setCursorPos = oldSetCursorPos
	term.getCursorPos = oldGetCursorPos
end

function View:applyTheme(theme)
	self.backgroundColour = theme.viewBackgroundColour
end