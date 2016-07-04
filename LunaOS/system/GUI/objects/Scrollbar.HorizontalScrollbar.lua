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
	if self.focused then
		if key == 203 then --left
			self:scrollUp()
		end
		
		if key == 205 then --right
			self:scrollDown()
		end
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

function HorizontalScrollbar:handleDown(event, mouseButton, xPos, yPos)
	self.focused = false
	
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