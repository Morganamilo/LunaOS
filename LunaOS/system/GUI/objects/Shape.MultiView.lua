MultiView = object.class(GUI.Shape)

function MultiView:init(xPos, yPos, width, size)
	self.super:init(xPos, yPos, width, size)
	self:addEventListener("", self.handleAny)
	self.views = {}
end

function MultiView:addView(view, name)
	view:setPos(self.xPos, self.yPos)
	
	if view.width ~= self.width or view.height ~= self.height then
		view:setSize(self.width, self.height)
	end
	
	self.views[name] = view
	view:setParentPane(self)
end

function MultiView:removeView(name)
	self.views[name] = nil
	view:setParentPane(nil)
end

function MultiView:gotoView(name)
	self.open = self.views[name]
end

function MultiView:draw(buffer)
	if self.open then
		self.open:draw(buffer)
	end
end

function MultiView:handleAny(...)
	if self.open then
		self.open:handleEvent(arg)
	end
end