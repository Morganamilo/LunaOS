Button = object.class(GUI.Label)

Button.activateOnRelease = true --should the button react as soon as it is clicked or when it is released
Button.held = false

function Button:init(xPos, yPos, width, height, text)
	self.super:init(xPos, yPos, width, height, text)
	
	self:addEventListener("mouse_click", self. handleDown)
	self:addEventListener("mouse_up",  self.handleUp)
end

function Button:handleDown(event, mouse, xPos, yPos)
	if self:isInBounds(xPos, yPos) then
		self.held = true
		
		if not self.activateOnRelease then
			self:onClick()
		end
	end
end

function Button:handleUp(event, mouse, xPos, yPos)
	if self:isInBounds(xPos, yPos) and self.held and self.activateOnRelease then
		self.held = false
		xPos = xPos - self.xPos + 1
		yPos = yPos - self.yPos + 1
		
		if mouse == 1 and self.onClick then
			self:onClick(event, mouse, xPos, yPos)
		end
		
		if mouse == 2 and self.onRightClick then
			self:onRightClick(event, mouse, xPos, yPos)
		end
	end
	
	self.held = false
end

function Button:handleDrag(event, mouse, xPos, yPos)

end

function Button:draw(buffer)
	local backColour = self.held and self.heldBackgroundColour or self.backgroundColour
	local textColour = self.held and self.heldTextColour or self.textColour
	
	local x, y, width, height = self:getTextPos()
	
	buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour)
	
	buffer:writeTextBox(x, y, width, height, self.text, textColour, nil, self.xAlignment, self.yAlignment)
end

function Button:applyTheme(theme)
	self.super:applyTheme(theme)
	
	self.heldBackgroundColour = theme.heldBackgroundColour
	self.heldTextColour = theme.heldTextColour	
end
