local hexToNum = {["-"] = 255, ["0"] = 0, ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["a"] = 10, ["b"] = 11, ["c"] = 12, ["d"] = 13, ["e"] = 14, ["f"] = 15}
local numToHex = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"}
numToHex[0] = "0"
numToHex[255] = "-"

function encodeImage(image) 
	local x = image.size[1]
	local y = image.size[2]   
	local encodedImage = tostring(string.char(image.size[1])) .. tostring(string.char(image.size[2])) 
	
	for n = 1, x * y do
		local text = image.text[n] or " "
		local textColour = hexToNum[image.textColour[n]] or 0
		local colour = hexToNum[image.colour[n]] or 0
		
		encodedImage = encodedImage .. text .. string.char(textColour) .. string.char(colour)
	end
	
	return encodedImage
end

function decodeImage(image)
	local decodeImage = {size = {}, text = {}, textColour = {}, colour = {}}
	
	decodeImage.size[1] = string.byte(image:sub(1,1)) 
	decodeImage.size[2] = string.byte(image:sub(2,2)) 
	
	for n = 3, #image, 3 do
		local text = image:sub(n,n)
		local textColour = string.byte(image, n + 1)
		local colour = string.byte(image, n + 2)
		local l = #decodeImage.text + 1
		
		decodeImage.text[l] = text
		decodeImage.textColour[l] = numToHex[textColour]
		decodeImage.colour[l] = numToHex[colour]
	end
	
	return decodeImage
end

function decodeFile(path)
	local file = fs.open(path, "r")
	local image = file.readAll()
	file.close()
	
	return decodeImage(image)
end

function encodeToFile(path, image)
	local file = fs.open(path, "w")
	file.write(encodeImage(image))
	file.close()
end
	