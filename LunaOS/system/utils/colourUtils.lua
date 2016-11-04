---The colourUtils API provides function to manipulate both colours and blits
--and converting between the two.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module colourUtils

---This table maps each colour to its corresponding blit.
--@table blitConversions
local blitConversions = {
	[1] = "0",
	[2] = "1",
	[4] = "2",
	[8] = "3",
	[16] = "4",
	[32] ="5",
	[64] = "6",
	[128] = "7",
	[256] = "8",
	[512] = "9",
	[1024]= "a",
	[2048] = "b",
	[4096] = "c",
	[8192] = "d",
	[16384] = "e",
	[32768] = "f",
	["-"] = "-"
}

---This table maps each blit to its corresponding colour.
--@table colourConversions
local colourConversions = {
	["0"] = 1,
	["1"] = 2,
	["2"] = 4,
	["3"] = 8,
	["4"] = 16,
	["5"] = 32,
	["6"] = 64,
	["7"] = 128,
	["8"] = 256,
	["9"] = 512,
	["a"] = 1024,
	["b"] = 2048,
	["c"] = 4096,
	["d"] = 8192,
	["e"] = 16384,
	["f"] = 32768,
	["-"] = "-"
}


---This table maps each colour string to its corresponding blit.
--@table blits
blits = {
	white = "0",
	orange = "1",
	magenta = "2",
	lightBlue = "3",
	yellow = "4",
	lime = "5",
	pink = "6",
	gray = "7",
	grey = "7",
	lightGray = "8",
	lightGrey = "8",
	cyan = "9",
	purple = "a",
	blue = "b",
	brown = "c",
	green = "d",
	red = "e",
	black = "f",
	transparent = "-"
}

---This table maps each colour string to its corresponding colour.
--@table blits
colours = {
	white = 1,
	orange = 2,
	magenta = 4,
	lightBlue = 8,
	yellow = 16,
	lime = 32,
	pink = 64,
	gray = 128,
	grey = 128,
	lightGray = 256,
	lightGrey = 256,
	cyan = 512,
	purple = 1024,
	blue = 2048,
	brown = 4096,
	green = 8192,
	red = 16384,
	black = 32768,
	transparent = "-"
}
		
---This table maps each colour to an inverted version of that colour.
--due to limited number of colours the inverse of one colour may not be the actually inverse but instead the closest colour avaliable. It is also not guaranteed that the inverse of an inverse is equal to the original colour.
--@table invertTable
local invertTable = {
	[colours.white] = colours.black,
	[colours.orange] = colours.blue,
	[colours.magenta] = colours.green,
	[colours.lightBlue] = colours.brown,
	[colours.yellow] = colours.blue,
	[colours.lime] = colours.purple,
	[colours.pink] = colours.green,
	[colours.gray] = colours.lightGray,
	[colours.grey] = colours.lightGray,
	[colours.lightGray] = colours.gray,
	[colours.lightGrey] = colours.gray,
	[colours.cyan] = colours.brown,
	[colours.purple] = colours.lime,
	[colours.blue] = colours.yellow,
	[colours.brown] = colours.lightGrey,
	[colours.green] = colours.purple,
	[colours.red] = colours.cyan,
	[colours.black] = colours,
	["-"] = "-"
}

---This table maps each colour to a lighter version of that colour.
--@table lighterTable
local lighterTable = {
	[colours.white] = colours.lightGray,
	[colours.orange] = colours.yellow,
	[colours.magenta] = colours.pink,
	[colours.lightBlue] = colours.cyan,
	[colours.yellow] = colours.orange,
	[colours.lime] = colours.green,
	[colours.pink] = colours.magenta,
	[colours.gray] = colours.lightGray,
	[colours.grey] = colours.lightGray,
	[colours.lightGray] = colours.gray,
	[colours.lightGrey] = colours.gray,
	[colours.cyan] = colours.lightBlue,
	[colours.purple] = colours.magenta,
	[colours.blue] = colours.lightBlue,
	[colours.brown] = colours.red,
	[colours.green] = colours.lime,
	[colours.red] = colours.orange,
	[colours.black] = colours.gray,
	["-"] = "-"
}

---This table maps each colour to a darker version of that colour.
--@table darkerTable
local darkerTable = {
	[colours.white] = colours.lightGray,
	[colours.orange] = colours.red,
	[colours.magenta] = colours.purple,
	[colours.lightBlue] = colours.cyan,
	[colours.yellow] = colours.orange,
	[colours.lime] = colours.green,
	[colours.pink] = colours.magenta,
	[colours.gray] = colours.black,
	[colours.grey] = colours.black,
	[colours.lightGray] = colours.gray,
	[colours.lightGrey] = colours.gray,
	[colours.cyan] = colours.blue,
	[colours.purple] = colours.gray,
	[colours.blue] = colours.gray,
	[colours.brown] = colours.gray,
	[colours.green] = colours.gray,
	[colours.red] = colours.brown,
	[colours.black] = colours.black,
	["-"] = "-"
}

---Converts a colour to a blit.
--@param colour A colour.
--@return The blit corresponding to the given colour. If a valid blit is entered then return the blit back. Otherwise return nil.
--@usage local red = colourToBlit(colourUtils.colours.red)
function colourToBlit(colour)
	local blit = blitConversions[colour]
	
	if blit then
		return blit
	elseif colourConversions[colour] then
		return colour
	end
end

---Converts a blit to a colour.
--@param b A blit.
--@return The colour corresponding to the given blit. If a valid colour is entered then return the colour back. Otherwise return nil.
--@usage local red = blitToColour(colourUtils.blits.red)
function  blitToColour(b)
	local colour = colourConversions[b]
	
	if colour then
		return colour
	elseif blitConversions[b] then
		return b
	end
end

---Transforms a colour using one of the transform tables (lighterTable, darkerTable, invertTable).
--@param colour The colour to be transformed.
--@param transformTable The table used to apply the transformation.
--@return The transformed version of the given colour.
local function transformColour(colour, transformTable)
	local isBlit = false
	
	if type(colour) == "string" then
		colour = blitToColour(colour)
		isBlit = true
	end
	
	colour = transformTable[colour]
	
	if isBlit then
		colour = colourToBlit(colour)
	end
	
	return colour
end

---Gives a lighter version of a given colour.
--White will always return while as it can not get any lighter.
--@param colour The colour to make lighter.
--@return a lighter version of colour.
--@usage lighterRed = colourUtils.lighter(colourUtils.blits.red)
function lighter(colour)
	return transformColour(colour, lighterTable)
end

---Gives a farker version of a given colour.
--Black will always return black as it can not get any darker.
--@param colour The colour to make darker.
--@return a darker version of colour.
--@usage darkRed = colourUtils.darker(colourUtils.blits.red)
function darker(colour)
	return transformColour(colour, darkerTable)
end

---Gives the inverse of a given colour.
--Inverting a colour twise it not guaranteed to give the original colour.
--@param colour The colour to be inverted.
--@return The inverse of the colour.
--@usage invertRed = colourUtils.invert(colourUtils.blits.red)
function invert(colour)
	return transformColour(colour, invertTable)
end