Group = object.class()

Group.components = {}

function Group:init(allowMultipleSelected, oneMustBeSelected)
	self.allowMultipleSelected = allowMultipleSelected or false
	self.oneMustBeSelected = oneMustBeSelected or false
end

function Group:addComponent(component)
	errorUtils.assert(component:instanceOf(GUI.Selectable), "Error: Component must implement the Selectable interface")
	
	table.insert(self.components, component)
	
	component.onSelect = function() self:handleSelect(component) end
	component.onUnSelect = function() self:handleUnSelect(component) end
end

function Group:removeComponent(component)
	table.remove(self.components, tableUtils.isIn(self.components, component))
	component.onSelect = function() end
end

function Group: selectAll()
	for k, v in pairs(self.components) do
		v.selected = true
	end
end

function Group: unSelectAll()
	for k, v in pairs(self.components) do
		v.selected = false
	end
end

function Group: getSelected()
	local selected = {}
	
	for k, v in pairs(self.components) do
		if v.selected then 
			selected[#selected + 1] = v
		end
	end
	
	return selected
end

function Group: getUnSelected()
	local unSelected = {}
	
	for k, v in pairs(self.components) do
		if not k.selected then 
			unSelected[#unSelected + 1] = v
			end
	end
	
	return unSelected
end

function Group:handleSelect(component)
	if not self.allowMultipleSelected then
		self:unSelectAll()
		component.selected = true
	end
	
	self:onChange()
end

function Group:handleUnSelect(component)
	if self.oneMustBeSelected and #self:getSelected() == 0 then
		component.selected = true
	end
	
	self:onChange()
end

function Group:onChange()
	--empty function called whenever a button in the group changes
end