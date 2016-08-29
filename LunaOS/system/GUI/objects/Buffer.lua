Buffer = object.class()

local toBlit = colourUtils.colourToBlit
local div = mathUtils.div

function Buffer:init(term, xPos, yPos, xSize, ySize, colour)
	self.term = term
	
	self.pixelBuffer = {}
	self.textBuffer = {}
	self.textColourBuffer = {}
	self.changed = {}
	
	self.xSize = xSize
	self.ySize = ySize
	
	self.xPos = xPos
	self.yPos = yPos
		
	self.size = xSize * ySize
	
	if colour then self:clear(colour) end
end

---------------------------------------------------------------------------------------------------
--drawing
---------------------------------------------------------------------------------------------------

--draws a pixel using a given table index
function Buffer:drawPixelIndexRaw(pos, colour)
	self.pixelBuffer[pos] = colour
	self.textBuffer[pos] = " "
end

function Buffer:drawPixelIndex(pos, colour)
	if pos < 1 or pos > self.size then return end
	colour = toBlit(colour)
end

--draws a pixel given an X, Y coord
function Buffer:drawPixel(xPos, yPos, colour)
	--only draw if the position is in the range
	if not self:isInBounds(xPos, yPos) then return end
	local pos = self:XYToIndex(xPos, yPos)

	self:drawPixelIndexRaw(pos, colour)
	self.changed[yPos] = true
end

--draws a line with a given length at a given X, Y coord
function Buffer:drawLine(xPos, yPos, width, colour) 
	--only draw if the position is in the range
	if yPos < 1 or yPos > self.ySize or xPos > self.xSize then return end
	colour = toBlit(colour)
	
	--ajust the line so that if part off the buffer then only draw the part that is on the buffer
	if xPos < 1 then
		width  = width + xPos - 1
		xPos = 1
	end
	
	local startPos = self:XYToIndex(xPos, yPos)
	local endPos = math.min(width - 1, self.xSize - xPos) + startPos
	
	for n = startPos, endPos do
		self:drawPixelIndexRaw(n, colour)
	end
	
	self.changed[yPos] = true
end

function Buffer:drawVLine(xPos, yPos, width, colour)
	--only draw if the position is in the range
	if xPos < 1 or xPos > self.xSize or yPos > self.ySize then return end
	colour = toBlit(colour)
	
	--ajust the line so that if part off the buffer then only draw the part that is on the buffer
	if yPos < 1 then
		yPos = 1
		width = width + (yPos - 1)
	end
	
	local startPos = self:XYToIndex(xPos, yPos)
	local endPos = math.min(width - 1, self.ySize - yPos) + start
	
	for y = startPos, endPos, self.xSize do
		self:drawPixelIndexRaw(start + (y * self.xSize), colour)
	end
end

function Buffer:drawBox(xPos, yPos, width, height, colour)
	for n = 0, height - 1 do
		self:drawLine(xPos, yPos + n, width, colour)
	end
end

function Buffer:drawOutline(xPos, yPos, width, height, colour)
	self:drawLine(xPos, yPos , width, colour)
	self:drawLine(xPos, yPos + height - 1, width, colour)
	
	self:drawVLine(xPos, yPos + 1 , height - 2, colour)
	self:drawVLine(xPos + width - 1, yPos + 1 , height - 2, colour) 
end

function Buffer:drawThickOutline(xPos, yPos, width, height, thickness, colour)
	for n = 0, thickness - 1 do
		self:drawOutline(xPos + n, yPos + n, width - n*2, height - n*2, colour)
	end
end

--draws a function that takes a x and a y coord and returns true or false
--deciding wether it should draw or not
function Buffer:drawFunction(xPos, yPos, width, height, startX, startY, f, colour)
	for y = 1, height do
		for x = 1, width do
			if f(x - startX, y - startY) then
				self:drawPixel(xPos + x - 1, yPos + y - 1, colour)
			end
		end
		
		self.changed[y] = true
	end
end

function Buffer:drawFunction2(xPos, yPos, width, height, f, colour)
	--for y = 1, height do
	local last
	
		for x = 1, width do
			local res = mathUtils.round(f(x))
			local next =  f(x+1)
			if res >= 1 and res <= self.ySize or next >= 1 and next <= self.ySize then
				
			
				if next > res then
				self:drawVLine(x, res, next - res, colour)
				else
				self:drawVLine(x + 1, next, res - next, colour)
				end
				
				self:drawPixel(x,res, 1024)
			end
		--end
		
		--self.changed[xPos + y - 1] = true
	end
end


local function elipseFunction(x, y) 
	x = x- (width + 1) /2
	y = y- (height + 1)/2

	return mathUtils.round(math.sqrt((x*x)/(width*width) + (y*y)/(height*height))) < 1
end

--draws an elipse
function Buffer:drawEllipse(xPos, yPos, width, height, colour)
	self:drawFunction(xPos, yPos, width, height, 0, 0, elipseFunction, colour)
end

