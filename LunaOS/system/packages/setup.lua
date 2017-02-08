if not kernel.setSU(true) then
	error("Can not get SuperUser")
end

kernel.setFullscreen(true)

local systemPath = lunaOS.getProp("systemPath")
local systemDataPath = lunaOS.getProp("systemDataPath")
local version = lunaOS.getProp("version")

local bannerLabels = {}

local frame
local default
local pageHanlder
local banner
local bannerText
local welcome
local logo
local smallLogo
local labelText
local labelTextField
local labelCheckBox
local labelCheckBoxText
local userText
local passwordText
local passwordConfirmText
local passwordAlert
local timezoneList
local timezoneLabel
local doneText
local rebootButton

local backButton
local nextButton


local pages = {"Welcome", "Label", "Password", "Time Zone", "Done"}
local currentPage = 1

local function setup()
	if not labelCheckBox.selected then
		os.setComputerLabel(labelTextField.text)
	end

	password.setPassword(passwordText.text)

	local file = fs.open(fs.combine(systemDataPath, "timezone"), "w")
	file.write(timezoneList:getSelectedEntry())
	file.close()
	fs.open(fs.combine(systemDataPath, "setupdone"), "w").close()
end

local function initComponents()
	--calculate where to place the windows
	local xSize, ySize = term.getSize()
	local views = {}


	local FRAME_SIZE_X = xSize
	local FRAME_SIZE_Y = ySize
	local FRAME_POS_X = 1
	local FRAME_POS_Y = 1

	local BANNER_SIZE_X = FRAME_SIZE_X
	local BANNER_SIZE_Y = 3
	local BANNER_POS_X = 1
	local BANNER_POS_Y = 1

	local VIEW_SIZE_X = FRAME_SIZE_X
	local VIEW_SIZE_Y = FRAME_SIZE_Y - BANNER_SIZE_Y
	local VIEW_POS_X = BANNER_POS_X
	local VIEW_POS_Y = BANNER_POS_Y + BANNER_SIZE_Y

	local CURRENT_PAGE_COLOUR = colourUtils.blits.blue
	local BEFORE_PAGE_COLOUR = colourUtils.blits.cyan
	local AFTER_PAGE_COLOUR = colourUtils.blits.lightGrey

	local BUTTON_BACKGROUND_COLOUR = colourUtils.blits.blue
	local BUTTON_TEXT_COLOUR = colourUtils.blits.white

	local BANNER_TEXT_COLOUR = colourUtils.blits.white
	local BANNER_BACKGROUND_COLOUR = colourUtils.blits.grey

	local VIEW_BACKGROUD_COLOUR = colourUtils.blits.lightBlue
	local VIEW_TEXT_COLOUR = colourUtils.blits.black

	local setupText = "First Time Setup"
	local welcomeText = "Welcoome To LunaOS v" .. version .. "\n\nBefore we begin we need to configure a few things to ensure everything is setup correctly."

	local function nextPage()
		if pages[currentPage] == "Password" then
			if passwordText.text ~= passwordConfirmText.text then
				passwordAlert.visible = true
				return
			else
				passwordAlert.visible = false
			end
		end

		if pages[currentPage] == "Time Zone" then
			if not timezoneList.selected then
				timezoneAlert.visible = true
				return
			else
				timezoneAlert.visible = false
			end
		end

		if currentPage < #pages then
			currentPage = currentPage + 1
			pageHanlder:gotoView(currentPage)
			bannerLabels[currentPage].backgroundColour = CURRENT_PAGE_COLOUR

			if currentPage > 1 then
				bannerLabels[currentPage - 1].backgroundColour = BEFORE_PAGE_COLOUR
			end
		end
	end

	local function backPage()
		if currentPage > 1 then
			currentPage = currentPage - 1
			pageHanlder:gotoView(currentPage)
			bannerLabels[currentPage].backgroundColour = CURRENT_PAGE_COLOUR

			if currentPage < #pages then
				bannerLabels[currentPage + 1].backgroundColour = AFTER_PAGE_COLOUR
			end
		end
	end

	--create the objects
	frame = GUI.Frame(term.current(), true)
	banner = GUI.View()
	pageHanlder = GUI.MultiView()
	default = GUI.Theme()
	logo = GUI.Image()
	smallLogo = GUI.Image()
	bannerText = GUI.Label()
	welcome = GUI.Label()
	userText = GUI.Label()
	labelText = GUI.Label()
	labelTextField = GUI.TextField()
	labelCheckBox = GUI.RadioButton()
	labelCheckBoxText = GUI.Label()
	passwordText = GUI.TextField()
	passwordConfirmText = GUI.TextField()
	passwordAlert = GUI.Label()
	timezoneList = GUI.List()
	timezoneLabel = GUI.Label()
	timezoneAlert = GUI.Label()
	doneText = GUI.Label()

	backButton = GUI.Button()
	nextButton = GUI.Button()
	rebootButton = GUI.Button()

	pageHanlder:setPos(VIEW_POS_X, VIEW_POS_Y)
	pageHanlder:setSize(VIEW_SIZE_X, VIEW_SIZE_Y)

	--make the views and banner labels
	for k,v in pairs(pages) do
		local view = GUI.View()
		local label = GUI.Label()

		view:applyTheme(default)
		view:setPos(VIEW_POS_X, VIEW_POS_Y)
		view:setSize(VIEW_SIZE_X, VIEW_SIZE_Y)
		view.backgroundColour = VIEW_BACKGROUD_COLOUR
		pageHanlder:addView(view, k)
		views[v] = view

		label:setPos(18 + k*4 ,2)
		label:setSize(2, 1)
		label:applyTheme(default)
		label.backgroundColour = colourUtils.blits.lightGrey
		banner:addComponent(label)
		bannerLabels[#bannerLabels + 1] = label
	end

	bannerLabels[currentPage].backgroundColour = CURRENT_PAGE_COLOUR


	--apply themes
	frame:applyTheme(default)
	banner:applyTheme(default)
	--bannerText:applyTheme(default)
	--welcome:applyTheme(default)
	backButton:applyTheme(default)
	nextButton:applyTheme(default)
	rebootButton:applyTheme(default)
	labelTextField:applyTheme(default)
	labelCheckBox:applyTheme(default)
	passwordText:applyTheme(default)
	passwordConfirmText:applyTheme(default)
	timezoneList:applyTheme(default)


	--configure the objects
	banner:setPos(BANNER_POS_X, BANNER_POS_Y)
	banner:setSize(BANNER_SIZE_X, BANNER_SIZE_Y)

	bannerText:setPos(2,2)
	bannerText:setText(setupText)
	bannerText:setSize(#bannerText.text, 1)

	backButton:setPos(2, VIEW_SIZE_Y - 1)
	backButton:setSize(8, 1)
	backButton:setText("Back")
	backButton:setAlignment("center", "center")
	backButton.onClick = backPage

	labelText:setPos(2,2)
	labelText:setSize(VIEW_SIZE_X - 3, 2)
	labelText:setText("Enter a new label for this computer.")
	labelText.textColour = VIEW_TEXT_COLOUR

	labelTextField:setPos(6,5)
	labelTextField:setSize(VIEW_SIZE_X - 11)
	labelTextField:setText("LunaOS")

	labelCheckBox:setPos(6,7)

	labelCheckBoxText:setPos(8, 7)
	labelCheckBoxText:setSize(20, 1)
	labelCheckBoxText:setText("Don't set label")

	userText:setPos(2,2)
	userText:setSize(VIEW_SIZE_X - 3 ,2)
	userText:setText("Create a password for this computer. If you dont want a password leave it blank")
	userText.textColour = VIEW_TEXT_COLOUR

	passwordText:setPos(6, 9)
	passwordText:setSize(VIEW_SIZE_X - 11)
	passwordText.hint = "Password"
	passwordText.mask = "*"
	passwordText.hintColour = colourUtils.blits.grey

	passwordConfirmText:setPos(6, 11)
	passwordConfirmText:setSize(VIEW_SIZE_X - 11)
	passwordConfirmText.hint = "Confirm Password"
	passwordConfirmText.mask = "*"
	passwordConfirmText.hintColour = colourUtils.blits.grey

	passwordAlert:setText("Passwords do not match.")
	passwordAlert:setSize(#passwordAlert.text, 1)
	passwordAlert:setPos(math.floor(VIEW_SIZE_X/2 - passwordAlert.width/2), 13)
	passwordAlert.textColour = colourUtils.blits.red
	passwordAlert.visible = false

	timezoneList:setPos(VIEW_SIZE_X - 24,2)
	timezoneList:setSize(24,11)
	timezoneList.scrollbar.barColour = colourUtils.blits.grey

	timezoneLabel:setPos(2, 2)
	timezoneLabel:setSize(20, 10)
	timezoneLabel:setText("Please set your timezone.\n\nThis will be used to sync the real time clock.")
	timezoneLabel.textColour = VIEW_TEXT_COLOUR

	timezoneAlert:setText("Please set a timezone.")
	timezoneAlert:setSize(#timezoneAlert.text, 1)
	timezoneAlert:setPos(2, VIEW_SIZE_Y - 3)
	timezoneAlert.textColour = colourUtils.blits.red
	timezoneAlert.visible = false

	doneText:setText("Finished setting up LunaOS.\n\nClick reboot to apply settings and start using LunaOS")
	doneText:setPos(2,2)
	doneText:setSize(VIEW_SIZE_X - 3, 3)
	doneText.textColour = VIEW_TEXT_COLOUR

	rebootButton:setPos(VIEW_SIZE_X - 8, VIEW_SIZE_Y - 1)
	rebootButton:setSize(8, 1)
	rebootButton:setText("Reboot")
	rebootButton:setAlignment("center", "center")
	rebootButton.onClick = nextPage

	function rebootButton:onClick()
		setup()
		os.reboot()
	end


	local file = fs.open(fs.combine(systemPath, "timezones"), "r")
	local data = file.readLine()
	while data do
		timezoneList:addEntry(data)
		data = file.readLine()
	end

	file.close()

	nextButton:setPos(VIEW_SIZE_X - 8, VIEW_SIZE_Y - 1)
	nextButton:setSize(8, 1)
	nextButton:setText("Next")
	nextButton:setAlignment("center", "center")
	nextButton.onClick = nextPage

	logo:setImageFromFile(fs.combine(systemPath, "biglogo.img"))
	logo:setPos(VIEW_SIZE_X - 13, 3)

	smallLogo:setImageFromFile(fs.combine(systemPath, "logo.img"))
	smallLogo:setPos(math.floor(VIEW_SIZE_X/2 - smallLogo.width/2), 5)

	welcome:setSize(33,10)
	welcome:setPos(2,3)
	welcome:setText(welcomeText)

	--custom colours
	banner.backgroundColour = BANNER_BACKGROUND_COLOUR
	bannerText.textColour = BANNER_TEXT_COLOUR
	welcome.textColour = VIEW_TEXT_COLOUR

	backButton.textColour = BUTTON_TEXT_COLOUR
	backButton.backgroundColour = BUTTON_BACKGROUND_COLOUR
	nextButton.textColour = BUTTON_TEXT_COLOUR
	nextButton.backgroundColour = BUTTON_BACKGROUND_COLOUR
	rebootButton.textColour = BUTTON_TEXT_COLOUR
	rebootButton.backgroundColour = BUTTON_BACKGROUND_COLOUR

	labelCheckBox.defaultColour = colourUtils.blits.lightGrey
	labelCheckBox.selectedColour = colourUtils.blits.blue
	labelCheckBoxText.textColour = VIEW_TEXT_COLOUR

	--add the stuff to the frame
	frame:addComponent(banner)
	frame:addComponent(pageHanlder)
	banner:addComponent(bannerText)

	views["Welcome"]:addComponent(welcome)
	views["Welcome"]:addComponent(logo)
	views["Welcome"]:addComponent(nextButton)

	views["Label"]:addComponent(backButton)
	views["Label"]:addComponent(nextButton)
	views["Label"]:addComponent(labelText)
	views["Label"]:addComponent(labelTextField)
	views["Label"]:addComponent(labelCheckBox)
	views["Label"]:addComponent(labelCheckBoxText)

	views["Password"]:addComponent(backButton)
	views["Password"]:addComponent(nextButton)
	views["Password"]:addComponent(userText)
	views["Password"]:addComponent(passwordText)
	views["Password"]:addComponent(passwordConfirmText)
	views["Password"]:addComponent(passwordAlert)
	views["Password"]:addComponent(smallLogo)

	views["Time Zone"]:addComponent(backButton)
	views["Time Zone"]:addComponent(nextButton)
	views["Time Zone"]:addComponent(timezoneList)
	views["Time Zone"]:addComponent(timezoneLabel)
	views["Time Zone"]:addComponent(timezoneAlert)

	views["Done"]:addComponent(backButton)
	views["Done"]:addComponent(doneText)
	views["Done"]:addComponent(rebootButton)

	pageHanlder:gotoView(currentPage)
end




initComponents()
frame:mainLoop()
