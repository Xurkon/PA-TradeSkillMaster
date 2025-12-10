-- Database Query Builder
-- SQL-like query interface for tables

local TSM = select(2, ...)
local LibTSMClass = LibStub("LibTSMClass")
local TempTable = TSM.TempTable
local QueryClause = TSM.Database.QueryClause
local Query = LibTSMClass.DefineClass("Database.Query")
TSM.Database.Query = Query

-- ============================================================================
-- Class Methods
-- ============================================================================

function Query:__init(table)
	self._table = table
	self._clauses = {}
	self._orderBy = nil
	self._orderAscending = true
	self._limit = nil
	self._offset = nil
	self._selectFields = nil  -- nil = all fields
end

--- Select specific fields
-- @param ... string Field names
-- @return Query self for chaining
function Query:Select(...)
	self._selectFields = {...}
	return self
end

--- Add an equality clause
-- @param field string Field name
-- @param value any Value to match
-- @return Query self for chaining
function Query:Equal(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.EQUAL, value))
	return self
end

--- Add a not-equal clause
-- @param field string Field name
-- @param value any Value to not match
-- @return Query self for chaining
function Query:NotEqual(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.NOT_EQUAL, value))
	return self
end

--- Add a less-than clause
-- @param field string Field name
-- @param value number Value to compare
-- @return Query self for chaining
function Query:LessThan(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.LESS_THAN, value))
	return self
end

--- Add a less-than-or-equal clause
-- @param field string Field name
-- @param value number Value to compare
-- @return Query self for chaining
function Query:LessThanOrEqual(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.LESS_THAN_EQUAL, value))
	return self
end

--- Add a greater-than clause
-- @param field string Field name
-- @param value number Value to compare
-- @return Query self for chaining
function Query:GreaterThan(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.GREATER_THAN, value))
	return self
end

--- Add a greater-than-or-equal clause
-- @param field string Field name
-- @param value number Value to compare
-- @return Query self for chaining
function Query:GreaterThanOrEqual(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.GREATER_THAN_EQUAL, value))
	return self
end

--- Add a contains clause (string matching)
-- @param field string Field name
-- @param value string Value to search for
-- @return Query self for chaining
function Query:Contains(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.CONTAINS, value))
	return self
end

--- Add a starts-with clause
-- @param field string Field name
-- @param value string Prefix to match
-- @return Query self for chaining
function Query:StartsWith(field, value)
	tinsert(self._clauses, QueryClause(field, QueryClause.OPERATORS.STARTS_WITH, value))
	return self
end

--- Set order by
-- @param field string Field to order by
-- @param ascending? boolean Ascending order (default true)
-- @return Query self for chaining
function Query:OrderBy(field, ascending)
	self._orderBy = field
	self._orderAscending = ascending ~= false
	return self
end

--- Set result limit
-- @param count number Max results
-- @return Query self for chaining
function Query:Limit(count)
	self._limit = count
	return self
end

--- Set result offset
-- @param count number Offset
-- @return Query self for chaining
function Query:Offset(count)
	self._offset = count
	return self
end

--- Execute query and get all results
-- @return table Array of results
function Query:Execute()
	local results = TempTable.Acquire()
	
	-- Get all rows from table
	local allRows = self._table:GetAllRows()
	
	-- Filter by clauses
	for _, row in ipairs(allRows) do
		local matches = true
		for _, clause in ipairs(self._clauses) do
			if not clause:Evaluate(row) then
				matches = false
				break
			end
		end
		
		if matches then
			tinsert(results, row)
		end
	end
	
	-- Sort if order by specified
	if self._orderBy then
		local field = self._orderBy
		local asc = self._orderAscending
		table.sort(results, function(a, b)
			local aVal = a:GetField(field)
			local bVal = b:GetField(field)
			if asc then
				return aVal < bVal
			else
				return aVal > bVal
			end
		end)
	end
	
	-- Apply offset and limit
	local finalResults = TempTable.Acquire()
	local startIdx = (self._offset or 0) + 1
	local endIdx = self._limit and (startIdx + self._limit - 1) or #results
	
	for i = startIdx, math.min(endIdx, #results) do
		tinsert(finalResults, results[i])
	end
	
	TempTable.Release(results)
	
	return finalResults
end

--- Execute query and get first result
-- @return Row|nil First result or nil
function Query:First()
	local results = self:Limit(1):Execute()
	local first = results[1]
	TempTable.Release(results)
	return first
end

--- Execute query and get count
-- @return number Number of matching rows
function Query:Count()
	local results = self:Execute()
	local count = #results
	TempTable.Release(results)
	return count
end

--- Iterate over results
-- @return function Iterator
function Query:Iterator()
	local results = self:Execute()
	return TempTable.Iterator(results)
end

