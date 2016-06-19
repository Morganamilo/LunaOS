RadioButton = object.class(GUI.ToggleButton)

--RadioButton.activateOnRelease = false 

function RadioButton:init(xPos, yPos, width, height)
	self.super:init(xPos, yPos, width or 1, height or 1)
	
	self:addEventListener("mouse_click", self. eventHandler)
	self:addEventListener("mouse_up",  self.eventHandler)
	self:addEventListener("mouse_drag", self.eventHandler)
end

function RadioButton:draw(buffer)
	local colour
	
	if self.selected then
		colour = self.selectedColour
	else
		colour = self.defaultColour
	end
	
	buffer:drawBox(self.xPos, self.yPos, self.width, self.height, colour)	
end

function RadioButton:applyTheme(theme)
	self.defaultColour = theme.radioButtonDefaultColour
	self.selectedColour = theme.radioButtonSelectedColour
end