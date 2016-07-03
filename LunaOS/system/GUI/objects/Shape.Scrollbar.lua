Scrollbar = object.class(GUI.Shape)

Scrollbar.held = false
Scrollbar.focused = false


function Scrollbar:init(xPos, yPos, height, steps)
	self.super:init(xPos, yPos, 1, height)
	
	self.steps = steps
	self.scrollLevel = 1
	
	self:addEventListener("mouse_click", self. handleDown)
	self:addEventListener("mouse_up",  self.handleUp)
	self:addEventListener("mouse_drag", self.handleDrag)
	self:addEventListener("key", self.handleKey)
end

function Scrollbar:handleKey(event, key)
	if self.focused then
		if key == 200 then --up
			self:scrollUp()
		end
		
		if key == 208 then -- down
			self:scrollDown()
		end
		
		if key == 201 then --up
			self:scrollUp(4)
		end
		
		if key == 209 then -- down
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

function Scrollbar:handleDown(event, mouseButton, xPos, yPos)
	self.focused = false
	
	if self:isInBounds(xPos, yPos) then
		local barSize = self:getBarSize()
		local barPos = self:getBarPos()

		if yPos < barPos or yPos > barPos + barSize - 1 then
			self:setBarPos(math.min((yPos - self.yPos + 1) - mathUtils.round(barSize / 2) + 1,  self.height - barSize + 1))
		end

		self.held = true
		self.barGrabPoint = yPos - self:getBarPos() 
	end
end

function Scrollbar:handleUp(event, mouseButton, xPos, yPos)
	if self:isInBounds(xPos, yPos) and self.held then
		self.focused = true
	end
	
	self.held = false
end

function Scrollbar:handleDrag(event, mouseButton, xPos, yPos)
	if not self.held then return end
	
	local difference = self.yPos - yPos
	self:setBarPos(yPos - self.yPos + 1 - self.barGrabPoint) 
end

function Scrollbar:updateButtonPos()
	self.upButton:setPos(self.xPos, self.yPos)
	self.downButton:setPos(self.xPos, self.yPos + self.height - 1)
end

function Scrollbar:scrollUp(amount)
	self.scrollLevel = math.max(1, self.scrollLevel - (amount or 1))
end

function Scrollbar:scrollDown(amount)
	self.scrollLevel = math.min(self.steps, self.scrollLevel + (amount or 1))
end

function Scrollbar:getBarSize()
	--calculates how big the bar is
	return math.max(self.height - self.steps + 1, 1)
end

function Scrollbar:getBarPos()
	--calculates where the bar is 
	local barSize = self:getBarSize()
	local movementSpace = self.height - barSize + 1
	local percentage = movementSpace / self.steps --how much the bar should move per step
	local barPos = math.floor(percentage * (self.scrollLevel - 1)) + self.yPos
	
	return barPos
end

function Scrollbar:setBarPos(barPos)
	local barSize = self:getBarSize()
	local movementSpace = self.height - barSize + 1
	local percentage = self.steps /  movementSpace
	local pos = math.floor(percentage * (barPos - 1)) 
	
	self.scrollLevel =  math.max(1, math.min(pos + 1, self.steps))
end

function Scrollbar:drawBar(buffer)
	local barSize = self:getBarSize()
	local barPos = self:getBarPos()
	
	buffer:drawVLine(self.xPos, barPos, barSize , self.barColour)
end

function Scrollbar:draw(buffer)
	buffer:drawVLine(self.xPos, self.yPos, self.height, self.backgroundColour)
	self:drawBar(buffer)
end

function Scrollbar:isInBounds(xPos, yPos)
	return xPos >= self.xPos and xPos <= self.xPos + self.width - 1 and
	yPos >= self.yPos and yPos <= self.yPos + self.height - 1
end

function Scrollbar:applyTheme(theme)
	self.backgroundColour = theme.scrollbarBackgroundColour
	self.barColour = theme.scrollbarColour
end