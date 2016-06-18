Switch = object.class(GUI.ToggleButton)

Switch.defaultColour = "7"
Switch.onColour = "5"
Switch.offColour = "e"

function Switch:init(xPos, yPos)
	self.super:init(xPos, yPos, 2, 1, nil, nil, nil)
end

function Switch:draw(buffer)
	local colour
	local pos
	
	if self.selected then
		colour = self.onColour
		pos = 0
	else
		colour = self.offColour
		pos = 1
	end
	
	buffer:drawBox(self.xPos, self.yPos, 2, 1, self.defaultColour)	
	buffer:drawBox(self.xPos + pos, self.yPos, 1, 1, colour)	
end