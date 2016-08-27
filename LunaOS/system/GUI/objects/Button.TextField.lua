TextField = object.class(GUI.Button)

TextField.scrollPos = 1
TextField.cursorPos = 1
TextField.blinking = false
	
function TextField:init(xPos, yPos, width, text)
	self.super:init(xPos, yPos, width, 1, text)
	
	self.text = text or ""

	self:addEventListener("key", self.handleKey)
	self:addEventListener("char", self.handleChar)
	self:addEventListener("paste", self.handleChar)
	self:addEventListener("mouse_click", self.handleDown)
	self:addEventListener("mouse_drag", self.handleDrag)
end

function TextField:setSize(width)
	self.super:setSize(width, 1)
end

function TextField:handleDown(event, mouse, xPos, yPos)
	if self:isInBounds(xPos, yPos) then
		local point = self:getPoint(xPos)
		--point = math.min(#self.text, point)
		
		self:unSelect()
		self.cursorPos = point
		self.startSelect = point
		self:requestFocus()
	else
		self:unFocus()
	end
end


function TextField:handleDrag(event, mouse, xPos, yPos)
	if self:isFocus() then
		xPos = math.max(self.xPos, math.min(xPos, self.xPos + self.width - 1))
		local point = self:getPoint(xPos)
		--point = math.min(#self.text, point)
		
		self.cursorPos = point
		self.endSelect = point
	end
end

function TextField:handleKey(event, key)
	if self:isFocus() then
		if key == 203 then --left
			self:moveCursorLeft()
			self:unSelect()
		end
		
		if key == 205 then --right
			self:moveCursorRight()
			self:unSelect()
		end
		
		if key == 199 then --home
			self:goToStart()
			self:unSelect()
		end
		
		if key == 207 then --end
			self:goToEnd()
			self:unSelect()
		end
		
		if key == 14 then --backspace
			self:removeChar()
		end
		
		if key == 28 then --enter
			if self.onEnter then
				self:onEnter()
			end
		end
		
		if key == 211 then --del
			self:removeChar(self.cursorPos)
		end
		
		if key == 30 and keyHandler.isKeyDown(29)  then--ctrl + a
			self.startSelect = 1
			self.endSelect = #self.text
			
			self:goToStart()
		end
	end
end

function TextField:setText(text)
	self.super:setText(text)
	
	self:goToEnd()
	self:unSelect()
end

function TextField:handleChar(event, chr)
	if self:isFocus() then
		self:addChar(chr)
	end
end

function TextField:scrollLeft()
	if self.scrollPos > 1 then
		self.scrollPos = self.scrollPos - 1
	end
end

function TextField:scrollRight()
	if self.scrollPos < #self.text - self.width + 1 then
		self.scrollPos = self.scrollPos + 1
	end
end

function TextField:moveCursorLeft(n)
		self.cursorPos = math.max(self.cursorPos - (n or 1), 1)
	
	
	if self.cursorPos < self.scrollPos then
		self.scrollPos = self.cursorPos
	end
end

function TextField:moveCursorRight(n)
	n = math.min(n or 1, #self.text - self.cursorPos + 1)
	
	self.cursorPos = self.cursorPos + n
	
	if self.cursorPos - self.width + 1 > self.scrollPos  then
		  self.scrollPos = self.cursorPos - self.width + 1
	end
end

function TextField:goToStart()
	self.scrollPos = 1
	self.cursorPos = 1
end

function TextField:goToEnd()
	if #self.text + 1 > self.width then
		self.scrollPos = #self.text - self.width + 2
	end
	
	self.cursorPos = #self.text + 1
end

function TextField:addChar(chr)
	self:removeSelected()
	
	local leftPart = self.text:sub(1, self.cursorPos - 1)
	local rightPart = self.text:sub(self.cursorPos)
	
	self:setText(leftPart .. chr .. rightPart)
	self:moveCursorRight(#chr)
end

function TextField:removeChar(pos, amount)
	if self:getSelectedPos() then
		self:removeSelected()
		return
	end
			
	pos = pos or self.cursorPos - 1
	amount = amount or 1
	
	if pos < 1 then return end

	local leftPart = self.text:sub(1, pos - 1)
	local rightPart = self.text:sub(pos + amount)
	
	
	self:setText(leftPart .. rightPart)
	self:moveCursorLeft(amount)
	
	if self.cursorPos == #self.text + 1 and self.scrollPos == #self.text - self.width + 3  then 
		self:goToEnd()
	end
end

function TextField:removeSelected()
	local startSelect, endSelect = self:getSelectedPos()
			
	if startSelect then
		self. text = self.text:sub(1, startSelect - 1) .. self.text:sub(endSelect + 1)
		self.cursorPos = startSelect
		self:unSelect()
	end
end

function TextField:getPoint(point)
	point =  point - self.xPos + self.scrollPos
	
	if point > #self.text + 1 then
		point = #self.text + 1
	end
	
	return point
end

function TextField:unSelect()
	self.startSelect = nil
	self.endSelect = nil
end

function TextField:getSelectedPos()
	if self.startSelect and self.endSelect then
		if self.startSelect > self.endSelect then
			return self.endSelect, self.startSelect
		else
			return self.startSelect, self.endSelect
		end
	end
end

function TextField:applyTheme(theme)
	self.super:applyTheme(theme)
	
	self.heldBackgroundColour = theme.backgroundColour
	self.heldTextColour = theme.textColour	
	self.highlightedTextColour = theme.highlightedTextColour
	self.highlightedBackgroundColour = theme.highlightedBackgroundColour
	self.hintColour = theme.hintColour
end

function TextField:draw(buffer)	
	local trimedText
	local textColour = self.textColour
	
	if self.mask and #self.mask > 0  then
		trimedText = self.mask:rep(#self.text):sub(1, #self.text):sub(self.scrollPos, self.scrollPos + self.width - 1)
	else
		trimedText = self.text:sub(self.scrollPos, self.scrollPos + self.width - 1)
	end
	
	if self:isFocus() then 
		term.setCursorBlink(true)
		self.blinking = true
		term.setCursorPos(self.xPos + self.cursorPos - self.scrollPos, self.yPos)
	else
		if self.blinking then
			term.setCursorBlink(false)
			self.blinking = false
		end
		
		if  #self.text == 0 and self.hint then
			trimedText = self.hint:sub(self.scrollPos, self.scrollPos + self.width - 1)
			textColour = self.hintColour
		end
		
		self:unSelect()
	end
	
	buffer:drawBox(self.xPos, self.yPos, self.width, self.height, self.backgroundColour )
	buffer:writeStr(self.xPos, self.yPos, trimedText, textColour)
	
	local startSelect, endSelect = self:getSelectedPos()
			
	if startSelect then
		local highlightedText = trimedText:sub(startSelect - self.scrollPos + 1, endSelect - self.scrollPos + 1)
		
		buffer:writeStr(self.xPos + startSelect - self.scrollPos, self.yPos, highlightedText, self.highlightedTextColour, self.highlightedBackgroundColour)
	end
end

