-- Database - Main database management
-- Manages multiple tables with schemas

local TSM = select(2, ...)
local LibTSMClass = LibStub("LibTSMClass")
local Schema = TSM.Database.Schema
local Table = TSM.Database.Table
local Database = LibTSMClass.DefineClass("Database.Database")
TSM.Database.Database = Database

-- ============================================================================
-- Class Methods
-- ============================================================================

function Database:__init(name)
	self._name = name
	self._tables = {}
end

--- Create a new table
-- @param tableName string Table name
-- @param schema Schema Table schema
-- @return Table The new table
function Database:CreateTable(tableName, schema)
	assert(type(tableName) == "string", "tableName must be a string")
	assert(schema and schema.__className == "Database.Schema", "schema must be a Schema")
	assert(not self._tables[tableName], "Table already exists: " .. tableName)
	
	local table = Table(tableName, schema)
	self._tables[tableName] = table
	
	return table
end

--- Get a table
-- @param tableName string Table name
-- @return Table|nil Table or nil
function Database:GetTable(tableName)
	return self._tables[tableName]
end

--- Drop a table
-- @param tableName string Table name
-- @return boolean Success
function Database:DropTable(tableName)
	if self._tables[tableName] then
		self._tables[tableName] = nil
		return true
	end
	return false
end

--- Get all table names
-- @return table Array of table names
function Database:GetTableNames()
	local names = {}
	for name in pairs(self._tables) do
		tinsert(names, name)
	end
	return names
end

--- Get database name
-- @return string Database name
function Database:GetName()
	return self._name
end

