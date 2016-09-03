Menu = object.class()

Menu.items = {}

function Menu:addItem(text, name)
	self.items[#self.items + 1] = {text = text, name = name, type = "button"}
	return #self.items
end

function Menu:addSeparator(char)
	self.items[#self.items + 1] = {type = "separator", char = char}
end

function Menu:setPos(frame, view, xPos, yPos)
	if yPos + view.height - 1 > frame.ySize then
		yPos = yPos - view.height + 1
	end
	
	if yPos < 1 then
		local gap = frame.ySize - view.height
		
		yPos = math.floor(gap / 2) + 1
	end
	
	if xPos + view.width - 1 > frame.xSize then
		xPos = xPos - view.width - 1
	end
	
	if xPos < 1 then
		local gap = frame.xSize - view.width
		
		xPos = math.floor(gap / 2) + 1
	end
	
	view:setPos(xPos, yPos)
end

function Menu:popup(v, xPos, yPos)
	local frame = v:getFrame()
	local view = GUI.View()
	local theme = GUI.Theme()
	
	local width = 15
	local height = #self.items
	
	local realXPos, realYPos = v:getAbsolutePos()
	
	xPos = realXPos + xPos
	yPos = realYPos + yPos - 1
	
	for k, v in pairs(self.items) do
		if v.type == "button" then
			width = math.max(width, #v.text + 2)
		end
	end
	
	
	theme.backgroundColour = nil
	theme.textColour = colourUtils.blits.grey
	theme.heldBackgroundColour = colourUtils.blits.blue
	theme.heldTextColour = colourUtils.blits.white
	theme.viewBackgroundColour = colourUtils.blits.white
	
	view:applyTheme(theme)
	
	
	for k, v in pairs(self.items) do
		if v.type == "button" then
			local button = GUI.Button(1, k, width, 1, v.text)
			button:setMargin(0,0,1,1)
			
			function button:onClick()
				view.result = v.name
				view.active = false
			end
			
			button:applyTheme(theme)
			view:addComponent(button)
		end
		
		if v.type == "separator" then
			local label = GUI.Label(1, k, width, 1, string.rep(v.char, width))
	
			label:applyTheme(theme)
			label.textColour = colourUtils.blits.lightGrey
			view:addComponent(label)
		end
	end
	
	view:setSize(width, height)
	self:setPos(frame, view, xPos, yPos)
	
	return GUI.Popup.popup(frame, view, true)
end