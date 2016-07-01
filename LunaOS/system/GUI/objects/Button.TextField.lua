TextField = object.class(GUI.Button)

TextField.focused = false
TextField.cursorPos = 1
TextField.scrollPos = 1

TextField.startDrag = nil
TextField.endDrag = nil

TextField.mask = ''

function TextField:init(xPos, yPos, width, text)
	self.super:init(xPos, yPos, width, 1, text)
	
	self:addEventListener("mouse_drag", self. handleDrag)
	self:addEventListener("mouse_up", self. handleUp)
	self:addEventListener("char", self. handleChar)
	self:addEventListener("key", self. handleKey)
	self:addEventListener("paste", self. handlePaste)
end

function TextField:handleDown(xPos, yPos, mouse)
	if self:isInBounds(xPos, yPos) then
		self:focus(xPos, yPos)
		self.endDrag = nil
	else
		self:unFocus()
	end
end

function TextField:handleKey(event, key)
	if self.focused then
		if key == 14 then --backspace
			self:deleteChar(self.cursorPos + self.scrollPos - 1)
			
			if self.cursorPos >= self.width and #self.text > self.width then
				self:scrollLeft()
			else
				self:moveCursorLeft()
			end
		end
		
		if key == 211 then --del
			self:deleteChar(self.cursorPos + self.scrollPos)
		end
		
		if key == 28 then --enter
			self:action()
		end
		
		if key == 203 then --left
			self:moveCursorLeft()
			self:unHighlightAll()
		end
		
		if key == 205 then --right
			self:moveCursorRight()
			self:unHighlightAll()
		end
		
		if key == 199 then --home
			self.cursorPos = 1
			self:unHighlightAll()
		end
		
		if key == 207 then --end
			self.scrollPos = 1
			if #self.text < self.width then
				self.cursorPos = #self.text + 1
			else
				self.cursorPos = self.width 
				self.scrollPos = #self.text - self.width + 2 
			end
			
			self:unHighlightAll()
		end
		
		if key == 30 and kernel.keyHandler.isKeyDown(29)  then--ctrl + a
			self.startDrag = 1 --not cheaty at all
			self.endDrag = self.width + 1
		end
		
	end
end

function TextField:unHighlightAll()
	self.startDrag = nil
	self.endDrag = nil
end

function TextField:handleChar(event, chr)
	if self.focused then
		local pos = self:getHilightedPos()
		
		if pos then
			self:addChar(chr, pos + self.scrollPos)
		else
			self:addChar(chr, self.cursorPos + self.scrollPos)
			self:moveCursorRight()
		end
	end
end

function TextField:handlePaste(event, str)
	if self.focused then
		local pos = self:getHilightedPos()
		
		if pos then
			self:addChar(str, pos + self.scrollPos)
			
			for n = 1, #str -1 do
				self:moveCursorRight()
			end
		else
			self:addChar(str, self.cursorPos + self.scrollPos)
			
			for n = 1, #str do
				self:moveCursorRight()
			end
		end
	end
end

function TextField:deleteChar(pos)
	if not self:deleteHighlightedChars() then
		if pos == 1 then return end
		
		local leftPart = self.text:sub(1, pos - 2)
		local rightPart = self.text:sub(pos)
		
		self:setText(leftPart .. rightPart)
	end
	
	if #self.text == 0 then
		self.cursorPos = 1
	end
end

function TextField:addChar(chr, pos)
	self:deleteHighlightedChars()
	
	local leftPart = self.text:sub(1, pos - 2)
	local rightPart = self.text:sub(pos - 1)
	
	
	self:setText(leftPart .. chr .. rightPart)
end


function TextField:handleDrag(event, mouse, xPos, yPpos)
	if self.focused then
		self.cursorPos = self:xPosToCursorPos(xPos)
		self.endDrag = self:xPosToCursorPos(xPos)
	else
		self:unHighlightAll()
	end
end

function TextField:handleUp(event, mouse, xPos, yPos)
	if self:xPosToCursorPos(xPos) == self.startDrag then
		self:unHighlightAll()
	end
end

