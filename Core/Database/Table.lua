-- Database Table
-- Abstraction for a database table with schema

local TSM = select(2, ...)
local LibTSMClass = LibStub("LibTSMClass")
local Row = TSM.Database.Row
local Query = TSM.Database.Query
local Table = LibTSMClass.DefineClass("Database.Table")
TSM.Database.Table = Table

-- ============================================================================
-- Class Methods
-- ============================================================================

function Table:__init(name, schema)
	self._name = name
	self._schema = schema
	self._rows = {}
	self._indexes = {}
	self._nextId = 1
	
	-- Build indexes
	for _, fieldName in ipairs(schema:GetIndexes()) do
		self._indexes[fieldName] = {}
	end
end

--- Insert a new row
-- @param data table Row data
-- @return Row The new row
function Table:Insert(data)
	local row = Row(self._schema, data)
	
	-- Auto-generate primary key if needed
	local pkField = self._schema:GetPrimaryKey()
	if pkField and not data[pkField] then
		data[pkField] = self._nextId
		self._nextId = self._nextId + 1
	end
	
	tinsert(self._rows, row)
	
	-- Update indexes
	self:_UpdateIndexes(row, true)
	
	return row
end

--- Delete a row
-- @param row Row Row to delete
-- @return boolean Success
function Table:Delete(row)
	for i, r in ipairs(self._rows) do
		if r == row then
			tremove(self._rows, i)
			self:_UpdateIndexes(row, false)
			return true
		end
	end
	return false
end

--- Get all rows
-- @return table Array of rows
function Table:GetAllRows()
	return self._rows
end

--- Get row by primary key
-- @param pkValue any Primary key value
-- @return Row|nil Row or nil
function Table:GetByPrimaryKey(pkValue)
	local pkField = self._schema:GetPrimaryKey()
	if not pkField then return nil end
	
	for _, row in ipairs(self._rows) do
		if row:GetField(pkField) == pkValue then
			return row
		end
	end
	return nil
end

--- Create a new query
-- @return Query Query builder
function Table:NewQuery()
	return Query(self)
end

--- Get row count
-- @return number Number of rows
function Table:GetRowCount()
	return #self._rows
end

--- Clear all rows
function Table:Clear()
	wipe(self._rows)
	for _, index in pairs(self._indexes) do
		wipe(index)
	end
	self._nextId = 1
end

--- Get table name
-- @return string Table name
function Table:GetName()
	return self._name
end

--- Get schema
-- @return Schema The schema
function Table:GetSchema()
	return self._schema
end

--- Update indexes for a row
-- @param row Row The row
-- @param add boolean Add to index (true) or remove (false)
-- @private
function Table:_UpdateIndexes(row, add)
	for fieldName, index in pairs(self._indexes) do
		local value = row:GetField(fieldName)
		if value ~= nil then
			index[value] = index[value] or {}
			if add then
				tinsert(index[value], row)
			else
				for i, r in ipairs(index[value]) do
					if r == row then
						tremove(index[value], i)
						break
					end
				end
			end
		end
	end
end

--- Get rows by indexed field value (fast lookup)
-- @param fieldName string Indexed field name
-- @param value any Value to find
-- @return table Array of matching rows
function Table:GetByIndex(fieldName, value)
	local index = self._indexes[fieldName]
	if not index then
		error("Field not indexed: " .. tostring(fieldName))
	end
	
	return index[value] or {}
end

