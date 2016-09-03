local args = {...}
local path

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
	local virtualWidth = frame.width
	
		
	fileView = GUI.ScrollView()
	fileView:setPos(1, 4)
	fileView:setSize(frame.width, frame.height - 4)
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
		
		if #text > fileView.width - 8 then
			text = text:sub(1, fileView.width - 8) .. "..."
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
		
		function nameButton:onRightClick(event, mouse, xPos, yPos)
			local choice = fileMenu:popup(self, xPos, yPos)
			
			if choice == "delete" then
				fs.delete(fs.combine(p, self.text))
			end
		end
		
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
	local HeaderTheme = object.class(GUI.Theme)
	
	HeaderTheme.textColour = mainColour
	HeaderTheme.backgroundColour = secondaryColour
	HeaderTheme.heldTextColour = mainColour
	
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
	
	adressBar:setPos(18, 2)
	adressBar:setSize(frame.width - 20)
	
	searchButton:setPos(adressBar.xPos + adressBar.width + 1, 2)
	searchButton:setSize(1,1)
	searchButton:setText("?")
	
	footer:setPos(1, frame.height)
	footer:setSize(frame.width, 1)

	header.backgroundColour = mainColour
	adressBar.textColour = colourUtils.blits.lightBlue
	
	adressBar.onEnter = function() setPath(adressBar.text) end
	
	upButton.onClick = function() setPath(fs.getDir(path)) end
	rootButton.onClick = function() setPath("/") end
	homeButton.onClick = function() setPath("LunaOS/home") end
	
	fileMenu:addItem("Open", "open")
	fileMenu:addSeparator("-")
	fileMenu:addItem("Copy", "copy")
	fileMenu:addItem("Paste", "paste")
	fileMenu:addItem("Delete", "delete", false)

	frame:addComponent(header)
	frame:addComponent(adressBar)
	frame:addComponent(rootButton)
	frame:addComponent(homeButton)
	frame:addComponent(upButton)
	frame:addComponent(footer)
	frame:addComponent(searchButton)
end

initComponents()
setPath(args[1] or "/")

frame:mainLoop()