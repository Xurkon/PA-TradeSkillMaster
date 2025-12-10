-- TempTable - Temporary table pooling to reduce garbage collection
-- Based on TSM4 retail LibTSMUtil/BaseType/TempTable.lua

local TSM = select(2, ...)
local TempTable = {}
TSM.TempTable = TempTable

local private = {
	pool = {},
	inUse = {},
}

-- ============================================================================
-- Module Functions
-- ============================================================================

--- Acquire a temporary table from the pool
-- @return table A clean temporary table
function TempTable.Acquire(...)
	local tbl = tremove(private.pool)
	if not tbl then
		tbl = {}
	end
	
	private.inUse[tbl] = true
	
	-- If arguments provided, insert them
	local numArgs = select("#", ...)
	if numArgs > 0 then
		for i = 1, numArgs do
			local arg = select(i, ...)
			tbl[i] = arg
		end
	end
	
	return tbl
end

--- Release a temporary table back to the pool
-- @param tbl table The table to release
function TempTable.Release(tbl)
	assert(tbl and private.inUse[tbl], "Table not acquired or already released")
	
	wipe(tbl)
	private.inUse[tbl] = nil
	tinsert(private.pool, tbl)
end

--- Create an iterator from a temp table and release it when done
-- @param tbl table The temporary table
-- @return function Iterator function
function TempTable.Iterator(tbl)
	assert(tbl and private.inUse[tbl], "Table not acquired")
	
	local i = 0
	local n = #tbl
	
	return function()
		i = i + 1
		if i <= n then
			return i, tbl[i]
		else
			TempTable.Release(tbl)
			return nil
		end
	end
end

--- Get the number of tables in the pool (for debugging)
-- @return number Number of pooled tables
function TempTable.GetPoolSize()
	return #private.pool
end

--- Get the number of tables in use (for debugging)
-- @return number Number of tables in use
function TempTable.GetInUseCount()
	local count = 0
	for _ in pairs(private.inUse) do
		count = count + 1
	end
	return count
end

