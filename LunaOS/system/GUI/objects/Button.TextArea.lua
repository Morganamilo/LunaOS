TextArea= object.class(GUI.Button)


function TextArea:init(xPos, yPos, width, height, text)
	self.super:init(xPos, yPos, width, 1, text)
	
	self.text = "this is a test of tests"
	self.scrollPos = 1
	self.cursorPos = 1
	self.blinking = false

	self:addEventListener("key", self.handleKey)
	self:addEventListener("char", self.handleChar)
	self:addEventListener("paste", self.handleChar)
	--self:addEventListener("mouse_down", self.handleDown)
	--self:addEventListener("mouse_drag", self.handleDrag)
end