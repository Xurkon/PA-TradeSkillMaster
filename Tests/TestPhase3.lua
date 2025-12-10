-- Phase 3 UI Components Tests
-- Run in-game: /run TestPhase3()

function TestPhase3()
	local AceGUI = LibStub("AceGUI-3.0")
	
	print("|cff00ff00=== Phase 3 UI Components Tests ===|r")
	
	-- Test 1: DividedContainer
	print("Test 1: DividedContainer...")
	local div = AceGUI:Create("TSMDividedContainer")
	assert(div, "DividedContainer creation failed")
	assert(div.dividerPosition == 0.5, "Default divider position should be 0.5")
	div:SetDividerPosition(0.3)
	assert(div.dividerPosition == 0.3, "Divider position update failed")
	div:Release()
	print("|cff00ff00  PASS - DividedContainer working|r")
	
	-- Test 2: CollapsibleContainer
	print("Test 2: CollapsibleContainer...")
	local col = AceGUI:Create("TSMCollapsibleContainer")
	assert(col, "CollapsibleContainer creation failed")
	col:SetHeadingText("Test Section")
	assert(col.headingText == "Test Section", "Heading text failed")
	col:SetCollapsed(true)
	assert(col.isCollapsed == true, "Collapse failed")
	col:SetCollapsed(false)
	assert(col.isCollapsed == false, "Expand failed")
	col:Release()
	print("|cff00ff00  PASS - CollapsibleContainer working|r")
	
	-- Test 3: CustomStringInput
	print("Test 3: CustomStringInput...")
	local csi = AceGUI:Create("TSMCustomStringInput")
	assert(csi, "CustomStringInput creation failed")
	csi:SetText("dbmarket")
	assert(csi:GetText() == "dbmarket", "SetText/GetText failed")
	-- Test validation
	local isValid = csi:Validate("dbmarket * 0.95")
	assert(isValid, "Valid string should pass validation")
	csi:Release()
	print("|cff00ff00  PASS - CustomStringInput working|r")
	
	-- Test 4: Graph
	print("Test 4: Graph...")
	local graph = AceGUI:Create("TSMGraph")
	assert(graph, "Graph creation failed")
	local testData = {{x=1, y=10}, {x=2, y=20}, {x=3, y=15}}
	graph:SetData(testData)
	assert(#graph.dataPoints == 3, "Graph data not set correctly")
	graph:Release()
	print("|cff00ff00  PASS - Graph working|r")
	
	print("|cff00ff00=== All Phase 3 Tests PASSED! ===|r")
	print("|cffffff00UI Components ready for Dashboard implementation!|r")
end

-- Visual Test: Simplified Component Demo
function TestPhase3Visual()
	local AceGUI = LibStub("AceGUI-3.0")
	
	print("|cff00ff00=== Phase 3 Visual Demo ===|r")
	print("|cffffff00Creating simplified demo...|r")
	
	-- Test 1: Collapsible Sections Demo
	local sectionsFrame = AceGUI:Create("Window") or AceGUI:Create("Frame")
	sectionsFrame:SetTitle("Collapsible Sections Demo")
	sectionsFrame:SetWidth(400)
	sectionsFrame:SetHeight(300)
	sectionsFrame:SetLayout("List")
	
	-- Section 1
	local section1 = AceGUI:Create("TSMCollapsibleContainer")
	section1:SetHeadingText("Gold Tracking")
	section1:SetFullWidth(true)
	section1:SetContentHeight(80)
	
	-- Add visible content
	local section1Group = AceGUI:Create("SimpleGroup")
	section1Group:SetLayout("Flow")
	local label1a = AceGUI:Create("Label")
	label1a:SetText("|cffffffffClick header to collapse!|r")
	label1a:SetFullWidth(true)
	section1Group:AddChild(label1a)
	local label1b = AceGUI:Create("Label")
	label1b:SetText("|cff00ff00This content will disappear when collapsed.|r")
	label1b:SetFullWidth(true)
	section1Group:AddChild(label1b)
	
	section1:AddChild(section1Group)
	sectionsFrame:AddChild(section1)
	
	-- Section 2
	local section2 = AceGUI:Create("TSMCollapsibleContainer")
	section2:SetHeadingText("Settings")
	section2:SetFullWidth(true)
	section2:SetContentHeight(80)
	
	-- Add visible content
	local section2Group = AceGUI:Create("SimpleGroup")
	section2Group:SetLayout("Flow")
	local label2a = AceGUI:Create("Label")
	label2a:SetText("|cffffffffCollapsible sections = organized UI!|r")
	label2a:SetFullWidth(true)
	section2Group:AddChild(label2a)
	local label2b = AceGUI:Create("Label")
	label2b:SetText("|cff00ff00Watch this text disappear on collapse.|r")
	label2b:SetFullWidth(true)
	section2Group:AddChild(label2b)
	
	section2:AddChild(section2Group)
	sectionsFrame:AddChild(section2)
	
	sectionsFrame.frame:SetPoint("CENTER", -300, 0)
	sectionsFrame.frame:Show()
	
	-- Test 2: Graph Demo (separate window)
	local graphFrame = AceGUI:Create("Window") or AceGUI:Create("Frame")
	graphFrame:SetTitle("Graph Demo")
	graphFrame:SetWidth(500)
	graphFrame:SetHeight(350)
	graphFrame:SetLayout("Fill")
	
	local graph = AceGUI:Create("TSMGraph")
	graph:SetWidth(480)
	graph:SetHeight(280)
	
	-- Simple linear data
	local graphData = {}
	for i = 1, 10 do
		tinsert(graphData, {
			x = i,
			y = 50 + (i * 5)  -- Simple upward trend
		})
	end
	graph:SetData(graphData)
	graphFrame:AddChild(graph)
	
	graphFrame.frame:SetPoint("CENTER", 200, 0)
	graphFrame.frame:Show()
	
	print("|cff00ff00Two demo windows created:|r")
	print("|cffffff00  - Left: Collapsible sections (click headers!)|r")
	print("|cffffff00  - Right: Graph visualization|r")
end

-- Test Graph with Real Data
function TestPhase3Graph()
	local AceGUI = LibStub("AceGUI-3.0")
	
	print("|cff00ff00=== Phase 3 Graph Test ===|r")
	
	-- Create window
	local frame = AceGUI:Create("Window")
	if not frame then
		frame = AceGUI:Create("Frame")
	end
	
	frame:SetTitle("Gold Tracking Graph Demo")
	frame:SetWidth(700)
	frame:SetHeight(400)
	frame:SetLayout("Fill")
	
	-- Create graph
	local graph = AceGUI:Create("TSMGraph")
	frame:AddChild(graph)
	
	-- Generate realistic gold data (30 days)
	local goldData = {}
	local currentTime = time()
	local startGold = 50000  -- 50g starting
	
	for day = 30, 0, -1 do
		local timestamp = currentTime - (day * 86400)
		-- Simulate gold growth with some variation
		local dayProfit = math.random(1000, 5000)
		startGold = startGold + dayProfit
		
		tinsert(goldData, {
			x = timestamp,
			y = startGold
		})
	end
	
	graph:SetData(goldData)
	
	-- Position and show
	frame.frame:SetPoint("CENTER")
	frame.frame:Show()
	
	print("|cff00ff00Graph created with 30 days of gold tracking data!|r")
	print(string.format("|cffffff00Starting: %dg | Ending: %dg | Profit: %dg|r",
		goldData[1].y / 10000,
		goldData[#goldData].y / 10000,
		(goldData[#goldData].y - goldData[1].y) / 10000
	))
end

-- Test All Components Together
function TestPhase3Complete()
	print("|cff00ff00=== Running Complete Phase 3 Test Suite ===|r")
	
	-- Run basic tests
	TestPhase3()
	
	-- Small delay, then show visual demo
	print("|cffffff00Creating visual demo in 2 seconds...|r")
	C_Timer.After(2, function()
		TestPhase3Visual()
	end)
end

