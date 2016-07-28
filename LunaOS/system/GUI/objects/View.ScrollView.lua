ScrollView = object.class(GUI.View)

function ScrollView:init(xPos, yPos, xSize, ySize, virtualXSize, virtualYSize, backgroundColour)
	self.super:init(xPos, yPos, xSize, ySize, backgroundColour)
	
	self.virtualXSize = virtualXSize
	self.virtualYSize = virtualYSize
	
	self.vBar = GUI.Scrollbar()
	self.hBar = GUI.HorizontalScrollbar()
	
	self:setSubComponentPos()
	self:setSubComponentSize()
	self:setSubComponentSteps()
	
	self.vBar.getFrame = function() return self:getFrame() end
	self.hBar.getFrame = function() return self:getFrame() end
end

function ScrollView:draw(buffer)
	self.super:drawInternal()

	self.hBar:onDraw(buffer)
	self.vBar:onDraw(buffer)

	buffer:drawBuffer(self.buffer, self.hBar.scrollLevel, self.vBar.scrollLevel, self.bufferXLength, self.bufferYLength)
end

function ScrollView:setSubComponentPos()
	self.vBar:setPos(self.xSize + self.xPos - 1, self.yPos)
	self.hBar:setPos(self.xPos, self.yPos + self.ySize - 1)
end

function ScrollView:setSubComponentSize()
	self.vBar:setSize(1, self.ySize)
	self.hBar:setSize(self.xSize - 1, 1)
	self.buffer:resize(self.virtualXSize, self.virtualYSize, self.backgroundColour)
end

function ScrollView:setSubComponentSteps()
	local showBoth = self.virtualXSize > self.xSize or self.virtualYSize > self.ySize 
	
	if self.virtualXSize >= self.xSize and showBoth  then
		self.hBar.visible = true
		self.bufferYLength = self.ySize -1
		self.vBar.steps = self.virtualYSize - self.ySize + 2
	else
		self.hBar.visible = false
		self.bufferYLength = self.ySize
		self.vBar.steps = self.virtualYSize - self.ySize + 1
	end
	
	if self.virtualYSize >= self.ySize and showBoth then
		self.vBar.visible = true
		self.hBar:setSize(self.xSize - 1, 1)
		self.bufferXLength = self.xSize -1
		self.hBar.steps = self.virtualXSize - self.xSize + 2
	else
		self.vBar.visible = false
		self.hBar:setSize(self.xSize, 1)
		self.bufferXLength = self.xSize 
		self.hBar.steps = self.virtualXSize - self.xSize + 1
	end
end


function ScrollView:setSize(xSize, ySize)
	self.xSize = xSize
	self.ySize = ySize
	self:setSubComponentSize()
end

function ScrollView:setVirtualSize(xSize, ySize)
	self.virtualXSize = xSize
	self.virtualYSize = ySize
	
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

function ScrollView:handleEvent(event, force)
	self.vBar:handleEvent(event)
	self.hBar:handleEvent(event)
	
	if not force then
		if event[1] == "mouse_click" or event[1] == "mouse_up" or event[1] == "mouse_scroll" or event[1] == "mouse_drag" then
			--if the event is out of the range of the view then dont process any further
			if event[3] < self.xPos or event[3] > self.xPos + self.xSize - 2 or event[3] < self.yPos or event[4] > self.yPos + self.ySize - 2 then
				return 
			end
		end
	end
	
	local xAjust = self.hBar.scrollLevel - 1
	local yAjust = self.vBar.scrollLevel - 1
	
	self:ajustEvent(event, xAjust, yAjust)
	self.super:handleEvent(event, true)
end
