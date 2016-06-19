Shape = object.class(GUI.Component)

function Shape:init(xPos, yPos, width, height, text)
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

function Shape:transform(xDifference, yDifference)
	self:setPos(self.xPos + xDifference, yPos + yDifference)
end