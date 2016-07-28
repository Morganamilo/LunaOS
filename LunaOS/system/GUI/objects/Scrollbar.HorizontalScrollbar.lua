HorizontalScrollbar = object.class(GUI.Scrollbar)

function HorizontalScrollbar:init(xPos, yPos, width, height, steps)
	self.super:init(xPos, yPos, width, height, steps)
	self.length = width
	
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
	if self:isInBounds(xPos, yPos) and kernel.keyHandler.isKeyDown(42)  then
		if direction < 0 then
			self:scrollUp()
		else
			self:scrollDown()
		end
		
		self:requestFocus()
	else
		self:unFocus()
	end
end

function HorizontalScrollbar:draw(buffer)
	local barSize = self:getBarSize()
	local barPos = self:getBarPos()
	
	buffer:drawBox(self.xPos, self.yPos, self.length, self.height, self.backgroundColour)
	buffer:drawBox(barPos, self.yPos, barSize, self.height, self.barColour)
end

function HorizontalScrollbar:getBarPos()
	--calculates where the bar is 
	local barSize = self:getBarSize()
	local movementSpace = self.length - barSize + 1
	local percentage = movementSpace / self.steps --how much the bar should move per step
	local barPos = math.floor(percentage * (self.scrollLevel - 1)) + self.xPos
	
	return barPos
end

function HorizontalScrollbar:setSize(width, height)
	self.super:setSize(width, height)
	self.length = width
end

function HorizontalScrollbar:handleDown(event, mouseButton, xPos, yPos)
	self:unFocus()
	
	if self:isInBounds(xPos, yPos) then
		local barSize = self:getBarSize()
		local barPos = self:getBarPos()

		if xPos < barPos or xPos > barPos + barSize - 1 then
			self:setBarPos(math.min((xPos - self.xPos + 1) - mathUtils.round(barSize / 2) + 1,  self.length - barSize + 1))
		end

		self.held = true
		self.barGrabPoint = xPos - self:getBarPos() 
	end
end

function HorizontalScrollbar:handleDrag(event, mouseButton, xPos, yPos)
	if not self.held then return end
	
	local difference = self.xPos - xPos
	self:setBarPos(xPos - self.xPos + 1 - self.barGrabPoint) 
end