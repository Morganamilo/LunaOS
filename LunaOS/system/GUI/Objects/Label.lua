Label = object.class(GUI.Component)

function Label:init(xPos, yPos, width, height, str, backgroundColour, textColour)
	self.xPos = xPos
	self.yPos = yPos
	self.width = width
	self.height = height
	self.backgroundColour = backgroundColour
	self.textColour = textColour
	self.str = str
	
	self.upMargin = 0
	self.downMargin = 0
	self.leftMargin = 0
	self.rightMargin = 0
	
	self.xAlignment = "left"
	self.yAlignment = "center"
end

function Label:onDraw(buffer)
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, self.backgroundColour) --  v = GUI.View(1) l = GUI.Label(3,3,20,5,"this is a test for text alignment i hope it works very well", "9", "8") v:addComponent(l) l:addEventListener("char", function(a) l.str = a  if a == "z" then v:close() end)
	end
	
	buffer:writeTextBox(self.xPos + self.leftMargin, self.yPos + self.upMargin, self.width - self.leftMargin - self.rightMargin, self.height - self.downMargin - self.upMargin, self.str, self.textColour, self.backgroundColour, self.xAlignment, self.yAlignment)
end

function Label:setMargin(up, down, left, right)
	self.upMargin = up
	self.downMargin = down
	self.leftMargin = left
	self.rightMargin = right
end