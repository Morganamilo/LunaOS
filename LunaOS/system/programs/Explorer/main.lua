local args = {...}
local _path

--local fileButtons = {}
local mainColour = colourUtils.blits.cyan
local secondaryColour = colourUtils.blits.grey


local theme
local headerTheme

local frame
local header
local adressBar

local rootButton
local homeButton
local upButton
local searchButton
local footer
local fileView
local fileMenu 
local fileView
local fileViewMenu

local setPath
local displayFiles
local handleDirectory
local handleFile
local initComponents
local formatBytes
local fixPath
local default

local buttonPos = 1

local function comparator(_a, _b)
	local a = _a:lower()
	local b = _b:lower()
	
	for n = 1, #a do
		if string.byte(a, n) > string.byte(b, n) then 
			return 1
		end
		
		if string.byte(a, n) < string.byte(b, n) then 
			return -1
		end
		
		if string.byte(_a, n) > string.byte(_b, n) then 
			return 1
		end
		
		if string.byte(_a, n) < string.byte(_b, n) then 
			return -1
		end
	end
	
	if #a > #b then
		return 1
	end
	
	if #a < #b then
		return -1
	end
	
	return 0
end

function fixPath(path)
	if path:find("*") then
		path = fs.find(path)[1] or _path
	end
	
	path = fs.combine(path)
	
	if path == ".." then
		path = ""
	end
	
	return "/" .. path
end

function getFiles(path)
	local files = fs.listFiles(path)
	local dirs = fs.listDirs(path)
	
	tableUtils.sort(files, comparator)
	tableUtils.sort(dirs, comparator)
	
	return tableUtils.combine(dirs, files)
end

function formatBytes(bytes)
	--if you reach an exobyte ill be verry impressed
	local units = {'B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'}
	local unitCount = 1
	
	while bytes > 1024 do
		unitCount = unitCount + 1
		bytes = bytes / 1024
	end
	
	bytes = (mathUtils.round(bytes * 10)/10)
	
	return tostring(bytes) .. units[unitCount]
end

function clear()
	if fileView then
		frame:removeComponent(fileView)
	end
	
	buttonPos = 1
	
	fileView = GUI.ScrollView()
	fileView:setPos(1, 4)
	fileView:setSize(frame.width, frame.height - 4)
	fileView:applyTheme(default)
	fileView.backgroundColour = secondaryColour
	
	frame:addComponent(fileView)
end

function addItem(path, fileName)
	local nameButton = GUI.Button()
	local sizeLabel = GUI.Label()
	local file = fs.combine(path, fileName)
	local text = fileName
	
	if #text > fileView.width - 8 then
		text = text:sub(1, fileView.width - 8) .. "..."
	end
	
	sizeLabel:setPos(fileView.virtualWidth - 4, buttonPos)
	sizeLabel:setSize(5,1)
	sizeLabel:applyTheme(default)
	sizeLabel.backgroundColour = nil
	--sizeLabel:setAlignment("right","top")
	sizeLabel.textColour = colourUtils.blits.lightGrey
	
	if fs.isFile(file) then
		sizeLabel:setText(formatBytes(fs.getSize(file)))
	else
		sizeLabel:setText("Dir")
	end
	
	nameButton:setPos(1, buttonPos)
	nameButton:setSize(fileView.width, 1)
	nameButton:applyTheme(default)
	nameButton:setText(text)
	nameButton.backgroundColour = nil
	nameButton.heldBackgroundColour = colourUtils.blits.lightGrey
	nameButton.onClick = function() setPath(fs.combine(path, fileName)) end
	
	if fs.isFile(fs.combine(path, fileName)) then
		nameButton.textColour = colourUtils.blits.lightGrey
	else
		nameButton.textColour = colourUtils.blits.lightBlue
	end
	
	function nameButton:onRightClick(event, mouse, xPos, yPos)
		local choice = fileMenu:popup(self, xPos, yPos)
		
		if choice == "delete" then
			fs.delete(fs.combine(path, fileName))
		end
	end
	
	fileView:addComponent(nameButton)
	fileView:addComponent(sizeLabel)
	
	buttonPos = buttonPos + 1
end

