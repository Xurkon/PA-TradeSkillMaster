-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster: Modern                           --
--          https://github.com/XiusTV/Modern-TSM-335                            --
--               All Rights Reserved - Backport to 3.3.5                        --
-- ------------------------------------------------------------------------------ --
--
-- Phase 5 Test Suite: Dashboard Enhancements & Accounting Integration
--

local TSM = select(2, ...) or _G.TSM

function TestPhase5()
	local passCount = 0
	local failCount = 0
	local totalTests = 14
	
	local function Test(name, condition, errorMsg)
		if condition then
			print("|cff00ff00✓|r " .. name)
			passCount = passCount + 1
		else
			print("|cffff0000✗|r " .. name .. " - " .. (errorMsg or "Failed"))
			failCount = failCount + 1
		end
	end
	
	print("\n|cffffd700=== Phase 5: Accounting Integration Tests ===|r")
	
	-- Test 1: AccountingTracker module exists
	Test("Test 1: AccountingTracker module exists",
		TSM.AccountingTracker ~= nil,
		"TSM.AccountingTracker is nil")
	
	-- Test 2: AccountingTracker.Initialize function exists
	Test("Test 2: AccountingTracker.Initialize exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.Initialize) == "function",
		"Initialize function missing")
	
	-- Test 3: AccountingTracker.IsAvailable function exists
	Test("Test 3: AccountingTracker.IsAvailable exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.IsAvailable) == "function",
		"IsAvailable function missing")
	
	-- Test 4: AccountingTracker.GetSalesData function exists
	Test("Test 4: AccountingTracker.GetSalesData exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetSalesData) == "function",
		"GetSalesData function missing")
	
	-- Test 5: AccountingTracker.GetExpenseData function exists
	Test("Test 5: AccountingTracker.GetExpenseData exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetExpenseData) == "function",
		"GetExpenseData function missing")
	
	-- Test 6: AccountingTracker.GetSalesTotalCopper function exists
	Test("Test 6: AccountingTracker.GetSalesTotalCopper exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetSalesTotalCopper) == "function",
		"GetSalesTotalCopper function missing")
	
	-- Test 7: AccountingTracker.GetExpenseTotalCopper function exists
	Test("Test 7: AccountingTracker.GetExpenseTotalCopper exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetExpenseTotalCopper) == "function",
		"GetExpenseTotalCopper function missing")
	
	-- Test 8: AccountingTracker.GetProfitCopper function exists
	Test("Test 8: AccountingTracker.GetProfitCopper exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetProfitCopper) == "function",
		"GetProfitCopper function missing")
	
	-- Test 9: AccountingTracker.GetTopSellers function exists
	Test("Test 9: AccountingTracker.GetTopSellers exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetTopSellers) == "function",
		"GetTopSellers function missing")
	
	-- Test 10: AccountingTracker.GetTopExpenses function exists
	Test("Test 10: AccountingTracker.GetTopExpenses exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetTopExpenses) == "function",
		"GetTopExpenses function missing")
	
	-- Test 11: AccountingTracker.GetSummaryStats function exists
	Test("Test 11: AccountingTracker.GetSummaryStats exists",
		TSM.AccountingTracker and type(TSM.AccountingTracker.GetSummaryStats) == "function",
		"GetSummaryStats function missing")
	
	-- Test 12: TSMGraph multi-series support
	local AceGUI = LibStub("AceGUI-3.0")
	local graph = AceGUI:Create("TSMGraph")
	local multiSeriesData = {
		{
			name = "Gold",
			color = {1, 0.82, 0, 1},
			data = {{x=1, y=100}, {x=2, y=200}, {x=3, y=150}}
		},
		{
			name = "Sales",
			color = {0, 1, 0, 1},
			data = {{x=1, y=50}, {x=2, y=75}, {x=3, y=60}}
		}
	}
	graph:SetData(multiSeriesData)
	Test("Test 12: TSMGraph accepts multi-series data",
		graph.multiSeriesMode == true and #graph.dataSeries == 2,
		"Multi-series mode not working")
	
	-- Test 13: TSMGraph backwards compatibility (single series)
	local singleSeriesData = {{x=1, y=100}, {x=2, y=200}, {x=3, y=150}}
	graph:SetData(singleSeriesData)
	Test("Test 13: TSMGraph single-series mode (backwards compat)",
		graph.multiSeriesMode == false and #graph.dataPoints == 3,
		"Single-series mode broken")
	
	-- Test 14: Dashboard initialization with AccountingTracker
	Test("Test 14: Dashboard initializes with AccountingTracker",
		TSM.Dashboard and type(TSM.Dashboard.Initialize) == "function",
		"Dashboard.Initialize missing")
	
	-- Summary
	print("\n|cffffd700=== Phase 5 Test Summary ===|r")
	print(string.format("|cff00ff00Passed:|r %d/%d", passCount, totalTests))
	if failCount > 0 then
		print(string.format("|cffff0000Failed:|r %d/%d", failCount, totalTests))
	end
	
	if passCount == totalTests then
		print("|cff00ff00All Phase 5 tests passed!|r ✓")
	else
		print("|cffff0000Some Phase 5 tests failed.|r Please review above.")
	end
	
	return passCount == totalTests
end

