ToggleButton = object.class(GUI.Button)
ToggleButton:implement(GUI.Selectable)

ToggleButton.selected = false
ToggleButton.changeColourOnHold = false

function ToggleButton:init(xPos, yPos, width, height, text)
	self.super:init(xPos, yPos, width, height, text)
end

function ToggleButton:toggleSelected()
	self.selected = not self.selected
end

function ToggleButton:onClick()
	self:toggleSelected()

	if self.selected then
		if self.onSelect then
			self:onSelect()
		end
	else
		if self.onUnSelect then
			self:onUnSelect()
		end
	end
end


function ToggleButton:draw(buffer)
	local backColour
	local textColour
	
	local x, y, width, height = self:getTextPos()
	
	if self.held and self.changeColourOnHold then
		backColour = self.heldBackgroundColour or self.backgroundColour
		textColour = self.heldTextColour or self.textColour
	elseif self.selected then
		backColour = self.selectedBackgroundColour or self.backgroundColour
		textColour = self.selectedTextColour or self.textColour
	else
		backColour = self.backgroundColour
		textColour = self.textColour
	end
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour) 
	end
	
	buffer:writeTextBox(x,  y, width, height, self.text, textColour, backColour, self.xAlignment, self.yAlignment)
end

function ToggleButton:applyTheme(theme)
	self.super:applyTheme(theme)
	
	self.selectedBackgroundColour = theme.selectedBackgroundColour
	self.selectedTextColour = theme.selectedTextColour
end

--Zenix was here
