-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster: Modern                           --
--          https://github.com/XiusTV/Modern-TSM-335                            --
--               All Rights Reserved - Backport to 3.3.5                        --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...) or _G.TSM
if not TSM then error("TSM not found!") return end

local AccountingTracker = {}
local private = {
	accounting = nil,
	cache = {
		lastUpdate = 0,
		sales = {},
		expenses = {},
		topSellers = {},
		topExpenses = {},
	},
}

local CACHE_TIMEOUT = 5 -- Refresh cache every 5 seconds

-- ============================================================================
-- Initialization
-- ============================================================================

function AccountingTracker.Initialize()
	-- Try to get TSM_Accounting addon
	private.accounting = LibStub("AceAddon-3.0"):GetAddon("TSM_Accounting", true)
	
	if not private.accounting then
		TSM:Print("Warning: TSM_Accounting not loaded. Sales/Expense tracking unavailable.")
		return false
	end
	
	return true
end

function AccountingTracker.IsAvailable()
	return private.accounting ~= nil and private.accounting.items ~= nil
end

-- ============================================================================
-- Sales Data
-- ============================================================================

function AccountingTracker.GetSalesData(startTime, endTime, characters)
	if not AccountingTracker.IsAvailable() then
		return {}
	end
	
	local sales = {}
	local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
	
	-- Iterate through all items
	for itemString, itemData in pairs(private.accounting.items) do
		if itemData.sales then
			for _, sale in ipairs(itemData.sales) do
				-- Filter by time range
				if sale.time >= startTime and sale.time <= endTime then
					-- Filter by characters if specified
					local playerMatch = not characters or #characters == 0
					if not playerMatch and characters then
						for _, char in ipairs(characters) do
							if sale.player == char then
								playerMatch = true
								break
							end
						end
					end
					
					if playerMatch then
						table.insert(sales, {
							timestamp = sale.time,
							type = "sale",
							itemString = itemString,
							itemName = itemData.name or "Unknown",
							quantity = sale.quantity or 1,
							stackSize = sale.stackSize or 1,
							pricePerItem = sale.copper and (sale.copper / (sale.quantity or 1)) or 0,
							total = sale.copper or 0,
							character = sale.player or currentPlayer,
							buyer = sale.otherPlayer or "Unknown",
							source = sale.key or "Auction",
						})
					end
				end
			end
		end
	end
	
	-- Sort by timestamp (newest first)
	table.sort(sales, function(a, b) return a.timestamp > b.timestamp end)
	
	return sales
end

function AccountingTracker.GetSalesTotalCopper(startTime, endTime, characters)
	local sales = AccountingTracker.GetSalesData(startTime, endTime, characters)
	local total = 0
	
	for _, sale in ipairs(sales) do
		total = total + sale.total
	end
	
	return total
end

-- ============================================================================
-- Expense Data (Purchases)
-- ============================================================================

function AccountingTracker.GetExpenseData(startTime, endTime, characters)
	if not AccountingTracker.IsAvailable() then
		return {}
	end
	
	local expenses = {}
	local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
	
	-- Item purchases (buys)
	for itemString, itemData in pairs(private.accounting.items) do
		if itemData.buys then
			for _, buy in ipairs(itemData.buys) do
				if buy.time >= startTime and buy.time <= endTime then
					local playerMatch = not characters or #characters == 0
					if not playerMatch and characters then
						for _, char in ipairs(characters) do
							if buy.player == char then
								playerMatch = true
								break
							end
						end
					end
					
					if playerMatch then
						table.insert(expenses, {
							timestamp = buy.time,
							type = "purchase",
							itemString = itemString,
							itemName = itemData.name or "Unknown",
							quantity = buy.quantity or 1,
							stackSize = buy.stackSize or 1,
							pricePerItem = buy.copper and (buy.copper / (buy.quantity or 1)) or 0,
							total = buy.copper or 0,
							character = buy.player or currentPlayer,
							seller = buy.otherPlayer or "Unknown",
							source = buy.key or "Auction",
						})
					end
				end
			end
		end
	end
	
	-- Other expenses (repairs, postage, etc)
	if private.accounting.money and private.accounting.money.expense then
		for _, expense in ipairs(private.accounting.money.expense) do
			if expense.time >= startTime and expense.time <= endTime then
				local playerMatch = not characters or #characters == 0
				if not playerMatch and characters then
					for _, char in ipairs(characters) do
						if expense.player == char then
							playerMatch = true
							break
						end
					end
				end
				
				if playerMatch then
					table.insert(expenses, {
						timestamp = expense.time,
						type = expense.key or "Other",
						itemString = nil,
						itemName = expense.key or "Other Expense",
						quantity = 1,
						stackSize = 1,
						pricePerItem = expense.copper or 0,
						total = expense.copper or 0,
						character = expense.player or currentPlayer,
						seller = expense.otherPlayer or "Various",
						source = expense.key or "Other",
					})
				end
			end
		end
	end
	
	-- Sort by timestamp (newest first)
	table.sort(expenses, function(a, b) return a.timestamp > b.timestamp end)
	
	return expenses
