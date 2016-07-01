Buffer = object.class()

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
	
	
	self:clear(colour)
end

function Buffer:indexToXY(index)
	local y = mathUtils.div(index, self.xSize)
	local x = index - y*self.xSize
	
	return x,y
	
end

function Buffer:XYToIndex(xPos, yPos)
	if xPos > self.xSize or xPos < 1 or yPos > self.ySize or yPos < 1 then return end
	return (yPos -1) * self.xSize + xPos
end
function Buffer:restrictPos(xPos, yPos)
	if xPos > self.xSize then xPos = self.xSize end
	if yPos > self.ySize then yPos = self.ySize end
	if xPos < 1 then xPos = 1 end
	if yPos < 1 then yPos = 1 end
	
	return xPos, yPos
end

function Buffer:changeAll()
	for n = 1, self.ySize do
		self.changed[n] = true
	end
end

function Buffer:clear(colour)
	if type(colour) == "number" then colour = colourUtils.colourToBlit(colour) end
	
	for n = 1, self.size do
		self.pixelBuffer[n] = colour
		self.textBuffer[n] = " "
		self.textColourBuffer[n] = colour
	end
	
	self:changeAll()
end

function Buffer:drawPixelRaw(pos, colour)
	if pos < 1 or pos > self.size then return end
	if type(colour) == "number" then colour = colourUtils.colourToBlit(colour) end
	self.pixelBuffer[pos] = colour
	self.textBuffer[pos] = " "
end

function Buffer:drawPixel(xPos, yPos, colour)
	local pos = self:XYToIndex(xPos, yPos)
	if not pos then return end
	
	self:drawPixelRaw(pos, colour)
	self.changed[yPos] = true
end

function Buffer:drawLine(xPos, yPos, width, colour) -- x,y = term.getSize() a = bufferUtils.Buffer(term,1,1,x,y,"2")         print(mathUtils.time(function() for n = 1,100 do a:draw() end end) )
	if yPos < 1 or yPos > self.ySize or xPos > self.xSize then return end --    a:drawBox(3,3,20,10,"9") a:writeTextBox(3,3,20,10,"this is a test it needs a lot of text to actually work properly and show the wraping", "6",nil)
	if xPos < 1 then width = width + (xPos - 1) xPos = 1 end

	local start = self:XYToIndex(xPos, yPos)

	for n = start, math.min(width -1, self.xSize - xPos) + start do -- time = os.clock() for n = 1, 100 do a:draw() end print(os.clock() - time)
		self:drawPixelRaw(n, colour)
	end
	
	self.changed[yPos] = true
end

function Buffer:drawVLine(xPos, yPos, width, colour)
	if xPos < 1 or xPos > self.xSize or yPos > self.ySize then return end
	if yPos < 1 then width = width + (yPos - 1) yPos = 1 end
	
	local start = self:XYToIndex(xPos, yPos)
	
	for y = 0, width - 1 do
		self:drawPixelRaw(start + y * self.xSize, colour)
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
	self:drawVLine(xPos + width - 1, yPos + 1 , height - 2, colour) -- x,y = term.getSize() a = bufferUtils.Buffer(term, 4,2,10,5,"2")  a:drawEllipse(1,1,11,11,"a")                 a:drawShape(2,2,{5,6,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil})
end

function Buffer:drawThickOutline(xPos, yPos, width, height, thickness, colour)
	for n = 0, thickness - 1 do
		self:drawOutline(xPos + n, yPos + n, width - n*2, height - n*2, colour)
	end
end


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

function Buffer:drawEllipse(xPos,yPos, width, height, colour)
	local function f(x, y) 
		x=x- (width + 1) /2
		y=y- (height + 1)/2

		return mathUtils.round(math.sqrt((x*x)/(width*width) + (y*y)/(height*height))) < 1
	end
	
	self:drawFunction(xPos, yPos, width, height, 0, 0, f, colour)
end



