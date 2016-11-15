View = object.class(GUI.Shape)
View.components = {}
View.held = false

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
	errorUtils.assert(component ~= self, "View can not be added to itself")
	errorUtils.assert(component:instanceOf(GUI.Drawable), string.format(errorUtils.strings.mustImplement, "Drawable"))
	errorUtils.assert(component:instanceOf(GUI.EventHandler), string.format(errorUtils.strings.mustImplement, "EventHandler"))
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
	self.buffer:clear(self.backgroundColour)
	
	for _, component in pairs(self.components) do  
		component:onDraw(self.buffer)
	end
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

function View:pushEvent(event)
	for _, component in pairs(self.components) do
		component:handleEvent(event)
		
		if event[1] == "mouse_up" and component:isInBounds(event[3], event[4]) then
			self.held = false
		end
	end
end

function View:handleAny(...)
	local event = arg
	local inBounds 
	
	local xAjust, yAjust = self:getAjust()
	local hit = false
	
	if event[1] == "mouse_click"  then
		hit = true
	end
		
	if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
		inBounds = self:isInBounds(event[3], event[4])
		
		if not inBounds then
			event[3] = math.huge
			event[4] = math.huge
			hit  = false
			self.held = false
		end
	end
	
	event = self:ajustEvent(event, -xAjust, -yAjust)
	
	self:pushEvent(event)
	
	if event[1] == "mouse_up" and self.held then
		self.held = false
		event[3] = event[3] - self.xPos + 1
		event[4] = event[4]- self.yPos + 1
				
		if event[2] == 1 and self.onClick then
			self:onClick(event[1], event[2], event[3], event[4])
		end
		
		if event[2] == 2 and self.onRightClick then
			self:onRightClick(event[1], event[2], event[3], event[4])
		end
	end
	
	if hit then
		self.held = true
	end
end

function View:applyTheme(theme)
	self.backgroundColour = theme.viewBackgroundColour
end

function View:setCursorPos(xPos, yPos)
	local xAjust, yAjust = self:getAjust()
	
	xPos = xPos + xAjust
	yPos = yPos +yAjust
		
	if self:isInBounds(xPos, yPos) then
		self:getParentPane():setCursorPos(xPos, yPos)
	else
		self:getParentPane():setCursorPos(nil, nil)
	end
end

function View:setCursorBlink(blink)
	self:getParentPane():setCursorBlink(blink)
end

function View:getAbsolutePos()
	local xPos, yPos = self:getParentPane():getAbsolutePos()
	local xAjust, yAjust = self:getAjust()
	
	return xPos + xAjust, yPos + yAjust
end
