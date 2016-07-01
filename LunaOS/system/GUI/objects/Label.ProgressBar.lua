ProgressBar = object.class(GUI.Label)

ProgressBar.progress = 0
ProgressBar.maxProgress = 100

function ProgressBar:init(xPos, yPos, width, height, text)
	self.super:init(xPos, yPos, width, height, text)
	
	self:setAlignment("center", "center")
end

function ProgressBar:draw(buffer)
	local x, y, width, height = self:getTextPos()
	
	local progress = mathUtils.round(self.progress / self.maxProgress * self.width)
	progress = math.min(progress, self.width)
	
	if self.backgroundColour then
		buffer:drawBox(self.xPos + progress, self.yPos, self.width - progress, self.height, self.backgroundColour) 
	end
	
	if self.highlightedBackgroundColour then
		buffer:drawBox(self.xPos, self.yPos, progress, self.height, self.highlightedBackgroundColour) 
	end
	
	buffer:writeTextBox(x, y, width, height, self.text, self.textColour, nil, self.xAlignment, self.yAlignment)
end

function ProgressBar:applyTheme(theme)
	self.super:applyTheme(theme)
	self.highlightedBackgroundColour = theme.highlightedBackgroundColour
	self.textColour = theme.textColour
end