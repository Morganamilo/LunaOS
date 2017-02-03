Scrollbar = object.class(GUI.Shape)

Scrollbar.held = false
Scrollbar.scrollLevel = 1

function Scrollbar:init(xPos, yPos, width, height, steps) --   mathUtils.time(function() f:draw() end, 60)
	self.super:init(xPos, yPos, width, height) -- some bug, stupid dirty workaround
	
	self.steps = steps
	
	self:addEventListener("mouse_click", self. handleDown)
	self:addEventListener("mouse_up",  self.handleUp)
	self:addEventListener("mouse_drag", self.handleDrag)
	self:addEventListener("mouse_scroll", self.handleScroll)
	self:addEventListener("key", self.handleKey)
end

function Scrollbar:getLength()
	return self.height
end

function Scrollbar:handleKey(event, key)
	if self:isFocus() then
		if key == 200 then --up
			self:scrollUp()
		end
		
		if key == 208 then -- down
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

function Scrollbar:handleScroll(event, direction, xPos, yPos)
	if self:isInBounds(xPos, yPos) then
		if direction < 0 and self.scrollLevel > 1 then
			self:scrollUp()
			self:requestFocus()
		elseif direction > 0 and self.scrollLevel < self.steps then
			self:scrollDown()
			self:requestFocus()
		end
	end
end

function Scrollbar:handleDown(event, mouseButton, xPos, yPos)	
	if mouseButton == 2 then return end
	
	if self:isInBounds(xPos, yPos) then
		local barSize = self:getBarSize() 
		local barPos = self:getBarPos()

		if yPos < barPos or yPos > barPos + barSize - 1 then
			self:setBarPos(math.min((yPos - self.yPos + 1) - mathUtils.round(barSize / 2) + 1,  self:getLength() - barSize + 1))
		end

		self.held = true
		self.barGrabPoint = yPos - self:getBarPos() 
		self:requestFocus()
	end
end

function Scrollbar:handleUp(event, mouseButton, xPos, yPos)	
	if self.held then 
		self:requestFocus()
	end
	
	self.held = false
end

function Scrollbar:handleDrag(event, mouseButton, xPos, yPos)
	if not self.held then return end
	
	local difference = self.yPos - yPos
	self:setBarPos(yPos + 1 - self.barGrabPoint) 
end

function Scrollbar:scrollUp(amount)
	self.scrollLevel = math.max(1, self.scrollLevel - (amount or 1))
end

function Scrollbar:scrollDown(amount)
	self.scrollLevel = math.min(self.steps, self.scrollLevel + (amount or 1))
end

function Scrollbar:scroll(amount)
	if amount > 0 then
		self:scrollUp(amount)
	elseif amount < 0 then
		self:scrollDown(-amount)
	end
end

function Scrollbar:getBarSize()
	--calculates how big the bar is
	return math.max(self:getLength() - self.steps + 1, 1)
end

function Scrollbar:getBarPos()
	--calculates where the bar is 
	
	--how big the bar is
	local barSize = self:getBarSize()
	local movementSpace = self:getLength() - barSize + 1
	local percentage = movementSpace / self.steps --how much the bar should move per step
	local barPos = math.min(mathUtils.round(percentage * (self.scrollLevel - 1)), self:getLength() - 1)
	
	return barPos
end

function Scrollbar:setBarPos(barPos)
	local barSize = self:getBarSize()
	local movementSpace = self:getLength() - barSize + 1
	local percentage = self.steps /  movementSpace
	local pos = mathUtils.round(percentage * (barPos - 1)) 
	
	self.scrollLevel =  math.max(1, math.min(pos + 1, self.steps))
end

function Scrollbar:draw(buffer)
	local barSize = self:getBarSize()
	local barPos = self:getBarPos() + self.yPos
	
	buffer:drawBox(self.xPos, self.yPos, self.width, self:getLength(), self.backgroundColour)
	buffer:drawBox(self.xPos, barPos, self.width, barSize , self.barColour)
end

function Scrollbar:applyTheme(theme)
	self.backgroundColour = theme.scrollbarBackgroundColour
	self.barColour = theme.scrollbarColour
end