function TestPhase5Live()
	-- Live test with actual data (if TSM_Accounting is loaded)
	print("\n|cffffd700=== Phase 5 Live Data Test ===|r")
	
	if not TSM.AccountingTracker then
		print("|cffff0000AccountingTracker not loaded!|r")
		return false
	end
	
	local isAvailable = TSM.AccountingTracker.IsAvailable()
	print("AccountingTracker available: " .. (isAvailable and "|cff00ff00YES|r" or "|cffff0000NO|r"))
	
	if not isAvailable then
		print("|cffaaaaaTSM_Accounting addon not loaded or no data available.|r")
		print("Enable TSM_Accounting addon and record some transactions to test.")
		return false
	end
	
	-- Test with last 30 days
	local endTime = time()
	local startTime = endTime - (30 * 24 * 60 * 60)
	
	-- Get sales data
	local salesData = TSM.AccountingTracker.GetSalesData(startTime, endTime, nil)
	print(string.format("Found %d sales in last 30 days", #salesData))
	
	-- Get expense data
	local expenseData = TSM.AccountingTracker.GetExpenseData(startTime, endTime, nil)
	print(string.format("Found %d expenses in last 30 days", #expenseData))
	
	-- Get totals
	local salesTotal = TSM.AccountingTracker.GetSalesTotalCopper(startTime, endTime, nil)
	local expenseTotal = TSM.AccountingTracker.GetExpenseTotalCopper(startTime, endTime, nil)
	local profit = TSM.AccountingTracker.GetProfitCopper(startTime, endTime, nil)
	
	print(string.format("Total Sales: %s", TSMAPI:FormatTextMoney(salesTotal, "|cffffd700", true)))
	print(string.format("Total Expenses: %s", TSMAPI:FormatTextMoney(expenseTotal, "|cffffd700", true)))
	print(string.format("Net Profit: %s", TSMAPI:FormatTextMoney(profit, "|cffffd700", true)))
	
	-- Get top sellers
	local topSellers = TSM.AccountingTracker.GetTopSellers(startTime, endTime, 5, nil)
	if #topSellers > 0 then
		print("\n|cff00ff00Top 5 Sellers:|r")
		for i, item in ipairs(topSellers) do
			print(string.format("  %d. %s: %s (%dx)",
				i, item.itemName,
				TSMAPI:FormatTextMoney(item.total, "|cffffd700", true),
				item.quantity))
		end
	end
	
	-- Get top expenses
	local topExpenses = TSM.AccountingTracker.GetTopExpenses(startTime, endTime, 5, nil)
	if #topExpenses > 0 then
		print("\n|cffff0000Top 5 Expenses:|r")
		for i, item in ipairs(topExpenses) do
			print(string.format("  %d. %s: %s (%dx)",
				i, item.itemName,
				TSMAPI:FormatTextMoney(item.total, "|cffffd700", true),
				item.quantity))
		end
	end
	
	-- Get summary stats
	local stats = TSM.AccountingTracker.GetSummaryStats(startTime, endTime, nil)
	print("\n|cff00ffffSummary Statistics:|r")
	print(string.format("  Sales count: %d", stats.sales.count))
	print(string.format("  Expenses count: %d", stats.expenses.count))
	print(string.format("  Avg sales/day: %s", TSMAPI:FormatTextMoney(stats.sales.avgPerDay, "|cffffd700", true)))
	print(string.format("  Avg expenses/day: %s", TSMAPI:FormatTextMoney(stats.expenses.avgPerDay, "|cffffd700", true)))
	print(string.format("  Avg profit/day: %s", TSMAPI:FormatTextMoney(stats.profit.avgPerDay, "|cffffd700", true)))
	
	print("\n|cff00ff00Live data test complete!|r")
	return true
end

function TestPhase5Visual()
	-- Visual test - opens enhanced Dashboard
	print("\n|cffffd700=== Phase 5 Visual Test ===|r")
	print("Opening enhanced Dashboard with analytics...")
	
	if not TSM.Dashboard then
		print("|cffff0000Dashboard not loaded!|r")
		return false
	end
	
	TSM.Dashboard.Show()
	
	print("|cff00ff00Dashboard opened!|r")
	print("Test the following features:")
	print("  • Time range buttons (1D, 1W, 1M, etc)")
	if TSM.AccountingTracker and TSM.AccountingTracker.IsAvailable() then
		print("  • Graph mode selector (Gold Only, Gold+Sales, etc)")
		print("  • Sales/Expenses/Profit statistics")
		print("  • Transaction details panel")
		print("  • Top sellers/expenses lists")
		print("  • Multi-series graph (colored lines)")
	else
		print("  |cffaaaa(TSM_Accounting not available - limited features)|r")
	end
	
	return true
end

function TestPhase5All()
	-- Run all Phase 5 tests
	print("\n|cffffd700==================================|r")
	print("|cffffd700=== PHASE 5 COMPLETE TEST ===|r")
	print("|cffffd700==================================|r")
	
	local test1 = TestPhase5()
	print("\n")
	
	local test2 = TestPhase5Live()
	print("\n")
	
	local test3 = TestPhase5Visual()
	
	print("\n|cffffd700=== All Phase 5 Tests Complete ===|r")
	if test1 then
		print("|cff00ff00✓ Unit tests passed|r")
	end
	if test2 then
		print("|cff00ff00✓ Live data test passed|r")
	end
	if test3 then
		print("|cff00ff00✓ Visual test opened|r")
	end
	
	return test1 and test2 and test3
end

-- Register tests in global scope
_G.TestPhase5 = TestPhase5
_G.TestPhase5Live = TestPhase5Live
_G.TestPhase5Visual = TestPhase5Visual
_G.TestPhase5All = TestPhase5All

-- Test messages removed for regular users
-- print("|cffffd700Phase 5 tests loaded!|r Use: /run TestPhase5()")

