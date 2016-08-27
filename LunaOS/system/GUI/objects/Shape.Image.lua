Image = object.class(GUI.Shape)

function Image:init(xPos, yPos)
	self.super:init(xPos, yPos, 0, 0 )
end

function Image:setImage(image)
	self.image = imageUtils.decodeImage(image)
	self:setSize(image.size[1], image.size[2])
end

function Image:setImageFromFile(file)
	local file = fs.open(file, "rb")
	local image = ""
	
	while true do
		local char = file.read()
		
		if not char then
			break
		end
		
		image = image .. string.char(char)
	end
	
	file.close()
	
	self.image = image
	self:setSize(self.image:byte(1), self.image:byte(2))
end

function Image:draw(buffer)
	buffer:drawImage(self.xPos, self.yPos, self.image)
end