function TextField:moveCursorLeft()
	if self.cursorPos > 1 then
		self.cursorPos = self.cursorPos - 1
	elseif self.scrollPos > 1 then
		self:scrollLeft()
	end
end

function TextField:moveCursorRight()
	if self.cursorPos < #self.text - self.scrollPos + 2 then
		if self.cursorPos < self.width then
			self.cursorPos = self.cursorPos + 1
		else
			self:scrollRight()
		end
	end
end

function TextField:scrollLeft()
	if self.scrollPos > 1 then
		self.scrollPos = self.scrollPos - 1
	end
end

function TextField:scrollRight()
	self.scrollPos = self.scrollPos + 1
end

function TextField:xPosToCursorPos(xPos)
	local textEnd = #self.text - self.scrollPos + 1 + 1
	local relativePos = xPos - self.xPos + 1
	
	if  relativePos > textEnd then
		return textEnd
	else
		return math.max(relativePos, 1)
	end
end

function TextField:focus(xPos, yPos)
	self.cursorPos = self:xPosToCursorPos(xPos)
	self.startDrag = self.cursorPos
	self.focused = true
end

function TextField:unFocus()
	self.focused = false
	term.setCursorBlink(false)
end

function TextField:applyTheme(theme)
	self.super:applyTheme(theme)
	
	self.heldBackgroundColour = theme.backgroundColour
	self.heldTextColour = theme.textColour	
	self.highlightedTextColour = theme.highlightedTextColour
	self.highlightedBackgroundColour = theme.highlightedBackgroundColour
end

function TextField:getHilightedPos()
	local startDrag = self.startDrag
	local endDrag = self.endDrag
	
	if not (startDrag and endDrag) then
		return
	 end
	 
	 if startDrag > endDrag then
		startDrag, endDrag = endDrag, startDrag
	end
	
	return startDrag, endDrag
end

function TextField:deleteHighlightedChars()
	local startDrag, endDrag = self:getHilightedPos()
	local leftPart
	local rightPart
	
	if not (startDrag and endDrag) then
		return false
	end
	
	if self.endDrag > self.width then
		self:setText("")
		self.scrollPos = 1
	end
	
	leftPart = self.text:sub(1, startDrag + self.scrollPos - 2)
	rightPart = self.text:sub(endDrag + self.scrollPos)
	
	self:setText(leftPart .. rightPart)
	self.cursorPos = startDrag + 1
	
	self:unHighlightAll()
	
	return true
end

function TextField:action()
	--emtpy funtion that can be set for when enter is pressed
end

function TextField:drawHilightedText(buffer, x, y, text)
	if self.startDrag and self.endDrag then
		local startDrag, endDrag = self:getHilightedPos()
		local highlightedText = text:sub(startDrag, endDrag)
		
		buffer:writeStr(x + startDrag - 1, y, highlightedText, self.highlightedTextColour, self.highlightedBackgroundColour)
	end
end

function TextField:draw(buffer)
	local backColour = self.held and self.heldBackgroundColour or self.backgroundColour
	local textColour = self.held and self.heldTextColour or self.textColour
	
	local trimedText
	local x, y, width, height = self:getTextPos()
	
	if self.mask == '' then
		trimedText = self.text:sub(self.scrollPos, self.scrollPos + self.width - 1)
	else
		trimedText = self.mask:rep(#self.text):sub(1, #self.text):sub(self.scrollPos, self.scrollPos + self.width - 1)
	end
	
	if self.focused then 
		term.setCursorPos(self.xPos + self.cursorPos - 1, self.yPos)
		term.setCursorBlink(true)
	end
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour) 
	end
	
	buffer:writeStr(x, y, trimedText, textColour)
	self:drawHilightedText(buffer, x, y, trimedText)
	
	-- buffer:writeStr(x, y+1, tostring(self.cursorPos) .. '  ' .. tostring(self.scrollPos) .. '  ' .. tostring(#self.text) .. '  '
	-- .. tostring(self.startDrag) .. '  ' .. tostring(self.endDrag) .. ' ' .. tostring(self.focused)
	-- , textColour)
end