end

function AccountingTracker.GetExpenseTotalCopper(startTime, endTime, characters)
	local expenses = AccountingTracker.GetExpenseData(startTime, endTime, characters)
	local total = 0
	
	for _, expense in ipairs(expenses) do
		total = total + expense.total
	end
	
	return total
end

-- ============================================================================
-- Other Income (Transfers, etc)
-- ============================================================================

function AccountingTracker.GetOtherIncomeCopper(startTime, endTime, characters)
	if not AccountingTracker.IsAvailable() then
		return 0
	end
	
	if not private.accounting.money or not private.accounting.money.income then
		return 0
	end
	
	local total = 0
	
	for _, income in ipairs(private.accounting.money.income) do
		if income.time >= startTime and income.time <= endTime then
			local playerMatch = not characters or #characters == 0
			if not playerMatch and characters then
				for _, char in ipairs(characters) do
					if income.player == char then
						playerMatch = true
						break
					end
				end
			end
			
			if playerMatch then
				total = total + (income.copper or 0)
			end
		end
	end
	
	return total
end

-- ============================================================================
-- Profit Calculation
-- ============================================================================

function AccountingTracker.GetProfitCopper(startTime, endTime, characters)
	local sales = AccountingTracker.GetSalesTotalCopper(startTime, endTime, characters)
	local otherIncome = AccountingTracker.GetOtherIncomeCopper(startTime, endTime, characters)
	local expenses = AccountingTracker.GetExpenseTotalCopper(startTime, endTime, characters)
	
	return (sales + otherIncome) - expenses
end

-- ============================================================================
-- Top Items
-- ============================================================================