--draws another buffer to this buffer
--the buffer passed gets drawn ontop of the self buffer
function Buffer:drawBuffer(buffer, xPos, yPos, width, height)
	local text = buffer.textBuffer
	local pixel = buffer.pixelBuffer
	local textColour = buffer.textColourBuffer
	
	local selfText = self.textBuffer
	local selfPixel = self.pixelBuffer
	local selfTextColour = self.textColourBuffer
	
	local bufferXPos = buffer.xPos
	local bufferYPos = buffer.yPos
	
	
	yPos = yPos or 1
	xPos = xPos or 1
	
	width = width or buffer.xSize
	height = height or buffer.ySize
	
	if  buffer.yPos < 1 then
		height = height + bufferYPos - 1
		yPos = -bufferYPos + yPos + 1
		bufferYPos = 1
	end
	
	if  buffer.xPos < 1 then
		width = width + bufferXPos - 1
		xPos = -bufferXPos + xPos + 1
		bufferXPos = 1
	end
	
	width = math.min(buffer.xSize, width)
	height = math.min(buffer.ySize, height)
	
	local yEnd = math.min(self.ySize - bufferYPos , height -1) 
	local xEnd = math.min(self.xSize - bufferXPos, width -1) 
		
	for y = 0, yEnd  do
		local selfBufferPos = self:XYToIndex(bufferXPos, bufferYPos + y)
		local bufferPos = buffer:XYToIndex(xPos, yPos + y)
		
		for x = 0, xEnd do
			local t =  text[bufferPos]
			local p = pixel[bufferPos]
			local tc = textColour[bufferPos]
		
			if t ~= " "  or p ~= "-" then selfText[selfBufferPos] =  t end
			if p ~= "-" then selfPixel[selfBufferPos] = p end
			if  (t ~= " "  or p ~= "-")  and tc ~= "-" then selfTextColour[selfBufferPos] = tc end 
			
			selfBufferPos = selfBufferPos + 1
			bufferPos = bufferPos + 1
		end
	end
end

function Buffer:drawImage(xPos, yPos, image)
	if xPos > self.xSize or yPos > self.ySize then return end

	image = imageUtils.decodeImage(image)
	
	local xSize = image.size[1]
	local ySize = image.size[2]
	
	local buffer = self.pixelBuffer
	local textColour = self.textColourBuffer
	local text = self.textBuffer
	
	local imageBuffer = image.colour
	local imageTextColour = image.textColour
	local imageText = image.text
	
	local index = self:XYToIndex(xPos, yPos)
	local shapeIndex = 1
	
	for y = math.max(0, -yPos + 1), math.min(ySize - 1, self.ySize - yPos)  do
		for x  = math.max(0, -xPos + 1), math.min(xSize - 1, self.xSize - xPos) do
			local currentIndex = index + x
			local currentShapeIndex = shapeIndex + x
			
			local b = imageBuffer[currentShapeIndex]
			local tc = imageTextColour[currentShapeIndex]
			local t = imageText[currentShapeIndex]
			
			if b ~= "-" then buffer[currentIndex] = b end
			if (t ~= " " or b ~= "-") and tc ~= "-" then textColour[currentIndex] = tc end
			if t ~= " " or b ~= "-" then text[currentIndex] = t end
		end
		
		index = index + self.xSize
		shapeIndex = shapeIndex + xSize
	end
end

--draws the buffer to the screen
function Buffer:draw(ignoreChanged)
	local buffer = self.pixelBuffer
	local textColourBuffer = self.textColourBuffer
	local textBuffer = self.textBuffer
	
	local term = self.term
	local whitespace = string.rep(" ", self.xSize)
	
	for y = 1, self.ySize do
		if ignoreChanged or self.changed[y] then
			--get the start and end index of each line 
			local start = self:XYToIndex(1, y)
			local finish = start + self.xSize - 1
			
			local pixelColours = table.concat({unpack(buffer, start, finish)})
			local textColours =  table.concat({unpack(textColourBuffer, start, finish)})
			local text = table.concat({unpack(textBuffer, start, finish)})
		
			term.setCursorPos(self.xPos, y + self.yPos - 1)
			term.blit(text, textColours, pixelColours) 
		end
	end
	
	self.changed = {}
end

function Buffer:clear(colour)
	colour = toBlit(colour)
	
	local selfText = self.textBuffer
	local selfPixel = self.pixelBuffer
	local selfTextColour = self.textColourBuffer
	
	for n = 1, self.size do
		selfPixel[n] = colour
		selfText[n] = " "
		selfTextColour[n] = colour
	end
	
	self:changeAll()
end

function Buffer:clearArea(colour, xPos, yPos, xSize, ySize)
	if xPos > self.xSize or yPos  > self.ySize then return end
	
	self.pixelBuffer = {}
	self.textBuffer = {}
	self.textColourBuffer = {}
	
	local selfText = self.textBuffer
	local selfPixel = self.pixelBuffer
	local selfTextColour = self.textColourBuffer
	local start =  self:XYToIndex(xPos, yPos)
	
	if xPos < 1 then
		xSize  = xSize + xPos - 1
		xPos = 1
	end
	
	if yPos < 1 then
		yPos = 1
		ySize = ySize + (yPos - 1)
	end
	
	for y = yPos, yPos + ySize do
		local pos = start
		self.changed[y] = true
		
		for x = 0, xSize do
			selfPixel[pos] = colour
			selfText[pos] = " "
			selfTextColour[pos] = colour
			
			pos = pos + 1
		end
		
		start = start + self.xSize
	end
	
	self:changeAll()
