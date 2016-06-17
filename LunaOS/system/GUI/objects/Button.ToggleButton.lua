ToggleButton = object.class(GUI.Button)

ToggleButton.selected = false
ToggleButton.changeColourOnHold = false

function ToggleButton:init(xPos, yPos, width, height, text, backgroundColour, textColour)
	self.super:init(xPos, yPos, width, height, text, backgroundColour, textColour)
	
	
	local function eventHandler(event, mouseButton, xPos, yPos)
		if event == "mouse_click" then
			self:handleDown(xPos, yPos, mouseButton)
		elseif event == "mouse_up" then
			self:handleUp(xPos, yPos, mouseButton)
		elseif event == "mouse_drag" then
			self:handleDrag(xPos, yPos, mouseButton)
		end
	end
	
	self:addEventListener("mouse_click", eventHandler)
	self:addEventListener("mouse_up", eventHandler)
	self:addEventListener("mouse_drag", eventHandler)
	
	self.selectedTextColour = textColour
	self.selectedHeldTextColour = textColour
	
end

function ToggleButton:onClick()
	self.selected = not self.selected
end

function ToggleButton.super.t()
	self:onClick()
end


function ToggleButton:draw(buffer)
	local backColour
	local textColour
	
	local x  = self.xPos + self.leftMargin
	local y = self.yPos + self.upMargin
	local width = self.width - self.leftMargin - self.rightMargin
	local length = self.height - self.downMargin - self.upMargin
	
	
	if self.held and self.changeColourOnHold then
		backColour = self.heldBackgroundColour
		textColour = self.heldTextColour		
	elseif self.selected then
		backColour = self.selectedBackgroundColour
		textColour = self.selectedTextColour
	else
		backColour = self.backgroundColour
		textColour = self.textColour
	end
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos, self.yPos, self.width, self.height, backColour) 
	end
	
	buffer:writeTextBox(x,  y, width, length, tostring(self.selected), textColour, backColour, self.xAlignment, self.yAlignment)
end

--  					v = GUI.View(1) l = GUI.ToggleButton(3,3,20,5,"this is a test for text alignment i hope it works very well", "3", "8") l.selectedBackgroundColour = "2" v:addComponent(l) l:addEventListener("char", function(a) l.str = "a"  if a == "z" then v:close() end end) v:mainLoop()


--Zenix was here
