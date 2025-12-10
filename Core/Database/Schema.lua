-- Database Schema Definition
-- Defines table structure and field types

local TSM = select(2, ...)
local LibTSMClass = LibStub("LibTSMClass")
local Schema = LibTSMClass.DefineClass("Database.Schema")
TSM.Database = TSM.Database or {}
TSM.Database.Schema = Schema

local private = {
	fieldTypes = {
		NUMBER = "number",
		STRING = "string",
		BOOLEAN = "boolean",
	},
}

-- ============================================================================
-- Class Methods
-- ============================================================================

function Schema:__init()
	self._fields = {}
	self._indexes = {}
	self._primaryKey = nil
end

--- Add a field to the schema
-- @param fieldName string Name of the field
-- @param fieldType string Type (NUMBER, STRING, BOOLEAN)
-- @param default? any Default value
-- @return Schema self for chaining
function Schema:AddField(fieldName, fieldType, default)
	assert(type(fieldName) == "string", "fieldName must be a string")
	assert(private.fieldTypes[fieldType], "Invalid fieldType: " .. tostring(fieldType))
	
	self._fields[fieldName] = {
		name = fieldName,
		type = private.fieldTypes[fieldType],
		default = default,
	}
	
	return self
end

--- Add a number field
-- @param fieldName string Field name
-- @param default? number Default value
-- @return Schema self for chaining
function Schema:AddNumberField(fieldName, default)
	return self:AddField(fieldName, "NUMBER", default or 0)
end

--- Add a string field
-- @param fieldName string Field name
-- @param default? string Default value
-- @return Schema self for chaining
function Schema:AddStringField(fieldName, default)
	return self:AddField(fieldName, "STRING", default or "")
end

--- Add a boolean field
-- @param fieldName string Field name
-- @param default? boolean Default value
-- @return Schema self for chaining
function Schema:AddBooleanField(fieldName, default)
	return self:AddField(fieldName, "BOOLEAN", default or false)
end

--- Set the primary key field
-- @param fieldName string Primary key field
-- @return Schema self for chaining
function Schema:SetPrimaryKey(fieldName)
	assert(self._fields[fieldName], "Field does not exist: " .. tostring(fieldName))
	self._primaryKey = fieldName
	return self
end

--- Add an index for faster queries
-- @param fieldName string Field to index
-- @return Schema self for chaining
function Schema:AddIndex(fieldName)
	assert(self._fields[fieldName], "Field does not exist: " .. tostring(fieldName))
	tinsert(self._indexes, fieldName)
	return self
end

--- Get all fields
-- @return table Fields definition
function Schema:GetFields()
	return self._fields
end

--- Get a specific field
-- @param fieldName string Field name
-- @return table|nil Field definition
function Schema:GetField(fieldName)
	return self._fields[fieldName]
end

--- Get the primary key
-- @return string|nil Primary key field name
function Schema:GetPrimaryKey()
	return self._primaryKey
end

--- Get all indexes
-- @return table Array of indexed field names
function Schema:GetIndexes()
	return self._indexes
end

--- Validate a value for a field
-- @param fieldName string Field name
-- @param value any Value to validate
-- @return boolean, string Valid, error message
function Schema:ValidateField(fieldName, value)
	local field = self._fields[fieldName]
	if not field then
		return false, "Unknown field: " .. tostring(fieldName)
	end
	
	if value == nil then
		return true  -- nil is allowed
	end
	
	if type(value) ~= field.type then
		return false, "Expected " .. field.type .. " for field " .. fieldName .. ", got " .. type(value)
	end
	
	return true
end

--- Get default value for a field
-- @param fieldName string Field name
-- @return any Default value
function Schema:GetDefault(fieldName)
	local field = self._fields[fieldName]
	return field and field.default or nil
end

