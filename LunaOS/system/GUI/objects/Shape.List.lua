List = object.class(GUI.Shape)

function List:init(xPos, yPos, width, height)
	self.super:init(xPos or 1, yPos or 1, width or 1, height or 1)
	self.entries = {}

	self.scrollbar = GUI.Scrollbar(self.xPos, self.yPos, self.width, self.height, 0)
	self.scrollbar:setParentPane(self)

	self:addEventListener("", self.handleAny)
	self:addEventListener("mouse_scroll", self.handleScroll)
	self:addEventListener("mouse_click", self.handleClick)
	self:addEventListener("key", self.handleKey)
end

function List:handleAny(...)
	self.scrollbar:handleEvent(arg)
end

function List:handleClick(event, click, x, y)
	if click == 2 and self:isInBounds(x, y) then
		self:setSelected(nil)
		self:unFocus()
	elseif click == 1 then
		if self:isInBounds(x, y) then
			self:setSelected(self.scrollbar.scrollLevel + (y - self.yPos))
			self:requestFocus()
		else
			self:unFocus()
		end
	end
end

function List:handleScroll(event, direction, x, y)
	if self:isInBounds(x, y) then
		self.scrollbar:scroll(-direction)
	end
end

function List:handleKey(event, key)
	if not self:isFocus() then return end

	if key == keys.up and self.selected > 1 then
		self:setSelected(self.selected - 1)

		if self.selected < self.scrollbar.scrollLevel then
			self.scrollbar.scrollLevel = self.selected
		end

	elseif key == keys.down and self.selected < #self.entries then
		self:setSelected(self.selected + 1)

		if self.selected > self.scrollbar.scrollLevel + self.height - 1 then
			self.scrollbar.scrollLevel = self.selected - self.height + 1
		end

	elseif key == keys.home then
		self:setSelected(1)
		self.scrollbar.scrollLevel = 1

	elseif key == keys["end"] then
		self:setSelected(#self.selected)
		self.scrollbar.scrollLevel = self.scrollbar.steps
	end
end

function List:addEntry(item)
	self.entries[#self.entries + 1] = item
	self.scrollbar.steps = math.max(#self.entries - self.height, 0)
end

function List:removeEntry(item)
	self.entries[item] = nil
end

function List:setPos(xPos, yPos)
	self.super:setPos(xPos, yPos)
	self:updateScrollbar()
end

function List:setSize(width, height)
	self.super:setSize(width, height)
	self:updateScrollbar()
end

function List:updateScrollbar()
	self.scrollbar:setSize(1, self.height)
	self.scrollbar:setPos(self.xPos + self.width - 1, self.yPos)
end

function List:setSelected(n)
	if self.entries[n] or n == nil then
		self.selected = n

		if self.onSelect then
			self:onSelect(n)
		end
	end
end


function List:getSelectedEntry()
	return self.entries[self.selected]
end

function List:isInBounds(x, y)
	return x >= self.xPos and x < self.xPos + self.width and y >= self.yPos and y <= self.yPos + self.height
end

function List:draw(buffer)
	self.super:draw(buffer)

	for n = 0, math.min(self.height - 1, #self.entries) do
		local backgroundColour = self.backgroundColour
		local textColour = self.textColour
		local text = self.entries[self.scrollbar.scrollLevel + n]:sub(1, self.width - 1)
		text = text .. string.rep(" ", math.max(0, self.width - #text - 1))

		if self.scrollbar.scrollLevel + n == self.selected then
			backgroundColour = self.selectedColour
		end

		buffer:writeStr(self.xPos, self.yPos + n, text, textColour, backgroundColour)
	end

	self.scrollbar:draw(buffer)
end

function List:applyTheme(theme)
	self.super:applyTheme(theme)
	self.scrollbar:applyTheme(theme)
	self.textColour = theme.textColour
	self.selectedColour = theme.highlightedBackgroundColour
end
