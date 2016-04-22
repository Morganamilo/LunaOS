Frame = object.class()

Frame.nonStatic.views = {}

function Frame:init(window)
	self.window = window
end

function Frame:handleMainLoop()

end

function Frame:addView(view, name)
	self.views[name] = view
	view:setTerm(self.window)
end

function Frame:removeView()

end

function Frame:gotoView(view, dontClear)

end