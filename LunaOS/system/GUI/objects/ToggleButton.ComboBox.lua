ComboBox = object.class(GUI.ToggleButton)
ComboBox:implement(GUI.Scrollable)

ComboBox.open = false
ComboBox.activateOnRelease = false
ComboBox.scrollLevel = 1
ComboBox.scrollLength = 6
ComboBox.backgroundColour = "8"

function ComboBox:init(xPos, yPos, width, height, backgroundColour, textColour)
	self.super:init(xPos, yPos, width, height, "test", backgroundColour, textColour)
end

function ComboBox:getScrollXPos()
	return self.xPos + self.width -1
end

function ComboBox:getScrollYPos()
	return self.yPos
end

function ComboBox:scrollUp()

end

function ComboBox:scrollDown()

end

function ComboBox:OnClick()
	self.text = "test"
end

function ComboBox:draw(buffer)
	buffer:drawBox(self.xPos, self.yPos, self.width - 1, 1, self.backgroundColour) 
end