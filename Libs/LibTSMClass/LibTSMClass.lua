-- LibTSMClass - Object-Oriented Programming Framework for TSM
-- Based on TSM4 retail implementation, adapted for 3.3.5

local MAJOR, MINOR = "LibTSMClass", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- ============================================================================
-- Module Setup
-- ============================================================================

local private = {
	classes = {},
	abstractClasses = {},
}

-- ============================================================================
-- Public API
-- ============================================================================

--- Defines a new class or returns an existing one
-- @param className string The name of the class
-- @param parentClass? table Optional parent class to inherit from
-- @return table The class object
function lib.DefineClass(className, parentClass)
	assert(type(className) == "string", "className must be a string")
	assert(not parentClass or type(parentClass) == "table", "parentClass must be a table or nil")
	
	if private.classes[className] then
		-- Class already exists, return it
		return private.classes[className]
	end
	
	-- Create new class
	local class = {
		__className = className,
		__parent = parentClass,
		__isAbstract = false,
	}
	
	-- Set up inheritance and callable metatable
	local classMT = {
		__call = function(cls, ...)
			return lib.NewInstance(cls, ...)
		end
	}
	
	if parentClass then
		classMT.__index = parentClass
	end
	
	setmetatable(class, classMT)
	
	-- Store class
	private.classes[className] = class
	
	return class
end

--- Defines an abstract class (cannot be instantiated)
-- @param className string The name of the abstract class
-- @param parentClass? table Optional parent class
-- @return table The abstract class object
function lib.DefineAbstractClass(className, parentClass)
	local class = lib.DefineClass(className, parentClass)
	class.__isAbstract = true
	private.abstractClasses[className] = true
	return class
end

--- Creates a new instance of a class
-- @param class table The class to instantiate
-- @param ... any Constructor arguments
-- @return table The instance
function lib.NewInstance(class, ...)
	assert(type(class) == "table", "class must be a table")
	assert(not class.__isAbstract, "Cannot instantiate abstract class: " .. tostring(class.__className))
	
	local instance = {}
	setmetatable(instance, { __index = class })
	
	-- Call constructor if it exists
	if instance.__init then
		instance:__init(...)
	end
	
	return instance
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Checks if an object is an instance of a class
-- @param obj table The object to check
-- @param className string The class name
-- @return boolean True if obj is instance of className
function lib.IsInstance(obj, className)
	if type(obj) ~= "table" then return false end
	
	local class = getmetatable(obj).__index
	while class do
		if class.__className == className then
			return true
		end
		class = class.__parent
	end
	
	return false
end

--- Gets the class name of an object
-- @param obj table The object
-- @return string|nil The class name or nil
function lib.GetClassName(obj)
	if type(obj) ~= "table" then return nil end
	local class = getmetatable(obj).__index
	return class and class.__className or nil
end

-- ============================================================================
-- Export
-- ============================================================================

-- Make class definition easier
_G.TSMClass = lib

-- Example usage:
--[[
local MyClass = LibTSMClass.DefineClass("MyClass")

function MyClass:__init(name)
	self.name = name
end

function MyClass:SayHello()
	print("Hello, " .. self.name)
end

local obj = MyClass("World")
obj:SayHello()  -- Output: Hello, World
]]

