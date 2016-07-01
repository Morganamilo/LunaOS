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
	[32768] = "f"
}

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
	black = "f"
}

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
	black = 32768
}
		
		
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
		[colours.black] = colours.white,
}

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
	[colours.black] = colours.gray
}

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
	[colours.black] = colours.black
}

local highlightTable = {
	[colours.white] = colours.lightGray,
	[colours.orange] = colours.yellow,
	[colours.magenta] = colours.pink,
	[colours.lightBlue] = colours.cyan,
	[colours.yellow] = colours.orange,
	[colours.lime] = colours.green,
	[colours.pink] = colours.magenta,
	[colours.grey] = colours.lightGray,
	[colours.lightGray] = colours.gray,
	[colours.lightGrey] = colours.gray,
	[colours.cyan] = colours.lightBlue,
	[colours.purple] = colours.magenta,
	[colours.blue] = colours.lightBlue,
	[colours.brown] = colours.red,
	[colours.green] = colours.lime,
	[colours.red] = colours.orange,
	[colours.black] = colours.gray
}

function colourToBlit(colour)
	return blitConversions[colour]
end

function  blitToColour(b)
	return tableUtils.indexOf(blitConversions, b)
end

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

function lighter(colour)
	return transformColour(colour, lighterTable)
end

function darker(colour)
	return transformColour(colour, darkerTable)
end

function invert(colour)
	return transformColour(colour, invertTable)
end

function highlight(colour)
	return transformColour(colour, highlightTable)
end