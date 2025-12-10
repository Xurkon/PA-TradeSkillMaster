-- Database Row
-- Represents a single row in a database table

local TSM = select(2, ...)
local LibTSMClass = LibStub("LibTSMClass")
local Row = LibTSMClass.DefineClass("Database.Row")
TSM.Database.Row = Row

-- ============================================================================
-- Class Methods
-- ============================================================================

function Row:__init(schema, data)
	self._schema = schema
	self._data = data or {}
	self._modified = false
end

--- Get a field value
-- @param fieldName string Field name
-- @return any Field value
function Row:GetField(fieldName)
	assert(self._schema:GetField(fieldName), "Unknown field: " .. tostring(fieldName))
	return self._data[fieldName]
end

--- Set a field value
-- @param fieldName string Field name
-- @param value any New value
function Row:SetField(fieldName, value)
	local valid, err = self._schema:ValidateField(fieldName, value)
	assert(valid, "Validation failed: " .. tostring(err))
	
	self._data[fieldName] = value
	self._modified = true
end

--- Get all data
-- @return table Raw data table
function Row:GetData()
	return self._data
end

--- Check if row has been modified
-- @return boolean True if modified
function Row:IsModified()
	return self._modified
end

--- Mark as not modified
function Row:ClearModified()
	self._modified = false
end

--- Get the primary key value
-- @return any Primary key value
function Row:GetPrimaryKey()
	local pkField = self._schema:GetPrimaryKey()
	return pkField and self._data[pkField] or nil
end

