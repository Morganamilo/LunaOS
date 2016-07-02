Frame = object.class()

Frame.views = {}
Frame.openView = nil
Frame.running = false

function Frame:init(window)
	self.window = window
end

function Frame:addView(view, name)
	self.views[name] = view
	--view:setTerm(self.window)
end

function Frame:removeView(name)
	self.views[name] = nil
end

function Frame:gotoView(name)
	self.openView = name
	
	if self.running then
		self.views[name]:draw()
	end
end

function Frame:stop()
	self.running = false
end

function Frame:mainLoop()
	errorUtils.assert(self.openView, "Error: no open view", 2)

	self.running = true
	self.views[self.openView]:draw()
	
	while self.running do
		local view = self.views[self.openView]
		term.redirect(view.window)
		
		view:handleEvent()
		view:draw()
	end
end
