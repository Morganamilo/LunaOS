Button = object.class(GUI.Label)

Button.activateOnRelease = true --should the button react as soon as it is clicked or when it is released
Button.held = false

function Button:init(xPos, yPos, width, height, str, backgroundColour, textColour)
	self.super:init(xPos, yPos, width, height, str, backgroundColour, textColour)
	
	local function eventHandler(event, mouseButton, xPos, yPos)
		if event == "mouse_click" then
			self:handleDown(xPos, yPos, mouseButton)
		elseif event == "mouse_up" then
			self:handleUp(xPos, yPos, mouseButton)
		elseif event == "mouse_drag" then
			self:handleDrag(xPos, yPos, mouseButton)
		end
	end
	
	self:addEventListener("mouse_click", self.eventHandler)
	self:addEventListener("mouse_up", self.eventHandler)
	self:addEventListener("mouse_drag", self.eventHandler)
	
	self:addEventListener("mouse_click", eventHandler)
	
	self.heldBackgroundColour = self.backgroundColour
	self.heldTextColour = self.textColour
end

function Button:isInComponent(xPos, yPos)
	return xPos >= self.xPos and xPos <= self.xPos + self.width - 1 and
	yPos >= self.yPos and yPos <= self.yPos + self.height - 1
end

function Button:handleDown(xPos, yPos, mouse)
	if self:isInComponent(xPos, yPos) then
		self.held = true
		
		if not self.activateOnRelease then
			self:onClick()
		end
	end
end

function Button:handleUp(xPos, yPos, mouse)
	if self:isInComponent(xPos, yPos) and self.held and self.activateOnRelease then
		self:onClick()
	end
	
	self.held = false
end

function Button:handleDrag(xPos, yPos, mouse)

end

function Button:onClick()
	--empty function so there is no error thrown when a button is pressed and there is no onClick function set 
end

function Button:draw(buffer)
	local backColour = self.held and self.heldBackgroundColour or self.backgroundColour
	local textColour = self.held and self.heldTextColour or self.textColour
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour) --  v = GUI.View(1) l = GUI.Label(3,3,20,5,"this is a test for text alignment i hope it works very well", "9", "8") v:addComponent(l) l:addEventListener("char", function(a) l.str = "a"  if a == "z" then v:close() end end)
	end
	
	buffer:writeTextBox(self.xPos + self.leftMargin, self.yPos + self.upMargin, self.width - self.leftMargin - self.rightMargin, self.height - self.downMargin - self.upMargin, "4345", textColour, nil, self.xAlignment, self.yAlignment)
end