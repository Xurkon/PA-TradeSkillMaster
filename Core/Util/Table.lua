-- Table utility functions
-- Based on TSM4 retail LibTSMUtil/Lua/Table.lua

local TSM = select(2, ...)
local Table = {}
TSM.Table = Table

-- ============================================================================
-- Module Functions
-- ============================================================================

--- Get the number of keys in a table
-- @param tbl table The table
-- @return number The count
function Table.Count(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

--- Check if a table contains a value
-- @param tbl table The table
-- @param value any The value to find
-- @return boolean True if found
function Table.Contains(tbl, value)
	for _, v in pairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

--- Get a list of keys from a table
-- @param tbl table The table
-- @return table Array of keys
function Table.GetKeys(tbl)
	local keys = {}
	for k in pairs(tbl) do
		tinsert(keys, k)
	end
	return keys
end

--- Get a list of values from a table
-- @param tbl table The table
-- @return table Array of values
function Table.GetValues(tbl)
	local values = {}
	for _, v in pairs(tbl) do
		tinsert(values, v)
	end
	return values
end

--- Remove a value from an array table
-- @param tbl table The array
-- @param value any The value to remove
-- @return boolean True if removed
function Table.RemoveValue(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			tremove(tbl, i)
			return true
		end
	end
	return false
end

--- Copy a table shallowly
-- @param tbl table The table to copy
-- @return table The copy
function Table.ShallowCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

--- Copy a table deeply
-- @param tbl table The table to copy
-- @return table The deep copy
function Table.DeepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = Table.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

--- Merge two tables
-- @param dest table Destination table
-- @param src table Source table
-- @param deep boolean Deep merge
function Table.Merge(dest, src, deep)
	for k, v in pairs(src) do
		if deep and type(v) == "table" and type(dest[k]) == "table" then
			Table.Merge(dest[k], v, true)
		else
			dest[k] = v
		end
	end
end

