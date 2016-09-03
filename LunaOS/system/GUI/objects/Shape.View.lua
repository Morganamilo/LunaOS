View = object.class(GUI.Shape)
View.components = {}

function View:init(xPos, yPos, width, height)
	self.super:init(xPos, yPos, width, height)

	local x, y = term.getSize()
	
	self.xPos = xPos or 1
	self.yPos = yPos or 1
	self.width = width or x
 	self.height = height or y
	
	self.buffer = GUI.Buffer(term.current(), self.xPos, self.yPos, self.width, self.height)
	
	self:addEventListener("", self.handleAny)
end

function View:makeBuffer()
	return GUI.Buffer(term.current(), self.xPos, self.yPos, self.width, self.height, "0")
end

function View:addComponent(component)
	errorUtils.assert(component ~= self, "Error: View can not be added to itself")
	errorUtils.assert(component:instanceOf(GUI.Drawable), "Error: Component must implement the Viewable interface")
	errorUtils.assert(component:instanceOf(GUI.EventHandler), "Error: Component must implement the EventHandler interface")
	table.insert(self.components, component)
	
	component:setParentPane(self)
end

function View:removeComponent(component)
	table.remove(self.components, tableUtils.indexOf(self.components, component))
	component.parentPane = self
end

function View:getAjust()
	return self.xPos  - 1, self.yPos - 1
end

function View:drawInternal()
	self:clear() 
	
	for _, component in pairs(self.components) do  
		component:onDraw(self.buffer)
	end
end

function View:clear()
	self.buffer:clear(self.backgroundColour)
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
end

function View:setSize(width, height)
	self.width = width
	self.height = height
	
	self.buffer:resize(width, height, "0")
end

function View:ajustEvent(event, xAjust, yAjust)
	--ajust the position of mouse events and cursor positions	
	if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
		
		event[3] = event[3] + xAjust
		event[4] = event[4] + yAjust
	end
	
	return event
end

function View:handleAny(...)
	self:handleAnyInternal(false, ...)
end

function View:handleAnyForce(...)
	self:handleAnyInternal(true, ...)
end

function View:handleAnyInternal(force, ...)
	local event = arg
	
	local xAjust, yAjust = self:getAjust()
		
	if not force then
		if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
			--if the event is out of the range of the view then dont process any further
			if not self:isInBounds(event[3], event[4]) then
				if event[1] == "mouse_up" then
					event[3] = 0
					event[4] = 0
				else
					return
				end
			end
		end
	end
	
	event = self:ajustEvent(event, -xAjust, -yAjust)
	
	
	for _, component in pairs(self.components) do
		component:handleEvent(event)
	end
end

function View:applyTheme(theme)
	self.backgroundColour = theme.viewBackgroundColour
end

function View:setCursorPos(xPos, yPos)
	xPos = xPos + self.xPos - 1
	yPos = yPos + self.yPos - 1
		
	if self:isInBounds(xPos, yPos) then
		self:getParentPane():setCursorPos(xPos, yPos)
	else
		self:getParentPane():setCursorPos(nil, nil)
	end
end

function View:getCursorPos()
	xPos = xPos - self.xPos + 1
	yPos = yPos - self.yPos + 1
	return self:getParentPane():getCursorPos()
end

function View:setCursorBlink(blink)
	self:getParentPane():setCursorBlink(blink)
end