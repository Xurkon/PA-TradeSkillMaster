-- Database Query Clause
-- Represents a single WHERE condition

local TSM = select(2, ...)
local LibTSMClass = LibStub("LibTSMClass")
local QueryClause = LibTSMClass.DefineClass("Database.QueryClause")
TSM.Database.QueryClause = QueryClause

local OPERATORS = {
	EQUAL = "=",
	NOT_EQUAL = "!=",
	LESS_THAN = "<",
	LESS_THAN_EQUAL = "<=",
	GREATER_THAN = ">",
	GREATER_THAN_EQUAL = ">=",
	CONTAINS = "CONTAINS",
	STARTS_WITH = "STARTS_WITH",
}

-- ============================================================================
-- Class Methods
-- ============================================================================

function QueryClause:__init(field, operator, value)
	self._field = field
	self._operator = operator
	self._value = value
end

--- Evaluate the clause against a row
-- @param row table|Row Row data
-- @return boolean True if clause matches
function QueryClause:Evaluate(row)
	local rowData = type(row) == "table" and (row.GetData and row:GetData() or row) or row
	local fieldValue = rowData[self._field]
	
	if fieldValue == nil then
		return false
	end
	
	local op = self._operator
	local val = self._value
	
	if op == OPERATORS.EQUAL then
		return fieldValue == val
	elseif op == OPERATORS.NOT_EQUAL then
		return fieldValue ~= val
	elseif op == OPERATORS.LESS_THAN then
		return fieldValue < val
	elseif op == OPERATORS.LESS_THAN_EQUAL then
		return fieldValue <= val
	elseif op == OPERATORS.GREATER_THAN then
		return fieldValue > val
	elseif op == OPERATORS.GREATER_THAN_EQUAL then
		return fieldValue >= val
	elseif op == OPERATORS.CONTAINS then
		return type(fieldValue) == "string" and strfind(strlower(fieldValue), strlower(tostring(val)), 1, true) ~= nil
	elseif op == OPERATORS.STARTS_WITH then
		return type(fieldValue) == "string" and strfind(strlower(fieldValue), "^" .. strlower(tostring(val))) ~= nil
	end
	
	return false
end

--- Get the field name
-- @return string Field name
function QueryClause:GetField()
	return self._field
end

--- Get the operator
-- @return string Operator
function QueryClause:GetOperator()
	return self._operator
end

--- Get the value
-- @return any Value
function QueryClause:GetValue()
	return self._value
end

-- Export operators
QueryClause.OPERATORS = OPERATORS

