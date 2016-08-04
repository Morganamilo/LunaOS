Switch = object.class(GUI.ToggleButton)

Switch.activateOnRelease = false 

function Switch:init(xPos, yPos)
	self.super:init(xPos, yPos, 2, 1)
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

function Switch:applyTheme(theme)
	self.defaultColour = theme.switchDefaultColour
	self.onColour = theme.switchOnColour
	self.offColour = theme.switchOffColour
end