local blit = {[1] = "0", [2] = "1", [4] = "2", [8] = "3", [16] = "4", [32] ="5", [64] = "6", [128] = "7", [256] = "8", [512]= "9", [1024]= "a", [2048] = "b", [4096] = "c", [8192] = "d", [16384] = "e", [32768] = "f"}


Buffer = object.class()



function Buffer:indexToXY(index)
	local y = mathUtils.div(index, self.xSize)
	local x = index - y*self.xSize
	
	return x,y
	
end

function Buffer:XYToIndex(xPos, yPos)
	return (yPos -1) * self.xSize + xPos
end

function Buffer.static.colourToBlit(colour)
	return blit[colour]
end

function Buffer.static.blitToColour(b)
	return tableUtils.isIn(blit, b)
end

function Buffer:clear(colour)
	if type(colour) == "number" then colour = Buffer.colourToBlit(colour) end
	
	for n = 1, self.size do
		self.pixelBuffer[n] = colour
		self.textBuffer[n] = " "
		self.textColourBuffer[n] = colour
	end
	
	for n = 1, self.ySize do
		self.changed[n] = true
	end
end

function Buffer:drawPixelRaw(pos, colour)
	if type(colour) == "number" then colour = Buffer.colourToBlit(colour) end
	self.pixelBuffer[pos] = colour
	self.textBuffer[pos] = " "
end

function Buffer:drawPixel(xPos, yPos, colour)
	self:drawPixelRaw(self:XYToIndex(xPos, yPos), colour)
	self.changed[yPos] = true
end

function Buffer:drawLine(xPos, yPos, width, colour) -- x,y = term.getSize() a = bufferUtils.Buffer(x,y,"2")          print(mathUtils.time(function() for n = 1,100 do a:draw() end end) )

	local start = self:XYToIndex(xPos, yPos)
	
	for n = start, math.min(width -1, self.xSize - xPos) + start do -- time = os.clock() for n = 1, 100 do a:draw() end print(os.clock() - time)
		self:drawPixelRaw(n, colour)
	end
	
	self.changed[yPos] = true
end

function Buffer:drawVLine(xPos, yPos, width, colour)
	local start = self:XYToIndex(xPos, yPos)
	
	for n = 0, math.min(width -1, self.ySize - yPos) do
		self:drawPixelRaw(start + n * self.xSize, colour)
		self.changed[yPos + n] = true
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
	self:drawVLine(xPos + width - 1, yPos + 1 , height - 2, colour) -- x,y = term.getSize() a = bufferUtils.Buffer(term, x,y,"2")  a:drawEllipse(1,1,11,11,"a")                 a:drawShape(2,2,{5,6,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil,"1",nil})
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
	if type(textColour) == "number" then  textColour = Buffer.colourToBlit(textColour) end
	if type(textBackgroundColour) == "number" then  textBackgroundColour = Buffer.colourToBlit(textColour) end
	
	self.textBuffer[pos] = c
	self.textColourBuffer[pos] = textColour
	self.pixelBuffer[pos] = textBackgroundColour or self.pixelBuffer[pos]
end

function Buffer:writeChar(xPos, yPos, c, textColour, textBackgroundColour)
	self:writeCharRaw(self:XYToIndex(xPos, yPos), c, textColour, textBackgroundColour)
	changed[yPos] = true
end

function Buffer:writeLineStr(xPos, yPos, str, textColour, textBackgroundColour)
	local start = self:XYToIndex(xPos, yPos)
	
	for n = start, math.min(#str -1, self.xSize - xPos) + start do 
		self:writeCharRaw(n, str:sub(n - start + 1, n - start + 1), textColour, textBackgroundColour)
	end
	
	self.changed[yPos] = true
end


function Buffer:writeTextBox(xPos, yPos, width, height, str, textColour)
	local lines = textUtils.wrap(str, width, height)
		
	for y = yPos, yPos + height - 1 do	
			self:writeLineStr(xPos, y, lines[y - yPos + 1], textColour)
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
		
			term.setCursorPos(1, y) --0.6
			term.blit(text, textColours, pixelColours) --0.9
		end
		
	end
	
	self.changed = {}
end

function Buffer:init(term, xSize, ySize, colour)
	self.term = term
	self.pixelBuffer = {}
	self.textBuffer = {}
	self.textColourBuffer = {}
	self.changed = {}
	
	self.xSize = xSize
	self.ySize = ySize
	self.size = xSize * ySize
	
	
	self:clear(colour)
end