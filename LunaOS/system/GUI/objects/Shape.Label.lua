Label = object.class(GUI.Shape)

function Label:init(xPos, yPos, width, height, text)
	self.super:init(xPos, yPos, width, height)
	
	self:setText(text or "")
	self:setMargin(0, 0, 0, 0)
	self:setAlignment("left", "center")
end

function Label:setText(text)
	self.text = text
end

function Label:clear()
	self:setText("")
end

function Label:setAlignment(horizontal, vertical)
	self.xAlignment = horizontal
	self.yAlignment = vertical
end

function Label:getTextPos()
	return 
		self.xPos + self.leftMargin,
		self.yPos + self.upMargin, 
		self.width - self.leftMargin - self.rightMargin, 
		self.height - self.downMargin - self.upMargin
end

function Label:draw(buffer)
	local x, y, width, height = self:getTextPos()
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, self.backgroundColour) 
	end
	
	buffer:writeTextBox(x, y, width, height, self.text, self.textColour, nil, self.xAlignment, self.yAlignment)
end

function Label:setMargin(up, down, left, right)
	self.upMargin = up
	self.downMargin = down
	self.leftMargin = left
	self.rightMargin = right
end

function Label:applytheme(theme)
	self.backgroundColour = theme.backgroundColour
	self.textColour = theme.textColour
end