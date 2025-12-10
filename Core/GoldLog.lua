-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster: Modern                           --
--          https://github.com/XiusTV/Modern-TSM-335                            --
--               All Rights Reserved - Backport to 3.3.5                        --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...) or _G.TSM
if not TSM then error("TSM not found!") return end

-- GoldLog: Time-series storage for gold values
-- Based on retail TSM's GoldLog class
-- Stores gold values over time with minute-based resolution

-- Access LibTSMClass globally (exposed as _G.TSMClass by the library)
local TSMClass = _G.TSMClass or LibStub("LibTSMClass")
local GoldLog = TSMClass.DefineClass("GoldLog")
local SECONDS_PER_MIN = 60

-- ============================================================================
-- Class Meta Methods
-- ============================================================================

function GoldLog:__init()
	self._data = {} -- {minute => goldValue}
	self._startMinute = nil
	self._endMinute = nil
	self._isDirty = false
end

-- ============================================================================
-- Public Methods
-- ============================================================================

--- Append a gold value at a specific minute
-- @param minute number The minute timestamp (time()/60)
-- @param goldValue number The gold value in copper
function GoldLog:Append(minute, goldValue)
	assert(type(minute) == "number" and minute >= 0, "Invalid minute")
	assert(type(goldValue) == "number" and goldValue >= 0, "Invalid goldValue")
	
	if self._endMinute and minute < self._endMinute then
		error("Cannot append data in the past")
	end
	
	-- Only store if value changed or it's been a while
	local lastValue = self._data[self._endMinute]
	if not lastValue or lastValue ~= goldValue or minute - self._endMinute > 60 then
		self._data[minute] = goldValue
		self._startMinute = self._startMinute or minute
		self._endMinute = minute
		self._isDirty = true
	end
end

--- Get gold value at a specific minute (interpolates if needed)
-- @param minute number The minute timestamp
-- @return number The gold value in copper
function GoldLog:GetValue(minute)
	if not self._startMinute then
		return 0
	end
	
	-- Before start of log
	if minute < self._startMinute then
		return 0
	end
	
	-- After end of log
	if minute >= self._endMinute then
		return self._data[self._endMinute] or 0
	end
	
	-- Exact match
	if self._data[minute] then
		return self._data[minute]
	end
	
	-- Interpolate: Find closest earlier value
	local prevMinute, prevValue = nil, 0
	for m, v in pairs(self._data) do
		if m <= minute and (not prevMinute or m > prevMinute) then
			prevMinute = m
			prevValue = v
		end
	end
	
	return prevValue
end

--- Get the start minute of the log
-- @return number|nil The start minute
function GoldLog:GetStartMinute()
	return self._startMinute
end

--- Get the end minute of the log
-- @return number|nil The end minute
function GoldLog:GetEndMinute()
	return self._endMinute
end

--- Clean old entries (older than 2 years)
function GoldLog:Clean()
	if not self._endMinute then
		return
	end
	
	local cutoffMinute = self._endMinute - (365 * 2 * 24 * 60) -- 2 years
	local newStartMinute = nil
	
	for minute in pairs(self._data) do
		if minute < cutoffMinute then
			self._data[minute] = nil
			self._isDirty = true
		else
			newStartMinute = (not newStartMinute or minute < newStartMinute) and minute or newStartMinute
		end
	end
	
	self._startMinute = newStartMinute
end

--- Serialize the log for storage
-- @return string Serialized data
function GoldLog:Serialize()
	if not self._startMinute then
		return ""
	end
	
	local parts = {}
	local sortedMinutes = {}
	
	for minute in pairs(self._data) do
		table.insert(sortedMinutes, minute)
	end
	table.sort(sortedMinutes)
	
	for _, minute in ipairs(sortedMinutes) do
		table.insert(parts, minute .. ":" .. self._data[minute])
	end
	
	return table.concat(parts, ",")
end

--- Load a log from serialized data
-- @param data string Serialized data
-- @return GoldLog|nil The loaded log
function GoldLog.Load(data)
	if not data or data == "" then
		return nil
	end
	
	local log = GoldLog()
	
	for entry in string.gmatch(data, "[^,]+") do
		local minute, value = string.match(entry, "(%d+):(%d+)")
		if minute and value then
			minute = tonumber(minute)
			value = tonumber(value)
			log._data[minute] = value
			log._startMinute = (not log._startMinute or minute < log._startMinute) and minute or log._startMinute
			log._endMinute = (not log._endMinute or minute > log._endMinute) and minute or log._endMinute
		end
	end
	
	return log
end

--- Create a new empty GoldLog
-- @return GoldLog
function GoldLog.New()
	return GoldLog()
end

-- ============================================================================
-- Module Registration
-- ============================================================================

TSM.GoldLog = GoldLog

