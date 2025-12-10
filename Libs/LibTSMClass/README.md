# LibTSMClass - OOP Framework for TSM

## Overview
Provides object-oriented programming capabilities for TSM, including:
- Class definition and inheritance
- Abstract classes
- Instance creation
- Type checking

## Usage

### Define a Class
```lua
local LibTSMClass = LibStub("LibTSMClass")
local MyClass = LibTSMClass.DefineClass("MyClass")

function MyClass:__init(name)
    self.name = name
end

function MyClass:GetName()
    return self.name
end
```

### Create Instances
```lua
local obj = MyClass("Test")
print(obj:GetName())  -- Output: Test
```

### Inheritance
```lua
local ChildClass = LibTSMClass.DefineClass("ChildClass", MyClass)

function ChildClass:__init(name, age)
    self.__parent.__init(self, name)  -- Call parent constructor
    self.age = age
end
```

### Abstract Classes
```lua
local AbstractClass = LibTSMClass.DefineAbstractClass("AbstractClass")
-- Cannot instantiate: AbstractClass() will error
```

## API

- `DefineClass(className, parentClass?)` - Define a new class
- `DefineAbstractClass(className, parentClass?)` - Define abstract class
- `NewInstance(class, ...)` - Create instance
- `IsInstance(obj, className)` - Check instance type
- `GetClassName(obj)` - Get class name