function AccountingTracker.GetTopSellers(startTime, endTime, limit, characters)
	if not AccountingTracker.IsAvailable() then
		return {}
	end
	
	local itemTotals = {}
	
	-- Sum up sales by item
	for itemString, itemData in pairs(private.accounting.items) do
		if itemData.sales then
			for _, sale in ipairs(itemData.sales) do
				if sale.time >= startTime and sale.time <= endTime then
					local playerMatch = not characters or #characters == 0
					if not playerMatch and characters then
						for _, char in ipairs(characters) do
							if sale.player == char then
								playerMatch = true
								break
							end
						end
					end
					
					if playerMatch then
						if not itemTotals[itemString] then
							itemTotals[itemString] = {
								itemString = itemString,
								itemName = itemData.name or "Unknown",
								total = 0,
								quantity = 0,
							}
						end
						itemTotals[itemString].total = itemTotals[itemString].total + (sale.copper or 0)
						itemTotals[itemString].quantity = itemTotals[itemString].quantity + (sale.quantity or 1)
					end
				end
			end
		end
	end
	
	-- Convert to array and sort by total
	local topItems = {}
	for _, data in pairs(itemTotals) do
		table.insert(topItems, data)
	end
	
	table.sort(topItems, function(a, b) return a.total > b.total end)
	
	-- Return top N items
	local result = {}
	for i = 1, math.min(limit or 5, #topItems) do
		table.insert(result, topItems[i])
	end
	
	return result
end

function AccountingTracker.GetTopExpenses(startTime, endTime, limit, characters)
	if not AccountingTracker.IsAvailable() then
		return {}
	end
	
	local itemTotals = {}
	
	-- Sum up expenses by item
	for itemString, itemData in pairs(private.accounting.items) do
		if itemData.buys then
			for _, buy in ipairs(itemData.buys) do
				if buy.time >= startTime and buy.time <= endTime then
					local playerMatch = not characters or #characters == 0
					if not playerMatch and characters then
						for _, char in ipairs(characters) do
							if buy.player == char then
								playerMatch = true
								break
							end
						end
					end
					
					if playerMatch then
						if not itemTotals[itemString] then
							itemTotals[itemString] = {
								itemString = itemString,
								itemName = itemData.name or "Unknown",
								total = 0,
								quantity = 0,
							}
						end
						itemTotals[itemString].total = itemTotals[itemString].total + (buy.copper or 0)
						itemTotals[itemString].quantity = itemTotals[itemString].quantity + (buy.quantity or 1)
					end
				end
			end
		end
	end
	
	-- Convert to array and sort by total
	local topItems = {}
	for _, data in pairs(itemTotals) do
		table.insert(topItems, data)
	end
	
	table.sort(topItems, function(a, b) return a.total > b.total end)
	
	-- Return top N items
	local result = {}
	for i = 1, math.min(limit or 5, #topItems) do
		table.insert(result, topItems[i])
	end
	
	return result
end

function AccountingTracker.GetMostProfitableItem(startTime, endTime, characters)
	if not AccountingTracker.IsAvailable() then
		return nil
	end
	
	local itemProfit = {}
	
	-- Calculate profit per item (sales - expenses)
	for itemString, itemData in pairs(private.accounting.items) do
		local sales = 0
		local expenses = 0
		
		if itemData.sales then
			for _, sale in ipairs(itemData.sales) do
				if sale.time >= startTime and sale.time <= endTime then
					local playerMatch = not characters or #characters == 0
					if not playerMatch and characters then
						for _, char in ipairs(characters) do
							if sale.player == char then
								playerMatch = true
								break
							end
						end
					end
					if playerMatch then
						sales = sales + (sale.copper or 0)
					end
				end
			end
		end
		
		if itemData.buys then
			for _, buy in ipairs(itemData.buys) do
				if buy.time >= startTime and buy.time <= endTime then
					local playerMatch = not characters or #characters == 0
					if not playerMatch and characters then
						for _, char in ipairs(characters) do
							if buy.player == char then
								playerMatch = true
								break
							end
						end
					end
					if playerMatch then
						expenses = expenses + (buy.copper or 0)
					end
				end
			end
		end
		
		if sales > 0 or expenses > 0 then
			itemProfit[itemString] = {
				itemString = itemString,
				itemName = itemData.name or "Unknown",
				profit = sales - expenses,
			}
		end
	end
	
	-- Find most profitable
	local mostProfitable = nil
	for _, data in pairs(itemProfit) do
		if not mostProfitable or data.profit > mostProfitable.profit then
			mostProfitable = data
		end
	end
	
	return mostProfitable
end

-- ============================================================================
-- Time Series Data (for graphing)
-- ============================================================================

function AccountingTracker.GetSalesTimeSeries(startTime, endTime, interval, characters)
	if not AccountingTracker.IsAvailable() then
		return {}
	end
	
	local sales = AccountingTracker.GetSalesData(startTime, endTime, characters)
	local timeSeries = {}
	
	-- Group sales by time interval
	for _, sale in ipairs(sales) do
		local bucket = math.floor(sale.timestamp / interval) * interval
		timeSeries[bucket] = (timeSeries[bucket] or 0) + sale.total
	end
	
	-- Convert to array format for graphing
	local result = {}
	for timestamp, total in pairs(timeSeries) do
		table.insert(result, {
			x = timestamp,
			y = total / 10000, -- Convert to gold
		})
	end
	
	-- Sort by timestamp
	table.sort(result, function(a, b) return a.x < b.x end)
	
	return result
end

function AccountingTracker.GetExpenseTimeSeries(startTime, endTime, interval, characters)
	if not AccountingTracker.IsAvailable() then
		return {}
	end
	
	local expenses = AccountingTracker.GetExpenseData(startTime, endTime, characters)
	local timeSeries = {}
	
	-- Group expenses by time interval
	for _, expense in ipairs(expenses) do
		local bucket = math.floor(expense.timestamp / interval) * interval
		timeSeries[bucket] = (timeSeries[bucket] or 0) + expense.total
	end
	
	-- Convert to array format for graphing
	local result = {}
	for timestamp, total in pairs(timeSeries) do
		table.insert(result, {
			x = timestamp,
			y = total / 10000, -- Convert to gold
		})
	end
	
	-- Sort by timestamp
	table.sort(result, function(a, b) return a.x < b.x end)
	
	return result
end

-- ============================================================================
-- Summary Statistics
-- ============================================================================

function AccountingTracker.GetSummaryStats(startTime, endTime, characters)
	if not AccountingTracker.IsAvailable() then
		return {
			available = false,
			sales = { total = 0, count = 0, avgPerDay = 0 },
			expenses = { total = 0, count = 0, avgPerDay = 0 },
			profit = { total = 0, avgPerDay = 0 },
		}
	end
	
	local sales = AccountingTracker.GetSalesData(startTime, endTime, characters)
	local expenses = AccountingTracker.GetExpenseData(startTime, endTime, characters)
	
	local salesTotal = 0
	for _, sale in ipairs(sales) do
		salesTotal = salesTotal + sale.total
	end
	
	local expenseTotal = 0
	for _, expense in ipairs(expenses) do
		expenseTotal = expenseTotal + expense.total
	end
	
	local otherIncome = AccountingTracker.GetOtherIncomeCopper(startTime, endTime, characters)
	
	local days = math.max(1, (endTime - startTime) / 86400)
	
	return {
		available = true,
		sales = {
			total = salesTotal,
			count = #sales,
			avgPerDay = salesTotal / days,
		},
		expenses = {
			total = expenseTotal,
			count = #expenses,
			avgPerDay = expenseTotal / days,
		},
		otherIncome = {
			total = otherIncome,
			avgPerDay = otherIncome / days,
		},
		profit = {
			total = (salesTotal + otherIncome) - expenseTotal,
			avgPerDay = ((salesTotal + otherIncome) - expenseTotal) / days,
		},
	}
end

-- ============================================================================
-- Module Registration
-- ============================================================================

TSM.AccountingTracker = AccountingTracker

