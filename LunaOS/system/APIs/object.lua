---The object module allows the creations of classes, objects and interfaces.
--An object my have both static and non static varibles.
--Static varibles are accessed by classname.varible while non static varibles
--are accessed by instance.varible.
--Static varibles are the same for all instances, if one chances for one instance
--it changes for all.
--An object may also overide meta @{events} so that instances of the same class or
--inherit the same class may overide operators such as "+", "-" or "%".
--Object may also inherit from a parent class, attaining all of its static and non
--static varibles.
--When a class or objct tries to look up a value it starts at its own class and works
--its way up throgh its parents.
--Classes may overide varibles which applies to itself and all sub classes.
--Interfaces are a list of varibles that a class must contain in order to initalize.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module object


---Metamethods that a class can overide
local events = {
	"__mode","__tostring","__len","__unm","__add","__sub", "__mul",
	"__div","__mod","__pow","__concat","__eq","__lt","__le"
}

---Object class. all other classes are derived from this
local Object = {}

---Static varibles.
Object.static = {}

---Non static varibles.
Object.nonStatic = {}

---Interfaces that the object implements.
Object.interfaces = {}

---Empty constructor so that init can still be called without error.
Object.init = function()  end

--creates all the default functions for setting metamethods 
for _, v in ipairs(events) do
	Object.static[v] = function(class, value)
		local mt = getmetatable()
		class.events[v] = value 
	end
	
end

---Check whether an object is an instance of a class.
--Or if the object is an instance of any super class of the given class.
--@param object The object we want to see if its an instance of a class.
--@param class The class we check to see if its the class of an object.
--@return true if the class is an instance of the class or a parent of the class.
--@usage local isInstance = object:instanceOf(class)
local function instanceOfClass(object, class)
	--the class of the given object
	local objectClass = object.class
		
	--go through all of the classes parents to see if we get a match
	while objectClass ~= class do
		--if the class has no parent return false
		if not objectClass.super then
			return false
		end
		
		--set the objectClass to its parent and loop again
		objectClass = objectClass.super
	end
	
	return true
end

---Makes sure that the given class has all of its fields defined that are required by its interfaces.
--@param class The class to check.
--@return true if the class implements all of its classes fields. false otherwise.
--@usage local isValid = checkInterfaces(class)
local function checkInterfaces(class)
	--loop through all interfaces
	for _, interface in pairs(class.interfaces) do
		local fields = interface:getFields()
		local staticFields = interface:getStaticFields()
		
		
		--loop throgh fields
		for _, field in pairs(fields) do
			--if its missing a field return false
			if class.nonStatic[field] == nil then
				return false
			end
		end
		
		--loop through static fields
		for _, field in pairs(staticFields) do
			--if its missing a field return false
			if class.static[field] == nil then
				return false
			end
		end
	end
	
	return true
end

---Checks whether or not an object is an instance of an interface.
--@param object An object.
--@param interface An interface.
--@return true if the object implements the interface.
--@usage local isInstance = instanceOfInterface(object, interface)
local function instanceOfInterface(object, interface)
--	--for each interface
--	for _, classInterface in pairs(object.class.interfaces) do
--		if interface == classInterface then
--			return true
--		end
--	end
--	
--	return false
	
	
local fields = interface:getFields()
	local staticFields = interface:getStaticFields()


	--loop throgh fields
	for _, field in pairs(fields) do
		--if its missing a field return false
		if object.class.nonStatic[field] == nil then
			return false
		end
	end

	--loop through static fields
	for _, field in pairs(staticFields) do
		--if its missing a field return false
		if object.class.static[field] == nil then
			return false
		end
	end
	
	return true
end

---Default method instance of, avalible to all objects.
--It checks whether the object calling the method is an instance of a given class or interface.
--@param self The object calling the method.
--@param class A class or interface.
--@return true if the object is an instance of the given class or interface.
--@usage local isInstance object:instanceOf(class)
--@see instanceOfClass
--@see instanceOfInterface
function Object.nonStatic.instanceOf(self, class)
	--if an it has a implement method it must be a class
	--otherwise its an interface
	if class.implement then
		return instanceOfClass(self, class)
	else
		--return instanceOfInterface(self, class)
		return instanceOfInterface(self, class)
	end
end


---States that an object is implementing an interface or many interfaces.
--This method can be called once with many interfaces or many times with one interface, the result is the same.
--@param self The object calling the method.
--@param ... The interfaces to implement.
--@usage object:implement(interface1, interface2, interfaceN)
function Object.static.implement(self, ...)
	for _, interface in ipairs(arg) do
		self.interfaces[#self.interfaces + 1] = interface
	end
end

--creates all the default functions for setting metamethods 
for _, v in ipairs(events) do
	Object.static[v] = function(class, value) class.events[v] = value  end
end


---Create a new instance of class, further arguments are passed to the constructor (init).
--@param class The class that is made into an instance.
--@param ... All aother values that are passed to the constructor.
--@return The instance of the class.
--@usage local instance = Class()
local function new(class, ...)
	errorUtils.assert(checkInterfaces(class), "Error: Class does not implement all fields", 2)
	
	--define the actual instance and its meta table
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
	
	--copy nonstatic varibles over to the instance
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

---Creats a new class, parent can optonally be set to create a subclass.
--@param parent The parent of the new class, default is Object.
--@return The new class.
--@usage local Class = object.class()
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


--Default interface class.
local Interface = {}


---Adds non static fields to the interface.
--One or many fields can be added at once.
--any fields passed are just appended to the interfaces field table.
--@param ... The fields to add.
--@usage Interface:AddField("getHeight", "setHeight")
function Interface:addFields(...)
	for _, field in ipairs(arg) do
			self.nonStatic[#self.nonStatic + 1] = field
	end
end

---Adds static fields to the interface.
--One or many fields can be added at once.
--any fields passed are just appended to the interfaces field table.
--@param ... The fields to add.
--@usage Interface:AddField("getHeight", "setHeight")
function Interface:addStaticFields(...)
	for _, field in ipairs(arg) do
			self.static[#self.static + 1] = field
	end
end


---Gets all non static fields from the interfaces.
--@return All non static fields belonging to the interface
--@usage local fields = Interface:getFields()
function Interface:getFields()
	local fields = {}
	
	tableUtils.combine(fields, self.nonStatic)
	
	return fields
end

---Gets all static fields from the interfaces.
--@return All static fields belonging to the interface
--@usage local fields = Interface:getFields()
function Interface:getStaticFields()
	local fields = {}
	
	tableUtils.combine(fields, self.static)
	
	return fields
end

---Cretes a new interface.
--@return The new interface.
--@usage Interface = object.interface()
function interface()	
	local instance = {}
	
	instance.static = {}
	instance.nonStatic = {}
	
	return setmetatable(instance, {__index = Interface})
end
