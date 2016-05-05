--metamethods that a class can overide
local events = {
	"__mode","__tostring","__len","__unm","__add","__sub", "__mul",
	"__div","__mod","__pow","__concat","__eq","__lt","__le"
}

--Object class. all other classes are derived from this
local Object = {}

Object.static = {}
Object.nonStatic = {} --empty constructor so that init can still be called without error

Object.init = function()  end
--default mothod instanceOf: return true if 
--the object's class or superclasses are equal to the class parameter
function Object.nonStatic.instanceOf(self, class)
	local objectClass = self.class
	
	while objectClass ~= class do
		if not objectClass.super then return false end
		objectClass = objectClass.super
	end
	
	return true
end


--creates all the default functions for setting metamethods 
for _, v in ipairs(events) do
	Object.static[v] = function(class, value) class.events[v] = value  end
end

----------------------------------------------------------------------------------------------

--if an object tries to change a value
--if the value already exists it super set the value there
--otherwise set the value in object.self
local function changeObjectValue(tbl, k, v)
	if tbl.super[k] then
		tbl.super[k] = v
	else
		tbl.self[k]  = v
	end
end

--when an object looks for one of its members
--first look in object.self
--otherwise look in object.nonStatic (only return the value is a function)
--finally look in object.super
local function index(obj, k, v)
	local nonStatic = obj.class.nonStatic[k]
	nonStatic = type(nonStatic) == "function" and nonStatic or nil
	
	return obj.self[k] or nonStatic or obj.super[k] 
end

--calls the constructor (instance.init)
--makes sure all calls to super constructors goes to instance.super
local function construct(instance, ...)
	local mt = {__index = index, __newindex = changeObjectValue}
	instance.super = setmetatable({}, {__index = instance.class.super.nonStatic})
	
	local superInstance = instance
	local superClass = instance.class
	
	while true do
		superInstance = superInstance.super
		superClass = superClass.super
		
		if not superClass then break end
		rawset(superInstance, 'super' ,setmetatable({}, {__index = superClass.nonStatic, __newindex = instance.super}))
		
	end
	
	setmetatable(instance,  mt)
	instance.class.nonStatic.init(instance, unpack(arg)) -- call the constructor
	
	instance.super.super = nil --get rid of all exess
	

end

--create a new instance of class, further arguments are passed to the constructor (init)
local function new(class, ...)
	local mt = {__index = index, __newindex = changeObjectValue}
	
	local instance = {
		self = {},
		class = class
	}
	
	--each object gets a copy of all varibles in class.nonStatic (except functions, they are shared to consurve memory)
	local deepCopy = tableUtils.deepCopy
	local self = instance.self
	for k, v in pairs(class.nonStatic) do
		if type(v) ~= "function" then self[k] = deepCopy(v) end
	end
	
	--copy the class' metamethods to the objects metatable
	for _, v in ipairs(events) do
		mt[v] = class.events[v]
	end
	
	--setmetatable(instance, {__index = class.nonStatic})
	construct(instance, unpack(arg))
	--setmetatable(instance,  mt)
	
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
		--create an empty constructor so that when init is called an no constructor in specifried super.init doen not get called instead
		nonStatic = setmetatable({init = function() end}, {__index = parent.nonStatic}), --non static methods and varibles
		super = parent
	}
	
	return setmetatable(subclass, {__index = subclass.static, __call = new, __newindex = subclass.nonStatic})
end