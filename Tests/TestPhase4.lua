-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster: Modern                           --
--          https://github.com/XiusTV/Modern-TSM-335                            --
--               Phase 4 Tests: Dashboard & Gold Tracking                       --
-- ------------------------------------------------------------------------------ --

local TSM = _G.TSM

-- Test counter
local testsRun = 0
local testsPassed = 0

local function assert(condition, message)
	testsRun = testsRun + 1
	if not condition then
		error("TEST FAILED: " .. (message or "assertion failed"), 2)
	end
	testsPassed = testsPassed + 1
end

-- ============================================================================
-- Test Phase 4: Dashboard & Gold Tracking
-- ============================================================================

function _G.TestPhase4()
	testsRun = 0
	testsPassed = 0
	
	print("|cff00ff00========================================|r")
	print("|cffffd700   Testing Phase 4: Dashboard       |r")
	print("|cff00ff00========================================|r")
	
	-- Test 1: GoldLog exists
	print("\n|cff00ffffTest 1: GoldLog class exists|r")
	assert(TSM.GoldLog, "TSM.GoldLog should exist")
	print("|cff00ff00✓ GoldLog class found|r")
	
	-- Test 2: Create a new GoldLog
	print("\n|cff00ffffTest 2: Create new GoldLog|r")
	local log = TSM.GoldLog.New()
	assert(log, "GoldLog.New() should return a log")
	assert(log.Append, "GoldLog should have Append method")
	assert(log.GetValue, "GoldLog should have GetValue method")
	assert(log.Serialize, "GoldLog should have Serialize method")
	print("|cff00ff00✓ GoldLog created successfully|r")
	
	-- Test 3: Append gold values
	print("\n|cff00ffffTest 3: Append gold values|r")
	local currentMinute = math.floor(time() / 60)
	log:Append(currentMinute, 1000000) -- 100 gold
	log:Append(currentMinute + 60, 1500000) -- 150 gold
	log:Append(currentMinute + 120, 2000000) -- 200 gold
	assert(log:GetStartMinute() == currentMinute, "Start minute should match first append")
	assert(log:GetEndMinute() == currentMinute + 120, "End minute should match last append")
	print("|cff00ff00✓ Gold values appended|r")
	
	-- Test 4: Retrieve gold values
	print("\n|cff00ffffTest 4: Retrieve gold values|r")
	local value1 = log:GetValue(currentMinute)
	local value2 = log:GetValue(currentMinute + 60)
	local value3 = log:GetValue(currentMinute + 120)
	assert(value1 == 1000000, "First value should be 1000000, got " .. value1)
	assert(value2 == 1500000, "Second value should be 1500000, got " .. value2)
	assert(value3 == 2000000, "Third value should be 2000000, got " .. value3)
	print("|cff00ff00✓ Gold values retrieved correctly|r")
	
	-- Test 5: Serialize and deserialize
	print("\n|cff00ffffTest 5: Serialize and deserialize|r")
	local serialized = log:Serialize()
	assert(serialized and #serialized > 0, "Serialized data should not be empty")
	local loadedLog = TSM.GoldLog.Load(serialized)
	assert(loadedLog, "Should be able to load serialized data")
	assert(loadedLog:GetValue(currentMinute) == 1000000, "Loaded log should have same values")
	print("|cff00ff00✓ Serialize/deserialize works|r")
	
	-- Test 6: GoldTracker exists
	print("\n|cff00ffffTest 6: GoldTracker service exists|r")
	assert(TSM.GoldTracker, "TSM.GoldTracker should exist")
	assert(TSM.GoldTracker.Initialize, "GoldTracker should have Initialize method")
	assert(TSM.GoldTracker.GetGoldAtTime, "GoldTracker should have GetGoldAtTime method")
	assert(TSM.GoldTracker.GetGraphTimeRange, "GoldTracker should have GetGraphTimeRange method")
	print("|cff00ff00✓ GoldTracker service found|r")
	
	-- Test 7: Initialize GoldTracker
	print("\n|cff00ffffTest 7: Initialize GoldTracker|r")
	TSM.GoldTracker.Initialize()
	print("|cff00ff00✓ GoldTracker initialized|r")
	
	-- Test 8: Get time range
	print("\n|cff00ffffTest 8: Get graph time range|r")
	local minTime, maxTime, step = TSM.GoldTracker.GetGraphTimeRange({})
	assert(minTime, "Should have minTime")
	assert(maxTime, "Should have maxTime")
	assert(step, "Should have step")
	assert(minTime <= maxTime, "minTime should be <= maxTime")
	print(string.format("|cff00ff00✓ Time range: %d to %d (step: %d)|r", minTime, maxTime, step))
	
	-- Test 9: Get gold at time
	print("\n|cff00ffffTest 9: Get gold at current time|r")
	local gold = TSM.GoldTracker.GetGoldAtTime(time(), {})
	assert(gold >= 0, "Gold should be >= 0")
	print(string.format("|cff00ff00✓ Current gold: %d copper|r", gold))
	
	-- Test 10: Dashboard exists
	print("\n|cff00ffffTest 10: Dashboard exists|r")
	assert(TSM.Dashboard, "TSM.Dashboard should exist")
	assert(TSM.Dashboard.Initialize, "Dashboard should have Initialize method")
	assert(TSM.Dashboard.Show, "Dashboard should have Show method")
	print("|cff00ff00✓ Dashboard module found|r")
	
	-- Test 11: Initialize Dashboard
	print("\n|cff00ffffTest 11: Initialize Dashboard|r")
	TSM.Dashboard.Initialize()
	print("|cff00ff00✓ Dashboard initialized|r")
	
	-- Summary
	print("\n|cff00ff00========================================|r")
	print(string.format("|cffffd700   Tests Passed: %d/%d|r", testsPassed, testsRun))
	print("|cff00ff00========================================|r")
	
	if testsPassed == testsRun then
		print("|cff00ff00All Phase 4 tests PASSED!|r ✓")
		print("\n|cffaaaaaa Usage:|r")
		print("|cffffd700/tsm dashboard|r - Open Dashboard")
		print("|cffffd700/run TSM.Dashboard.Show()|r - Show Dashboard directly")
	else
		print("|cffff0000Some tests FAILED!|r ✗")
	end
end

-- ============================================================================
-- Visual Test: Show Dashboard
-- ============================================================================

function _G.TestPhase4Visual()
	print("|cff00ff00Opening Dashboard...|r")
	
	-- Initialize if not already done
	if not TSM.Dashboard then
		print("|cffff0000ERROR: TSM.Dashboard not found! Run TestPhase4() first.|r")
		return
	end
	
	TSM.Dashboard.Initialize()
	TSM.Dashboard.Show()
	
	print("|cff00ff00Dashboard opened!|r")
	print("|cffaaaaaa- View gold tracking graph|r")
	print("|cffaaaaaa- Click time range buttons (1D, 1W, 1M, etc.)|r")
	print("|cffaaaaaa- Drag window to move it|r")
	print("|cffaaaaaa- Click X or run TestPhase4Visual() again to close|r")
end

-- Test messages removed for regular users
-- print("|cff00ff00Phase 4 Tests Loaded!|r")
-- print("|cffffd700/run TestPhase4()|r - Run all Phase 4 tests")
-- print("|cffffd700/run TestPhase4Visual()|r - Show Dashboard")

