--metamethods that a class can overide
local events = {
	"__mode","__tostring","__len","__unm","__add","__sub", "__mul",
	"__div","__mod","__pow","__concat","__eq","__lt","__le"
}

--Object class. all other classes are derived from this
local Object = {}

Object.static = {}
Object.nonStatic = {}
Object.interfaces = {}

--empty constructor so that init can still be called without error
Object.init = function()  end

--default method instanceOf: return true if 
--the object's class or superclasses are equal to the class parameter
local function instanceOfClass(object, class)
	local objectClass = object.class
		
	while objectClass ~= class do
		if not objectClass.super then return false end
		objectClass = objectClass.super
	end
	
	return true
end

--makes sure that the given class has all of its fields defined in its intefaces defined
local function checkInterfaces(class)
	for _, interface in pairs(class.interfaces) do
		local fields = interface:getFields()
		local staticFields = interface:getStaticFields()
		
		for _, field in pairs(fields) do
			if class.nonStatic[field] == nil then
				return false
			end
		end
		
		for _, field in pairs(staticFields) do
			if class.static[field] == nil then
				return false
			end
		end
	end
	
	return true
end

--return true if the object is an instance of the given interface or any of its super interfaces
local function instanceOfInterface(object, interface)
	--for _, classInterface in pairs(object.class.interfaces) do
		--if tableUtils.indexOf(interface:getTypes(), classInterface) then
			--return true
		--end
	--end
	
	--return false
	
	
	--this is the best i can do currently
	--the above code does not work because some wierdness with the function envioments
	--so this just checks it has all the functions that fields that the interface wants and if so counts it as an instance
	
	local fields = interface:getFields()
	local staticFields = interface:getStaticFields()
	
	for _, field in pairs(fields) do
		if object.class.nonStatic[field] == nil then
			return false
		end
	end
	
	for _, field in pairs(staticFields) do
		if object.static[field] == nil then
			return false
		end
	end
	
	return true
end

--return true if the object is an instance of the given class or any of its super classes
function Object.nonStatic.instanceOf(self, class)
	if class.implement then
		return instanceOfClass(self, class)
	else
		return instanceOfInterface(self, class)
	end
end


--allows classes to implement interface
--an interface has a list of fields that the class must define before it is can be instantiated
function Object.static.implement(self, ...)
	for _, interface in ipairs(arg) do
		self.interfaces[#self.interfaces + 1] = interface
	end
end

--creates all the default functions for setting metamethods 
for _, v in ipairs(events) do
	Object.static[v] = function(class, value) class.events[v] = value  end
end

----------------------------------------------------------------------------------------------

--if an object tries to change a value
--if the value already exists in super set the value there
--otherwise set the value in object.self
local function changeObjectValue(tbl, k, v)
	if tbl.super[k] then
		tbl.super[k] = v
	else
		tbl.self[k]  = v
	end
end

--create a new instance of class, further arguments are passed to the constructor (init)
local function new(class, ...)
	errorUtils.assert(checkInterfaces(class), "Error: Class does not implement all fields", 0)
	
	--define the actual instance
	local instance = {self = {}, class = class}
	local instanceMt = {__index = instance.self, __newindex = instance.self}
	
	local superInstance = instance
	local superClass = class.super
	
	local deepCopy = tableUtils.deepCopy
	local self = instance.self
	
	--make sure any new varibles go to instance.self
	--make sure all varibles are read from instance.self
	--make sure function are read from the correct superclass
	local function index(tbl, k)
		local value = tbl.nonStatic[k]
		local selfValue = rawget(self, k)
	
		if  type(value) == "function" then
			return value
		elseif  type(selfValue) ~= "function" then
			return selfValue
		end
	end
	
	for k, v in pairs(class.nonStatic) do
		self[k] = deepCopy(v)
	end
	
	--copy the class' metamethods to the objects metatable
	for _, v in ipairs(events) do
		instanceMt[v] = class.events[v]
	end
	
	while superClass do
		local mt =  setmetatable({nonStatic = superClass.nonStatic}, {__index = index, __newindex = self})
		rawset(superInstance, "super", mt)
		superInstance = superInstance.super
		
		--copy nonStatic varibles (not function) from the super classes making sure varibles in subclass have priority over thoes in super
		for k, v in pairs(superClass.nonStatic) do
			if type(v) ~= "function" and instance.self[k] == nil then 
				instance.self[k] = deepCopy(v)
			end
		end
		
		superClass = superClass.super
	end
	
	setmetatable(self,  {__index = instance.super})
	setmetatable(instance, instanceMt)
	
	instance.class.nonStatic.init(instance, unpack(arg)) -- call the constructor
	
	return instance
end

--creats a new class, parent can optonally be set to create a subclass
--if parent in not set, the class' parent well become Object
--
--when the created class is index (Class.something) only static methods and varibles well be avalible
--if the value is not found it well look at the static values of its superclass
--non static values can be fount by explicitly indexing Class.nonStatic.something
function class(parent)
	parent = parent or Object
	
	local subclass = {
		events = setmetatable({}, {__index = parent.events}),
		static = setmetatable({}, {__index = parent.static}), --static methods and varibles
		--interfaces = setmetatable({}, {__index = parent.interfaces}),
		interfaces = tableUtils.copy(parent.interfaces),
		--create an empty constructor so that when init is called an no constructor in specifried super.init doen not get called instead
		nonStatic = setmetatable({init = function() end}, {__index = parent.nonStatic}), --non static methods and varibles
		super = parent
	}
	
	return setmetatable(subclass, {__index = subclass.static, __call = new, __newindex = subclass.nonStatic})
end




-----------------------------------------------------------------------------------------------------------------------------------
--interfaces
-----------------------------------------------------------------------------------------------------------------------------------

local Interface = {}


--adds non static fields to the interface 
function Interface:addFields(...)
	for _, field in ipairs(arg) do
			self.nonStatic[#self.nonStatic + 1] = field
	end
end

--adds static fields to the interface 
function Interface:addStaticFields(...)
	for _, field in ipairs(arg) do
			self.static[#self.static + 1] = field
	end
end

--returns a table of itself and all its super intefaces
function Interface:getTypes()
	local types = {self}
	
	for _, parent in pairs(self.super) do
			types = tableUtils.combine(types, parent:getTypes())
	end
	
	return types
end

--returns all the noncstatic fields of itself and all its super intefaces
function Interface:getFields()
	local interfaces = self:getTypes()
	local fields = {}
	
	for _, interface in pairs(interfaces) do
		fields = tableUtils.combine(fields, interface.nonStatic)
	end
	
	return fields
end

--returns all the static fields of itself and all its super intefaces
function Interface:getStaticFields()
	local interfaces = self:getTypes()
	local fields = {}
	
	for _, interface in pairs(interfaces) do
		fields = tableUtils.combine(fields, interface.static)
	end
	
	return fields
end

--cretes a new interface, many intefaces can be passed as super interfaces
function interface(...)
	arg.n = nil
	--if #arg ==  0 then arg = nil end
	
	local instance = {}
	
	instance.static = {}
	instance.nonStatic = {}
	instance.super = arg
	instance.addFields = addFields
	instance.addStaticFields = addStaticFields

	return setmetatable(instance, {__index = Interface})
end
