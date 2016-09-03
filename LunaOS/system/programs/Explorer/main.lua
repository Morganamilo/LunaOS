local args = {...}
local path

--local fileButtons = {}

local default = GUI.Theme()
local HeaderTheme = object.class(GUI.Theme)

local frame = GUI.Frame(term.current())
local header = GUI.Shape()
local adressBar = GUI.TextField()

local root = GUI.Button()
local home = GUI.Button()
local up = GUI.Button()
local search = GUI.Button()
local divider = GUI.Shape()
local footer = GUI.Label()
local fileView = GUI.View()
local headerTheme
local fileView

local setPath
local displayFiles
local handleDirectory
local handleFile
local initComponents
local formatBytes
local fixPath

function fixPath(p)
	local path = p
	
	if p:find("*") then
		path = fs.find(p)[1] or ";"
	end
	
	path = fs.combine(path)
	
	if path == ".." then
		path = ""
	end
	
	return "/" .. path
end

function formatBytes(bytes)
	--if you reach an exobyte ill be verry impressed
	local units = {'B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'}
	local unitCount = 1
	
	while bytes > 1024 do
		unitCount = unitCount + 1
		bytes = bytes / 1024
	end
	
	bytes = mathUtils.round(bytes * 10)/10
	
	return tostring(bytes) .. units[unitCount]
end

function displayFiles(p)
	if fileView then
		frame:removeComponent(fileView)
	end
	
	local files = fs.list(p)
	local position =  4
	local virtualWidth = frame.xSize - 15
	
		
	fileView = GUI.ScrollView()
	fileView:setPos(16, 4)
	fileView:setSize(frame.xSize - 15, frame.ySize - 4)
	fileView:applyTheme(default)
	fileView.backgroundColour = colourUtils.blits.yellow
	
	if  #files > fileView.height then
			position = position + 1
			virtualWidth = virtualWidth - 1
	end

	fileView:setVirtualSize(virtualWidth, #files)

	for k, v in pairs(files) do
		local nameButton = GUI.Button()
		local sizeLabel = GUI.Label()
		local file = fs.combine(p, v)
		local text = v
		
		if #text > 28 then
			text = text:sub(1,25) .. "..."
		end
		
		sizeLabel:setPos(fileView.width - position, k)
		sizeLabel:setSize(5,1)
		sizeLabel:applyTheme(default)
		sizeLabel.backgroundColour = nil
		sizeLabel:setAlignment("right","top")
		sizeLabel.textColour = colourUtils.blits.lightGrey
		
		if fs.isFile(file) then
			sizeLabel:setText(formatBytes(fs.getSize(file)))
		else
			sizeLabel:setText("Dir")
		end
		
		nameButton:setPos(1, k)
		nameButton:setSize(fileView.width, 1)
		nameButton:applyTheme(default)
		nameButton:setText(text)
		nameButton.backgroundColour = colourUtils.blits.grey
		nameButton.onClick = function() setPath(fs.combine(p, nameButton.text)) end
		nameButton.textColour = colourUtils.blits.lightBlue
		
		fileView:addComponent(nameButton)
		fileView:addComponent(sizeLabel)
	end
	
	frame:addComponent(fileView)
end

function setPath(p)
	p = fixPath(p)
	
	
	if not fs.hasReadPerm(p) then
		footer:setText("Access Denied")
	elseif fs.isDir(p) then
		handleDirectory(p)
	elseif fs.isFile(p) then
		handleFile(p)
	else
		footer:setText("File or Directory does not exits")
		return
	end
end

function handleFile(p)
	local PID = kernel.runFile("/rom/programs/edit", nil, nil, nil, p)
	kernel.gotoPID(PID)
end

function handleDirectory(p)
	local total = #fs.list(p)
	local totalFiles = #fs.listFiles(p)
	local totalDirs = total - totalFiles
	local footerText = "Total: " .. total .. ", Files: " .. totalFiles .. ", Directories: " .. totalDirs
	
	adressBar:setText(p)
	displayFiles(p)
	footer:setText(footerText)
	
	path = p
end

function initComponents()
	HeaderTheme.textColour = colourUtils.blits.cyan
	HeaderTheme.backgroundColour = colourUtils.blits.grey
	HeaderTheme.heldTextColour = colourUtils.blits.cyan

	headerTheme = HeaderTheme()
	
	header:setPos(1, 1)
	header:setSize(frame.xSize, 3)
	
	root:setPos(2, 2)
	root:setSize(3,1)
	root:setText(" /")
	
	home:setPos(6, 2)
	home:setSize(3,1)
	home:setText(" H")
	
	up:setPos(10, 2)
	up:setSize(3,1)
	up:setText(" ^")
	
	adressBar:setPos(18, 2)
	adressBar:setSize(frame.xSize - 20)
	
	search:setPos(adressBar.xPos + adressBar.width + 1, 2)
	search:setSize(1,1)
	search:setText("?")
	
	divider:setPos(15, 4)
	divider:setSize(1, frame.ySize - 4)
	
	footer:setPos(1, frame.ySize)
	footer:setSize(frame.xSize, 1)
	
	frame:applyTheme(default)
	header:applyTheme(default)
	footer:applyTheme(default)

	adressBar:applyTheme(headerTheme)
	root:applyTheme(headerTheme)
	home:applyTheme(headerTheme)
	up:applyTheme(headerTheme)
	divider:applyTheme(headerTheme)
	search:applyTheme(headerTheme)

	header.backgroundColour = colourUtils.blits.cyan
	divider.backgroundColour = colourUtils.blits.cyan
	adressBar.textColour = colourUtils.blits.lightBlue
	
	adressBar.onEnter = function() setPath(adressBar.text) end
	
	up.onClick = function() setPath(fs.getDir(path)) end
	root.onClick = function() setPath("/") end
	home.onClick = function() setPath("LunaOS/home") end
	

	frame:addComponent(header)
	frame:addComponent(adressBar)
	frame:addComponent(root)
	frame:addComponent(home)
	frame:addComponent(up)
	frame:addComponent(divider)
	frame:addComponent(footer)
	frame:addComponent(search)
end

initComponents()
setPath(args[1] or "/")

frame:mainLoop()