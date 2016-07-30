View = object.class(GUI.Shape)

function View:init(xPos, yPos, width, height)
	local x, y = term.getSize()
	
	self.xPos = xPos or 1
	self.yPos = yPos or 1
	self.width = width or x
 	self.height = height or y

	self:addEventListener("", self.handleAny)
	
	self.buffer = GUI.Buffer(term.current(), self.xPos, self.yPos, self.width, self.height)
	self.components = {}
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
	self.oldSetCursorPos = term.setCursorPos
	self.oldGetCursorPos = term.getCursorPos
	self.oldSetCursorBlink = term.setCursorBlink
	
	term.setCursorPos = self.ajustedSetCursorPos
	term.getCursorPos = self.ajustedGetCursorPos
	term.setCursorBlink = self.ajustedSetCursorBlink
	
	self:clear()  --      mathUtils.time(function() f:draw() end, 60)
		
	for _, component in pairs(self.components) do
		component:onDraw(self.buffer)
	end
		
	term.setCursorPos = self.oldSetCursorPos
	term.getCursorPos = self.oldGetCursorPos
	term.setCursorBlink = self.oldSetCursorBlink
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
	
	local oldSetCursorPos = term.setCursorPos
	local oldGetCursorPos = term.getCursorPos
	
	local xAjust = -self.xPos + 1
	local yAjust = -self.yPos + 1
	
	
	
	if not force then
		if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
			--if the event is out of the range of the view then dont process any further
			if not self:isInBounds(event[3], event[4]) then
				return 
			end
		end
	end
	
	event = self:ajustEvent(event, xAjust, yAjust)
	
	term.setCursorPos = function(xPos, yPos)
		xPos = xPos + xAjust
		yPos = yPos + yAjust
		
		if self:isInBounds(xPos, yPos) then
			oldSetCursorPos(xPos, yPos)
		else
			cancelBlink = true
		end
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

function View:setAjustFunctions()
	self.ajustedSetCursorPos = function(xPos, yPos)
		local xAjust, yAjust = self:getAjust()
		
		xPos = xPos + xAjust
		yPos = yPos + yAjust
		
		self.oldSetCursorPos(xPos, yPos)
		
		if not self:isInBounds(xPos, yPos) then
			term.setCursorBlink(false)
		end
	end
	
	self.ajustedGetCursorPos = function()
		local x, y = self.oldGetCursorPos()
		local xAjust, yAjust = self:getAjust()
		
		return x - xAjust, y - yAjust
	end
	
	self.ajustedSetCursorBlink = function(blink)
		if not blink then
			self.oldSetCursorBlink(false)
		else
			local x, y = self.oldGetCursorPos()
			
			if self:isInBounds(x, y) then
				self.oldSetCursorBlink(true)
			end
		end
	end
end