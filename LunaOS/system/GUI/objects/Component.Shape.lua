Shape = object.class(GUI.Component)

function Shape:init(xPos, yPos, width, height)
	self:setPos(xPos, yPos)
	self:setSize(width, height)
end

function Shape:setPos(xPos, yPos)
	self.xPos = xPos
	self.yPos = yPos
end

function Shape:setSize(width, height)
	self.width = width
	self.height = height
end

function Shape:isInBounds(xPos, yPos)
	return xPos >= self.xPos and xPos <= self.xPos + self.width - 1 and
	yPos >= self.yPos and yPos <= self.yPos + self.height - 1
end

function Shape:transform(xDifference, yDifference)
	self:setPos(self.xPos + xDifference, self.yPos + yDifference)
end

function Shape:draw(buffer)
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, self.backgroundColour) 
	end
end

function Shape:applyTheme(theme)
	self.backgroundColour = theme.backgroundColour
end