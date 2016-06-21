Button = object.class(GUI.Label)

Button.activateOnRelease = true --should the button react as soon as it is clicked or when it is released
Button.held = false

function Button:init(xPos, yPos, width, height, text)
	self.super:init(xPos, yPos, width, height, text)
	
	self:addEventListener("mouse_click", self. eventHandler)
	self:addEventListener("mouse_up",  self.eventHandler)
	self:addEventListener("mouse_drag", self.eventHandler)
end

function Button:eventHandler(event, mouseButton, xPos, yPos)
	if event == "mouse_click" then
		self:handleDown(xPos, yPos, mouseButton)
	elseif event == "mouse_up" then
		self:handleUp(xPos, yPos, mouseButton)
	elseif event == "mouse_drag" then
		self:handleDrag(xPos, yPos, mouseButton)
	end
end

function Button:isInBounds(xPos, yPos)
	return xPos >= self.xPos and xPos <= self.xPos + self.width - 1 and
	yPos >= self.yPos and yPos <= self.yPos + self.height - 1
end

function Button:handleDown(xPos, yPos, mouse)
	if self:isInBounds(xPos, yPos) then
		self.held = true
		
		if not self.activateOnRelease then
			self:onClick()
		end
	end
end

function Button:handleUp(xPos, yPos, mouse)
	if self:isInBounds(xPos, yPos) and self.held and self.activateOnRelease then
		self:onClick()
	end
	
	self.held = false
end

function Button:handleDrag(xPos, yPos, mouse)

end

function Button:onClick()
	--empty function so there is no error thrown when a button is pressed and there is no onClick function set 
end

function Button:draw(buffer)
	local backColour = self.held and self.heldBackgroundColour or self.backgroundColour
	local textColour = self.held and self.heldTextColour or self.textColour
	
	local x, y, width, height = self:getTextPos()
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour) 
	end
	
	buffer:writeTextBox(x, y, width, height, self.text, textColour, nil, self.xAlignment, self.yAlignment)
end

function Button:applyTheme(theme)
	self.super:applyTheme(theme)
	
	self.heldBackgroundColour = theme.heldBackgroundColour
	self.heldTextColour = theme.heldTextColour	
end