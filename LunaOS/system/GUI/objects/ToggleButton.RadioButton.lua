RadioButton = object.class(GUI.ToggleButton)

RadioButton.defaultColour = "7"
RadioButton.selectedColour = "5"

function RadioButton:init(xPos, yPos, width, height)
	self.super:init(xPos, yPos, width or 1, height or 1, nil, nil, nil)
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