function Buffer:drawShape(xPos, yPos, shape)
	local xSize = shape[1]
	local ySize = shape[2]
	local buffer = self.pixelBuffer
	
	local index = self:XYToIndex(xPos, yPos)
	local shapeIndex = 3
	
	for y = 1, ySize do
		for x= 1, xSize do
			if shape[shapeIndex] then
				buffer[index + x] = shape[shapeIndex]
			end
			
			shapeIndex = shapeIndex + 1
		end
		
		index = index + self.xSize
		self.changed[xPos + y - 1] = true
	end
end

function Buffer:writeCharRaw(pos, c, textColour, textBackgroundColour)
	if pos < 1 or pos > self.size then return end
	if type(textColour) == "number" then  textColour = colourUtils.colourToBlit(textColour) end
	if type(textBackgroundColour) == "number" then  textBackgroundColour = colourUtils.colourToBlit(textColour) end 
	
	self.textBuffer[pos] = c
	self.textColourBuffer[pos] = textColour or self.textColourBuffer[pos] or self.pixelBuffer[pos] 
	self.pixelBuffer[pos] = textBackgroundColour or self.pixelBuffer[pos]
end

function Buffer:writeChar(xPos, yPos, c, textColour, textBackgroundColour)
	local pos = self:XYToIndex(xPos, yPos)
	if not pos then return end
	
	self:writeCharRaw(pos, c, textColour, textBackgroundColour)
	self.changed[yPos] = true
end

function Buffer:writeStr(xPos, yPos, str, textColour, textBackgroundColour)
	if yPos < 1 or yPos > self.ySize or xPos > self.xSize then return end
	if xPos < 1 then str = str:sub(-xPos + 2) xPos = 1 end
	
	local start = self:XYToIndex(xPos, yPos)
	
	for n = start, math.min(#str -1, self.xSize - xPos) + start do 
		self:writeCharRaw(n, str:sub(n - start + 1, n - start + 1), textColour, textBackgroundColour)
	end
	
	self.changed[yPos] = true
end


function Buffer:writeTextBox(xPos, yPos, width, height, str, textColour, backgroundColour, xAlignment, yAlignment)
	local lines = textUtils.wrap(str, width, height)
	
	if yAlignment == "down" then
		local offset = height - #lines
		yPos = yPos + offset
		height = height - offset
	elseif yAlignment == "center" then
		local offset = math.floor((height - #lines)/2)
		yPos = yPos + offset
		height = height - offset
	end
		
	for y = yPos, math.min(height, #lines) + yPos - 1 do
		local currentLine =  lines[y - yPos + 1]
		local offset = 0
	
		if xAlignment == "right" then
			currentLine = textUtils.trimTrailingSpaces(currentLine)
			offset = width - #currentLine
		elseif xAlignment == "center" then
			offset = math.floor((width - #textUtils.trimTrailingSpaces(currentLine))/2)
		end
	
		self:writeStr(xPos + offset, y, currentLine, textColour, backgroundColour)
	end
	
end

function Buffer:draw(ignoreChanged)
	local buffer = self.pixelBuffer
	local textColourBuffer = self.textColourBuffer
	local textBuffer = self.textBuffer
	
	local index = 1
	local term = self.term
	local whitespace = string.rep(" ", self.xSize)
	
	for y = 1, self.ySize do
		
		if ignoreChanged or self.changed[y] then
			local start = self:XYToIndex(1, y)
			local finish = start + self.xSize - 1
			
			local pixelColours = table.concat({unpack(buffer, start, finish)})
			local textColours =  table.concat({unpack(textColourBuffer, start, finish)})
			local text = table.concat({unpack(textBuffer, start, finish)})
		
			term.setCursorPos(self.xPos, y + self.yPos - 1) --0.6
			term.blit(text, textColours, pixelColours) --0.9
		end
		
	end
	
	self.changed = {}
end

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

function Buffer:resize(width, height, colour)
	if type(colour) == "number" then colour = colourUtils.colourToBlit(colour) end
	
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