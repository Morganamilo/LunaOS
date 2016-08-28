HorizontalScrollbar = object.class(GUI.Scrollbar)

function HorizontalScrollbar:init(xPos, yPos, width, height, steps)
	self.super:init(xPos, yPos, width, height, steps)
	
	self:addEventListener("mouse_click", self. handleDown)
	self:addEventListener("mouse_up",  self.handleUp)
	self:addEventListener("mouse_drag", self.handleDrag)
	self:addEventListener("mouse_scroll", self.handleScroll)
	self:addEventListener("key", self.handleKey)
end

function HorizontalScrollbar:handleKey(event, key)
	if self:isFocus() then
		if key == 203 then --left
			self:scrollUp()
		end
		
		if key == 205 then --right
			self:scrollDown()
		end
		
		if key == 201 then --pageup
			self:scrollUp(4)
		end
		
		if key == 209 then -- pagedown
			self:scrollDown(4)
		end
		
		if key == 199 then --home
			self.scrollLevel = 1
		end
		
		if key == 207 then --end
			self.scrollLevel = self.steps
		end
	end
end

function HorizontalScrollbar:handleScroll(event, direction, xPos, yPos)
	if self:isInBounds(xPos, yPos) and keyHandler.isKeyDown(42)  then
		if direction < 0 and self.scrollLevel > 1 then
			self:scrollUp()
			self:requestFocus()
		elseif direction > 0 and self.scrollLevel < self.steps then
			self:scrollDown()
			self:requestFocus()
		end
	end
end

function HorizontalScrollbar:getLength()
	return self.width
end

function HorizontalScrollbar:handleDown(event, mouseButton, xPos, yPos)
	if mouseButton == 2 then return end
	
	if self:isInBounds(xPos, yPos) then
		local barSize = self:getBarSize() 
		local barPos = self:getBarPos()

		if xPos < barPos or xPos > barPos + barSize - 1 then
			self:setBarPos(math.min((xPos - self.xPos + 1) - mathUtils.round(barSize / 2) + 1,  self:getLength() - barSize + 1))
		end

		self.held = true
		self.barGrabPoint = xPos - self:getBarPos() 
		self:requestFocus()
	end
end

function HorizontalScrollbar:handleDrag(event, mouseButton, xPos, yPos)
	if not self.held then return end
	
	local difference = self.xPos - xPos
	self:setBarPos(xPos + 1 - self.barGrabPoint) 
end

function HorizontalScrollbar:draw(buffer)
	local barSize = self:getBarSize()
	local barPos = self:getBarPos() + self.xPos
	
	buffer:drawBox(self.xPos, self.yPos, self:getLength(), self.height, self.backgroundColour)
	buffer:drawBox(barPos, self.yPos, barSize, self.height, self.barColour)
end