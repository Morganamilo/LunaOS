TextField = object.class(GUI.Button)

TextField.focused = false
TextField.cursorPos = 1
TextField.scrollPos = 1


function TextField:init(xPos, yPos, width, text)
	self.super:init(xPos, yPos, width, 1, text)
	
	self:addEventListener("char", self. handleChar)
	self:addEventListener("key", self. handleKey)
	--self:addEventListener("key_up", self. handleKey)
end

function TextField:handleDown(xPos, yPos, mouse)
	if self:isInBounds(xPos, yPos) then
		self:focus(xPos, yPos)
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
			self:setText(self.text .. "\n")
		end
		
		if key == 203 then --left
			self:moveCursorLeft()
		end
		
		if key == 205 then --right
			self:moveCursorRight()
		end
		
		if key == 199 then --home
			self.cursorPos = 1
			self.scrollPos = 1
		end
		
		if key == 207 then --end
			if #self.text < self.width then
				self.cursorPos = #self.text + 1
			else
				self.cursorPos = self.width
				self.scrollPos = #self.text - self.width + 2
			end
		end
		
	end
end

function TextField:handleChar(event, chr)
	if self.focused then
		self:addChar(chr, self.cursorPos + self.scrollPos )
		
		self:moveCursorRight()
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

function TextField:deleteChar(pos)
	if pos == 1 then return end
	
	local leftPart = self.text:sub(1, pos - 2)
	local rightPart = self.text:sub(pos)
	
	self:setText(leftPart .. rightPart)
end

function TextField:addChar(chr, pos)
	if pos == 1 then return end
	
	local leftPart = self.text:sub(1, pos - 2)
	local rightPart = self.text:sub(pos - 1)
	
	self:setText(leftPart .. chr .. rightPart)
end


function TextField:focus(xPos, yPos)
	local textEnd = #self.text - self.scrollPos + 1 + 1
	local relativePos = xPos - self.xPos + 1
	self.focused = true
	
	if  relativePos > textEnd then
		self.cursorPos = textEnd
	else
		self.cursorPos = relativePos
	end
end

function TextField:unFocus()
	self.focused = false
	term.setCursorBlink(false)
end

function TextField:applyTheme(theme)
	self.super:applyTheme(theme)
	
	self.heldBackgroundColour = theme.backgroundColour
	self.heldTextColour = theme.textColour	
end

function TextField:draw(buffer)
	local backColour = self.held and self.heldBackgroundColour or self.backgroundColour
	local textColour = self.held and self.heldTextColour or self.textColour
	
	local trimedText = self.text:sub(self.scrollPos, self.scrollPos + self.width - 1)
	local x, y, width, height = self:getTextPos()
	
	if self.focused then 
		term.setCursorPos(self.xPos + self.cursorPos - 1, self.yPos)
		term.setCursorBlink(true)
	end
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour) 
	end
	
	buffer:writeStr(x, y, trimedText, textColour)
end

