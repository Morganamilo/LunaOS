ScrollView = object.class(GUI.View)

function ScrollView:init(xPos, yPos, width, height, virtualwidth, virtualheight)
	--self.super:init(xPos, yPos, width, height)
	self.super:init(xPos, yPos, virtualwidth, virtualheight)
	
	self.width = width
	self.height = height
	
	self.virtualwidth = virtualwidth
	self.virtualheight = virtualheight
	
	self.vBar = GUI.Scrollbar()
	self.hBar = GUI.HorizontalScrollbar()
	
	self:setSubComponentPos()
	self:setSubComponentSize()
	self:setSubComponentSteps()
	
	self:addEventListener("", self. handleAny)
	
	self.vBar:setParentPane(self)
	self.hBar:setParentPane(self)
	
	self:setAjustFunctions()
end

function ScrollView:makeBufffer()
	error()
end

function ScrollView:handleScroll(event, direction, xPos, yPos)
	local bar
	
	if keyHandler.isKeyDown(42) then
		bar = self.hBar
	else
		bar = self.vBar
	end
	
	if self:isFocus() then
		if direction < 0 then
			bar:scrollUp()
		else
			bar:scrollDown()
		end
	end
end

function ScrollView:handleKey(event, key)
	if self:isFocus() then
		if key == 203 then --left
			self.hBar:scrollUp()
		end
		
		if key == 205 then --right
			self.hBar:scrollDown()
		end
		
		if key == 200 then --up
			self.vBar:scrollUp()
		end
		
		if key == 208 then -- down
			self.vBar:scrollDown()
		end
		
		if key == 201 then --pageup
			self.vBar:scrollUp(4)
		end
		
		if key == 209 then -- pagedown
			self.vBar:scrollDown(4)
		end
		
		if key == 199 then --home
			self.vBar.scrollLevel = 1
		end
		
		if key == 207 then --end
			self.vBar.scrollLevel = self.vBar.steps
		end
	end
end

function ScrollView:getAjust()
	return self.xPos  - self.hBar.scrollLevel, self.yPos - self.vBar.scrollLevel 
end

function ScrollView:clear()
	self.buffer:clearArea(self.backgroundColour, self.hBar.scrollLevel, self.vBar.scrollLevel, self.width, self.height)
end

function ScrollView:draw(buffer)
	self:drawInternal()

	self.hBar:onDraw(buffer)
	self.vBar:onDraw(buffer)

	buffer:drawBuffer(self.buffer, self.hBar.scrollLevel, self.vBar.scrollLevel, self.bufferXLength, self.bufferYLength)
end

function ScrollView:setSubComponentPos()
	self.vBar:setPos(self.width + self.xPos - 1, self.yPos)
	self.hBar:setPos(self.xPos, self.yPos + self.height - 1)
end

function ScrollView:setSubComponentSize()
	self.vBar:setSize(1, self.height)
	self.hBar:setSize(self.width - 1, 1)
end

function ScrollView:setSubComponentSteps()
	local showBoth = self.virtualwidth > self.width or self.virtualheight > self.height 
	
	if self.virtualwidth >= self.width and showBoth  then
		self.hBar.visible = true
		self.bufferYLength = self.height -1
		self.vBar.steps = self.virtualheight - self.height + 2
	else
		self.hBar.visible = false
		self.bufferYLength = self.height
		self.vBar.steps = self.virtualheight - self.height + 1
	end
	
	if self.virtualheight >= self.height and showBoth then
		self.vBar.visible = true
		self.hBar:setSize(self.width - 1, 1)
		self.bufferXLength = self.width -1
		self.hBar.steps = self.virtualwidth - self.width + 2
	else
		self.vBar.visible = false
		self.hBar:setSize(self.width, 1)
		self.bufferXLength = self.width 
		self.hBar.steps = self.virtualwidth - self.width + 1
	end
end

function ScrollView:isInBounds(xPos, yPos)
	return xPos >= self.xPos and xPos <= self.xPos + self.bufferXLength - 1 and
	yPos >= self.yPos and yPos <= self.yPos + self.bufferYLength - 1
end

function ScrollView:setSize(width, height)
	self.width = width
	self.height = height
	self.buffer:resize(self.virtualwidth, self.virtualheight, self.backgroundColour)
	self:setSubComponentSize()
end

function ScrollView:setVirtualSize(width, height)
	self.virtualwidth = width
	self.virtualheight = height
	
	self.buffer:resize(width, height, "0")
	self:setSubComponentSteps()
end

function ScrollView:setPos(xPos, yPos)
	self.super:setPos(xPos, yPos)
	self:setSubComponentPos()
end

function ScrollView:applyTheme(theme)
	self.super:applyTheme(theme)
	self.vBar:applyTheme(theme)
	self.hBar:applyTheme(theme)
end

function ScrollView:handleAny(...)
	local event = arg
	
	self.vBar:handleEvent(event)
	self.hBar:handleEvent(event)
	
	if not force then
		if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
			--if the event is out of the range of the view then dont process any further
			if not self:isInBounds(event[3], event[4]) then
				return 
			elseif event[1] == "mouse_scroll" then
				local bar
	
				if keyHandler.isKeyDown(42) then
					bar = self.hBar
				else
					bar = self.vBar
				end
				
				if event[2] < 0 and bar.scrollLevel > 1 then
					self:requestFocus()
				elseif event[2] > 0 and bar.scrollLevel < bar.steps then
					self:requestFocus()
				end
			elseif event[1] ~= "mouse_up" then
				--self:requestFocus()
			end
		end
	end
	
	local xAjust = self.hBar.scrollLevel - 1
	local yAjust = self.vBar.scrollLevel - 1
	
	self:ajustEvent(event, xAjust, yAjust)
	self.super:handleAnyForce(unpack(event))
	
	if event[1] == "key" then
		self:handleKey(unpack(event))
	end
	
	if event[1] == "mouse_scroll" then
		self:handleScroll(unpack(event))
	end
end