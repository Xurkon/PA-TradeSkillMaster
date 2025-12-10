-- Phase 2 Database System Tests
-- Run in-game: /run TestPhase2()

function TestPhase2()
	local TSM = _G.TSM
	local Schema = TSM.Database.Schema
	local Database = TSM.Database.Database
	
	print("|cff00ff00=== Phase 2 Database System Tests ===|r")
	
	-- Test 1: Schema
	print("Test 1: Schema creation...")
	local schema = Schema()
		:AddStringField("name")
		:AddNumberField("price")
		:SetPrimaryKey("name")
		:AddIndex("price")
	assert(schema:GetPrimaryKey() == "name", "Primary key failed")
	assert(#schema:GetIndexes() == 1, "Index failed")
	print("|cff00ff00  PASS - Schema working|r")
	
	-- Test 2: Database and Table
	print("Test 2: Database and table...")
	local db = Database("TestDB")
	local items = db:CreateTable("items", schema)
	assert(items:GetRowCount() == 0, "Initial row count should be 0")
	print("|cff00ff00  PASS - Database and Table working|r")
	
	-- Test 3: Insert
	print("Test 3: Insert rows...")
	items:Insert({name = "Apple", price = 10})
	items:Insert({name = "Banana", price = 15})
	items:Insert({name = "Cherry", price = 20})
	assert(items:GetRowCount() == 3, "Should have 3 rows")
	print("|cff00ff00  PASS - Insert working|r")
	
	-- Test 4: Query - Equal
	print("Test 4: Query with Equal...")
	local apple = items:NewQuery():Equal("name", "Apple"):First()
	assert(apple and apple:GetField("price") == 10, "Apple price should be 10")
	print("|cff00ff00  PASS - Equal query working|r")
	
	-- Test 5: Query - LessThan
	print("Test 5: Query with LessThan...")
	local cheap = items:NewQuery():LessThan("price", 18):Execute()
	assert(#cheap == 2, "Should find 2 cheap items")
	TSM.TempTable.Release(cheap)
	print("|cff00ff00  PASS - LessThan query working|r")
	
	-- Test 6: Query - OrderBy
	print("Test 6: Query with OrderBy...")
	local sorted = items:NewQuery():OrderBy("price", false):Execute()
	assert(sorted[1]:GetField("name") == "Cherry", "First should be Cherry (most expensive)")
	assert(sorted[3]:GetField("name") == "Apple", "Last should be Apple (cheapest)")
	TSM.TempTable.Release(sorted)
	print("|cff00ff00  PASS - OrderBy query working|r")
	
	-- Test 7: Query - Count
	print("Test 7: Query Count...")
	local count = items:NewQuery():GreaterThan("price", 12):Count()
	assert(count == 2, "Should count 2 items > 12")
	print("|cff00ff00  PASS - Count query working|r")
	
	-- Test 8: Delete
	print("Test 8: Delete row...")
	items:Delete(apple)
	assert(items:GetRowCount() == 2, "Should have 2 rows after delete")
	print("|cff00ff00  PASS - Delete working|r")
	
	-- Test 9: GetByPrimaryKey
	print("Test 9: Get by primary key...")
	local banana = items:GetByPrimaryKey("Banana")
	assert(banana and banana:GetField("price") == 15, "Should find Banana with price 15")
	print("|cff00ff00  PASS - GetByPrimaryKey working|r")
	
	-- Test 10: Query Iterator
	print("Test 10: Query Iterator...")
	local sum = 0
	for i, item in items:NewQuery():Iterator() do
		sum = sum + item:GetField("price")
	end
	assert(sum == 35, "Sum should be 35 (15 + 20)")
	print("|cff00ff00  PASS - Iterator working|r")
	
	print("|cff00ff00=== All Phase 2 Tests PASSED! ===|r")
	print("|cffffff00Database System is ready for Phase 3 (UI Components)!|r")
end

-- Advanced Database Test: Auction Example
function TestPhase2Auction()
	local TSM = _G.TSM
	local Schema = TSM.Database.Schema
	local Database = TSM.Database.Database
	
	print("|cff00ff00=== Phase 2 Auction Database Example ===|r")
	
	-- Create auction schema
	local auctionSchema = Schema()
		:AddStringField("itemString")
		:AddNumberField("buyout")
		:AddStringField("seller")
		:AddNumberField("stackSize")
		:AddNumberField("timeLeft")
		:SetPrimaryKey("itemString")
		:AddIndex("seller")  -- Fast seller lookups
	
	-- Create database
	local db = Database("AuctionDB")
	local auctions = db:CreateTable("auctions", auctionSchema)
	
	-- Insert auction data
	auctions:Insert({
		itemString = "i:2589",  -- Linen Cloth
		buyout = 1000,  -- 10 silver
		seller = "Player1",
		stackSize = 20,
		timeLeft = 3600,
	})
	
	auctions:Insert({
		itemString = "i:2592",  -- Wool Cloth
		buyout = 2500,
		seller = "Player1",
		stackSize = 20,
		timeLeft = 7200,
	})
	
	auctions:Insert({
		itemString = "i:2589",  -- Another Linen Cloth
		buyout = 900,  -- Cheaper!
		seller = "Player2",
		stackSize = 20,
		timeLeft = 1800,
	})
	
	-- Test 1: Find cheapest Linen Cloth
	print("Finding cheapest Linen Cloth...")
	local cheapestLinen = auctions:NewQuery()
		:Equal("itemString", "i:2589")
		:OrderBy("buyout", true)
		:First()
	assert(cheapestLinen:GetField("buyout") == 900, "Should find 9s auction")
	assert(cheapestLinen:GetField("seller") == "Player2", "Seller should be Player2")
	print("|cff00ff00  Found: " .. cheapestLinen:GetField("buyout") .. "c by " .. cheapestLinen:GetField("seller") .. "|r")
	
	-- Test 2: Find all of Player1's auctions
	print("Finding all Player1 auctions...")
	local player1Auctions = auctions:NewQuery()
		:Equal("seller", "Player1")
		:Execute()
	assert(#player1Auctions == 2, "Player1 should have 2 auctions")
	TSM.TempTable.Release(player1Auctions)
	print("|cff00ff00  Found 2 auctions|r")
	
	-- Test 3: Find auctions expiring soon
	print("Finding auctions expiring soon (<1 hour)...")
	local expiringSoon = auctions:NewQuery()
		:LessThan("timeLeft", 3600)
		:Count()
	assert(expiringSoon == 1, "Should find 1 expiring soon")
	print("|cff00ff00  Found " .. expiringSoon .. " auction expiring soon|r")
	
	-- Test 4: Find all auctions under 15 silver
	print("Finding cheap auctions (<15s)...")
	local cheapAuctions = auctions:NewQuery()
		:LessThan("buyout", 1500)
		:Execute()
	assert(#cheapAuctions == 2, "Should find 2 cheap auctions")
	
	for i, auction in ipairs(cheapAuctions) do
		local buyout = auction:GetField("buyout")
		print(string.format("|cff00ff00  %d. %s for %dg%ds%dc by %s|r", 
			i,
			auction:GetField("itemString"),
			buyout / 10000,
			(buyout % 10000) / 100,
			buyout % 100,
			auction:GetField("seller")
		))
	end
	
	TSM.TempTable.Release(cheapAuctions)
	
	print("|cff00ff00=== Auction Database Example PASSED! ===|r")
	print("|cffffff00This is how auction queries will work in TSM!|r")
end

-- Performance Test
function TestPhase2Performance()
	local TSM = _G.TSM
	local Schema = TSM.Database.Schema
	local Database = TSM.Database.Database
	
	print("|cff00ff00=== Phase 2 Performance Test ===|r")
	
	-- Create schema
	local schema = Schema()
		:AddNumberField("id")
		:AddStringField("data")
		:SetPrimaryKey("id")
	
	local db = Database("PerfDB")
	local table = db:CreateTable("items", schema)
	
	-- Insert 1000 rows
	print("Inserting 1000 rows...")
	local startTime = GetTime()
	for i = 1, 1000 do
		table:Insert({id = i, data = "Item" .. i})
	end
	local insertTime = GetTime() - startTime
	print(string.format("|cff00ff00  Inserted 1000 rows in %.3f seconds|r", insertTime))
	
	-- Query test
	print("Querying for items with id > 500...")
	startTime = GetTime()
	local results = table:NewQuery():GreaterThan("id", 500):Execute()
	local queryTime = GetTime() - startTime
	print(string.format("|cff00ff00  Found %d rows in %.3f seconds|r", #results, queryTime))
	TSM.TempTable.Release(results)
	
	-- Iterator test
	print("Iterating all rows...")
	startTime = GetTime()
	local count = 0
	for i, row in table:NewQuery():Iterator() do
		count = count + 1
	end
	local iterTime = GetTime() - startTime
	print(string.format("|cff00ff00  Iterated %d rows in %.3f seconds|r", count, iterTime))
	
	print("|cff00ff00=== Performance Test Complete! ===|r")
end

