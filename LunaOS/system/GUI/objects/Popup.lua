Popup = object.class()

function Popup.static.popup(frame, view, closeAfterEvent)	
	while view.active do
		frame:drawInternal()
		view:draw(frame.buffer)
		
		frame.buffer:drawLine(view.xPos + 1, view.yPos + view.height, view.width,  colourUtils.blits.grey)
		frame.buffer:drawVLine(view.xPos + view.width, view.yPos + 1, view.height - 1, colourUtils.blits.grey)
	
		frame.buffer:draw()
	
		local event = {coroutine.yield()}
		view:handleEvent(event)
		
		if closeAfterEvent then
			if (event[1] == "mouse_click" or event[1] == "mouse_scroll") and not view:isInBounds(event[3], event[4]) then
				return nil
			end
		end
	
	end
	
	return view.result
end

function Popup.static.dialog(v, title, text, ...)
	local frame = v:getFrame()
	local view = GUI.View()
	local theme = GUI.Theme()
	
	local width = math.floor(frame.width / 1.5)
	local lines = #textUtils.wrap(text, width, math.floor(frame.height / 2))
	
	view:setSize(width, lines + 5)
	view:setPos(math.floor(frame.width/2 - view.width/2), math.floor(frame.height/2 - view.height/2))
	
	local topBar = GUI.Label(1,1, view.width - 1, 1)
	local exitButton = GUI.Button(view.width, 1, 1, 1, "x")
	local mainText = GUI.Label(2, 3, view.width - 2, lines, text)
	
	
	topBar:setText(title)
	
	topBar:applyTheme(theme)
	exitButton:applyTheme(theme)
	mainText:applyTheme(theme)
	
	view.backgroundColour = colourUtils.blits.white
	topBar.backgroundColour = colourUtils.blits.grey
	topBar.textColour = colourUtils.blits.lightGrey
	mainText.backgroundColour = colourUtils.blits.white
	mainText.textColour = colourUtils.blits.lightGrey
	
	topBar:setAlignment("center", "top")
	mainText:setAlignment("left", "top")
	
	exitButton.textColour = colourUtils.blits.red
	exitButton.backgroundColour = colourUtils.blits.grey
	exitButton.heldBackgroundColour = colourUtils.blits.grey

	GUI.Popup.makeButtons(view, arg)
	view:addComponent(topBar)
	view:addComponent(exitButton)
	view:addComponent(mainText)

	function exitButton:onClick()
		view.active = false
		view.result = 0
	end
	
	return GUI.Popup.popup(frame, view)
end

function Popup.static.yesNo(frame, title, text)
	return Popup.static.dialog(frame, title, text, "Yes", "No")
end

function Popup.static.ok(frame, title, text)
	return Popup.static.dialog(frame, title, text, "okay")
end

function Popup.static.makeButtons(view, texts)
	local buttons = {}
	local ButtonTheme = object.class(GUI.Theme)
	local buttonTheme
	local lastPos = view.width
	
	ButtonTheme.backgroundColour = colourUtils.blits.grey
	ButtonTheme.textColour = colourUtils.blits.lightGrey
	
	buttonTheme = ButtonTheme()
	
	for k, text in ipairs(texts) do
		local button = GUI.Button()
		button:setSize(#text + 2, 1)
		button:setText(text)
		button:setAlignment("center", "top")
		button:applyTheme(buttonTheme)
		
		function button:onClick()
			view.active = false
			view.result = k
		end
		
		buttons[k] = button
		
	end
	
	for n = #buttons, 1, -1  do
		local button = buttons[n]
		
		button:setPos(lastPos - button.width, view.height - 1)
		lastPos = button.xPos - 1
		view:addComponent(button)
	end
end
