-- Phase 1 Foundation Tests
-- Run in-game: /run TestPhase1()

function TestPhase1()
	local TSM = _G.TSM
	
	print("|cff00ff00=== Phase 1 Foundation Tests ===|r")
	
	-- Test 1: LibTSMClass
	print("Test 1: LibTSMClass...")
	local LibTSMClass = LibStub("LibTSMClass")
	assert(LibTSMClass, "LibTSMClass not loaded")
	
	local TestClass = LibTSMClass.DefineClass("TestClass")
	function TestClass:__init(value)
		self.value = value
	end
	function TestClass:GetValue()
		return self.value
	end
	
	local obj = TestClass(42)
	assert(obj:GetValue() == 42, "Basic class test failed")
	print("|cff00ff00  PASS - LibTSMClass working|r")
	
	-- Test 2: TempTable
	print("Test 2: TempTable...")
	assert(TSM.TempTable, "TempTable not loaded")
	
	local t = TSM.TempTable.Acquire(1, 2, 3)
	assert(#t == 3, "TempTable acquire failed")
	assert(t[1] == 1 and t[2] == 2 and t[3] == 3, "TempTable values incorrect")
	TSM.TempTable.Release(t)
	assert(TSM.TempTable.GetPoolSize() >= 1, "TempTable release failed")
	print("|cff00ff00  PASS - TempTable working|r")
	
	-- Test 3: Table utilities
	print("Test 3: Table utilities...")
	assert(TSM.Table, "Table utils not loaded")
	
	local tbl = {a = 1, b = 2, c = 3}
	assert(TSM.Table.Count(tbl) == 3, "Table.Count failed")
	assert(TSM.Table.Contains(tbl, 2), "Table.Contains failed")
	
	local keys = TSM.Table.GetKeys(tbl)
	assert(#keys == 3, "Table.GetKeys failed")
	
	local copy = TSM.Table.ShallowCopy(tbl)
	assert(copy.a == 1 and copy.b == 2, "Table.ShallowCopy failed")
	print("|cff00ff00  PASS - Table utils working|r")
	
	-- Test 4: SettingsHelper
	print("Test 4: SettingsHelper...")
	assert(TSM.SettingsHelper, "SettingsHelper not loaded")
	
	local testSchema = {
		fontSize = {
			type = "number",
			default = 14,
			min = 10,
			max = 20,
		},
	}
	
	TSM.SettingsHelper.RegisterSchema("test", testSchema)
	assert(TSM.SettingsHelper.GetDefault("test", "fontSize") == 14, "SettingsHelper default failed")
	
	local valid, err = TSM.SettingsHelper.Validate("test", "fontSize", 15)
	assert(valid, "SettingsHelper validation failed: " .. tostring(err))
	
	local invalid, err2 = TSM.SettingsHelper.Validate("test", "fontSize", 5)
	assert(not invalid, "SettingsHelper should reject value below min")
	print("|cff00ff00  PASS - SettingsHelper working|r")
	
	print("|cff00ff00=== All Phase 1 Tests PASSED! ===|r")
	print("|cffffff00Phase 1 Foundation is ready for Phase 2 (Database System)|r")
end

-- Test inheritance
function TestPhase1Inheritance()
	local LibTSMClass = LibStub("LibTSMClass")
	
	print("|cff00ff00=== Testing OOP Inheritance ===|r")
	
	-- Parent class
	local Animal = LibTSMClass.DefineClass("Animal")
	function Animal:__init(name)
		self.name = name
	end
	function Animal:Speak()
		return "Some sound"
	end
	
	-- Child class
	local Dog = LibTSMClass.DefineClass("Dog", Animal)
	function Dog:__init(name, breed)
		Animal.__init(self, name)
		self.breed = breed
	end
	function Dog:Speak()
		return "Woof!"
	end
	function Dog:GetBreed()
		return self.breed
	end
	
	local myDog = Dog("Buddy", "Golden Retriever")
	assert(myDog.name == "Buddy", "Inheritance: name failed")
	assert(myDog:GetBreed() == "Golden Retriever", "Inheritance: breed failed")
	assert(myDog:Speak() == "Woof!", "Inheritance: method override failed")
	assert(LibTSMClass.IsInstance(myDog, "Dog"), "IsInstance failed for Dog")
	assert(LibTSMClass.IsInstance(myDog, "Animal"), "IsInstance failed for parent Animal")
	
	print("|cff00ff00  PASS - Inheritance working perfectly!|r")
end