end


---------------------------------------------------------------------------------------------------
--text
---------------------------------------------------------------------------------------------------

function Buffer:writeCharRaw(pos, c, textColour, textBackgroundColour)
	if pos < 1 or pos > self.size then return end
	textColour = toBlit(textColour)
	textBackgroundColour = toBlit(textBackgroundColour)
	
	self.textBuffer[pos] = c
	if textColour then self.textColourBuffer[pos] = textColour end
	if textBackgroundColour then self.pixelBuffer[pos] = textBackgroundColour end
end

--draws a char to the buffer at a given X, Y coord
--can optionally give a background colour to the text
function Buffer:writeChar(xPos, yPos, c, textColour, textBackgroundColour)
	if not self:isInBounds(xPos, yPos) then return end
	
	local pos = self:XYToIndex(xPos, yPos)
	
	self:writeCharRaw(pos, c, textColour, textBackgroundColour)
	self.changed[yPos] = true
end

--writes a string to the buffer
--can optionally give a background colour to the text
function Buffer:writeStr(xPos, yPos, str, textColour, textBackgroundColour)
	if yPos < 1 or yPos > self.ySize or xPos > self.xSize then return end
	
	if xPos < 1 then
		xPos = 1
		str = str:sub(-xPos + 2)
	end
	
	local start = self:XYToIndex(xPos, yPos)
	
	for n = start, math.min(#str -1, self.xSize - xPos) + start do 
		self:writeCharRaw(n, str:sub(n - start + 1, n - start + 1), textColour, textBackgroundColour)
	end
	
	self.changed[yPos] = true
end

--writes a text box to the buffer with full text wrapping
--allows for text alignment
function Buffer:writeTextBox(xPos, yPos, width, height, str, textColour, backgroundColour, xAlignment, yAlignment)
	local lines = textUtils.wrap(str, width, height)
	local offset = 0
	
	if yAlignment == "down" then
		offset = height - #lines
	elseif yAlignment == "center" then
		offset = math.floor((height - #lines)/2)
	end
		
	if offset > 0 then
		yPos = yPos + offset
		height = height - offset
	end
		
	for y = math.max(1, yPos), math.min(height, #lines) + yPos - 1 do
		local currentLine =  lines[y - yPos + 1]
		local offset = 0
	
		if xAlignment == "right" then
			currentLine = textUtils.trimTrailingSpaces(currentLine)
			offset = width - #currentLine
		elseif xAlignment == "center" then
			offset = math.floor(( 1 + width - #textUtils.trimTrailingSpaces(currentLine))/2)
		end
	
		self:writeStr(xPos + offset, y, currentLine, textColour, backgroundColour)
	end
	
end

---------------------------------------------------------------------------------------------------
--helpers
---------------------------------------------------------------------------------------------------

--takes an index and turns it to an X, Y coord
function Buffer:indexToXY(index)
	local y = div(index, self.xSize)
	local x = index - y*self.xSize
	
	return x,y
end

--takes an X, Y coord and turns it into a table index
function Buffer:XYToIndex(xPos, yPos)
	--if xPos > self.xSize or xPos < 1 or yPos > self.ySize or yPos < 1 then return end
	return (yPos -1) * self.xSize + xPos
end

function Buffer:isInBounds(xPos, yPos)
	return xPos < 1 or yPos < 1 or xPos > self.xSize or yPos > self.ySize 
end

---------------------------------------------------------------------------------------------------
--other functions
---------------------------------------------------------------------------------------------------

function Buffer:setPos(xPos, yPos)
	self.xPos = xPos
	self.yPos = yPos
	self:changeAll()
end

function Buffer:translate(xPos, yPos)
	self.xPos = self.xPos + xPos
	self.yPos = self.yPos + yPos
	self:changeAll()
end


--resizies the buffer and removes any data outside of the new size
function Buffer:resize(width, height, colour)
	colour = toBlit(colour)
	
	local newPixelBuffer = {}
	local newTextColourBuffer = {}
	local newTextBuffer = {}
	
	local index = 1
	
	for y = 1, height do
		for x = 1, width do
			local pos = self:XYToIndex(x, y)
			
			newPixelBuffer[index] = self.pixelBuffer[pos] or colour
			newTextColourBuffer[index] = self.textColourBuffer[pos] or colour
			newTextBuffer[index] = self.textBuffer[pos] or " "
			
			index = index + 1
		end
	end
	
	self.pixelBuffer = newPixelBuffer
	self.textColourBuffer = newTextColourBuffer
	self.textBuffer = newTextBuffer
	
	self.xSize = width
	self.ySize = height
	self.size = width * height
	
	self.changed = {}
	self:changeAll()
end

--mark all lines as changed
function Buffer:changeAll()
	for n = 1, self.ySize do
		self.changed[n] = true
	end
end