function displayFiles(path)
	local virtualWidth = frame.width
	local files = getFiles(path)
	
	clear()
	
	if  #files > fileView.height then
			virtualWidth = virtualWidth - 1
	end

	fileView:setVirtualSize(virtualWidth, #files)

	for k, v in pairs(files) do
		addItem(path, v)
	end
end

function setPath(path)
	local startPos, endPos = path:find(".+//")
	if startPos and endPos then
		handleCommand(path:sub(startPos, endPos - 3), path:sub(endPos + 1))
		return
	end
	
	path = fixPath(path)
	
	
	if not fs.hasReadPerm(path) then
		footer:setText("Access Denied")
	elseif fs.isDir(path) then
		handleDirectory(path)
	elseif fs.isFile(path) then
		handleFile(path)
	else
		footer:setText("File or Directory does not exits")
		adressBar:setText(_path)
		return
	end
end

function handleFile(path)
	local PID = kernel.runFile("/rom/programs/edit", nil, nil, nil, path)
	kernel.gotoPID(PID)
end

function handleDirectory(path)
	local total = #fs.list(path)
	local totalFiles = #fs.listFiles(path)
	local totalDirs = total - totalFiles
	local footerText = "Total: " .. total .. ", Files: " .. totalFiles .. ", Directories: " .. totalDirs
	
	adressBar:setText(path)
	displayFiles(path, getFiles(path))
	footer:setText(footerText)
	
	_path = path
end

function initComponents()
	local HeaderTheme = object.class(GUI.Theme)
	default = GUI.Theme()
	
	HeaderTheme.textColour = mainColour
	HeaderTheme.backgroundColour = secondaryColour
	HeaderTheme.heldTextColour = colourUtils.blits.white

	theme = GUI.Theme()
	headerTheme = HeaderTheme()

	frame = GUI.Frame(term.current())
	header = GUI.Shape()
	adressBar = GUI.TextField()

	rootButton = GUI.Button()
	homeButton = GUI.Button()
	upButton = GUI.Button()
	searchButton = GUI.Button()
	
	footer	= GUI.Label()
	fileView = GUI.View()
	fileMenu = GUI.Menu()
	fileView= GUI.View()
	
	frame:applyTheme(default)
	header:applyTheme(default)
	footer:applyTheme(default)
	
	adressBar:applyTheme(headerTheme)
	rootButton:applyTheme(headerTheme)
	homeButton:applyTheme(headerTheme)
	upButton:applyTheme(headerTheme)
	searchButton:applyTheme(headerTheme)
	fileMenu:applyTheme(headerTheme)
	
	header:setPos(1, 1)
	header:setSize(frame.width, 3)
	
	rootButton:setPos(2, 2)
	rootButton:setSize(3,1)
	rootButton:setText(" /")
	
	homeButton:setPos(6, 2)
	homeButton:setSize(3,1)
	homeButton:setText(" H")
	
	upButton:setPos(10, 2)
	upButton:setSize(3,1)
	upButton:setText(" ^")
	
	adressBar:setPos(15, 2)
	adressBar:setSize(frame.width - 17)
	
	searchButton:setPos(adressBar.xPos + adressBar.width + 1, 2)
	searchButton:setSize(1,1)
	searchButton:setText("?")
	
	footer:setPos(1, frame.height)
	footer:setSize(frame.width, 1)
	footer.backgroundColour = mainColour
	footer.textColour = colourUtils.blits.white

	header.backgroundColour = mainColour
	adressBar.textColour = mainColour
	
	adressBar.onEnter = function() setPath(adressBar.text) end
	
	upButton.onClick = function() setPath(fs.getDir(_path)) end
	rootButton.onClick = function() setPath("/") end
	homeButton.onClick = function() setPath("LunaOS/home") end
	
	fileMenu:addItem("Open", "open")
	fileMenu:addItem("Open With...", "openWith")
	fileMenu:addSeparator("-")
	fileMenu:addItem("Cut", "cut")
	fileMenu:addItem("Copy", "copy")
	fileMenu:addItem("Paste", "paste")
	fileMenu:addItem("Delete", "delete")
	fileMenu:setEnabled("paste", false)
	
	frame:addComponent(header)
	frame:addComponent(adressBar)
	frame:addComponent(rootButton)
	frame:addComponent(homeButton)
	frame:addComponent(upButton)
	frame:addComponent(footer)
	frame:addComponent(searchButton)
end

function handleCommand(command, data)
	if command == "search" then
		setPath("*" .. data .. "*")
	end
end

initComponents()
setPath(args[1] or "/")

frame:mainLoop()