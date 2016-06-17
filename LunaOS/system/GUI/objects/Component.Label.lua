Label = object.class(GUI.Component)

function Label:init(xPos, yPos, width, height, text, backgroundColour, textColour)
	self.xPos = xPos
	self.yPos = yPos
	self.width = width
	self.height = height
	self.backgroundColour = backgroundColour
	self.textColour = textColour
	self.text = text
	
	self.upMargin = 0
	self.downMargin = 0
	self.leftMargin = 0
	self.rightMargin = 0
	
	self.xAlignment = "left"
	self.yAlignment = "center"
end

function Label:draw(buffer)
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, self.backgroundColour) --  v = GUI.View(1) l = GUI.Button(3,3,20,5,"this is a test for text alignment i hope it works very well", "9", "8") v:addComponent(l)
	end
	
	buffer:writeTextBox(self.xPos + self.leftMargin, self.yPos + self.upMargin, self.width - self.leftMargin - self.rightMargin, self.height - self.downMargin - self.upMargin, "self.text", self.textColour, nil, self.xAlignment, self.yAlignment)
end

function Label:setMargin(up, down, left, right)
	self.upMargin = up
	self.downMargin = down
	self.leftMargin = left
	self.rightMargin = right
end