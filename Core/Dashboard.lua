-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster: Modern                           --
--          https://github.com/XiusTV/Modern-TSM-335                            --
--               All Rights Reserved - Backport to 3.3.5                        --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...) or _G.TSM
if not TSM then error("TSM not found!") return end

local Dashboard = {}
local private = {
	mainFrame = nil,
	characterGuilds = {},
	unselectedCharacters = {},
	selectedTimeRange = nil,
	graphData = {},
	graphMode = "gold", -- gold, gold_sales, gold_expenses, all
	accountingAvailable = false,
	detailsPanelVisible = true,
}

local SECONDS_PER_DAY = 60 * 60 * 24
local TIME_RANGES = {
	{key = "1d", label = "1D", seconds = SECONDS_PER_DAY},
	{key = "1w", label = "1W", seconds = SECONDS_PER_DAY * 7},
	{key = "1m", label = "1M", seconds = SECONDS_PER_DAY * 30},
	{key = "3m", label = "3M", seconds = SECONDS_PER_DAY * 91},
	{key = "6m", label = "6M", seconds = SECONDS_PER_DAY * 183},
	{key = "1y", label = "1Y", seconds = SECONDS_PER_DAY * 365},
	{key = "all", label = "All", seconds = -1},
}

local GRAPH_MODES = {
	{key = "gold", label = "Gold Only"},
	{key = "gold_sales", label = "Gold + Sales"},
	{key = "gold_expenses", label = "Gold + Expenses"},
	{key = "all", label = "All Data"},
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Safe SetColorTexture wrapper that works on 3.3.5 clients
local function SafeSetColorTexture(texture, r, g, b, a)
	if not texture then return end
	a = a or 1
	if texture.SetColorTexture then
		-- Modern API available
		texture:SetColorTexture(r, g, b, a)
	else
		-- Fallback for 3.3.5: use white texture with vertex color
		texture:SetTexture("Interface\\Buttons\\WHITE8X8")
		texture:SetVertexColor(r, g, b, a)
	end
end

-- ============================================================================
-- Initialization
-- ============================================================================

function Dashboard.Initialize()
	-- Initialize GoldTracker
	TSM.GoldTracker.Initialize()
	
	-- Initialize AccountingTracker
	if TSM.AccountingTracker then
		private.accountingAvailable = TSM.AccountingTracker.Initialize()
	end
end

-- ============================================================================
-- UI Creation
-- ============================================================================

function Dashboard.Show()
	if private.mainFrame and private.mainFrame:IsShown() then
		private.mainFrame:Hide()
		return
	end
	
	if not private.mainFrame then
		private.CreateMainFrame()
	end
	
	private.RefreshData()
	private.mainFrame:Show()
end

function Dashboard.ShowEmbedded(parentFrame)
	-- Create embedded dashboard that fits in TSM options
	-- Note: Cleanup is handled by Options.lua when switching away from Analytics tab
	private.CreateEmbeddedDashboard(parentFrame)
end

function Dashboard.HideEmbedded()
	-- Clean up embedded dashboard
	if private.embeddedFrame then
		-- Release the graph widget first
		if private.embeddedFrame.graph then
			private.embeddedFrame.graph:Release()
			private.embeddedFrame.graph = nil
		end
		
		-- Get all child frames and destroy them
		local children = { private.embeddedFrame:GetChildren() }
		for _, child in ipairs(children) do
			if child.Release then
				child:Release() -- AceGUI widget
			else
				child:Hide()
				child:SetParent(nil)
			end
		end
		
		-- Get all child regions (textures, font strings)
		local regions = { private.embeddedFrame:GetRegions() }
		for _, region in ipairs(regions) do
			if region.SetTexture then
				region:SetTexture(nil)
			end
			region:Hide()
		end
		
		-- Clear mainFrame reference if it was pointing to embedded frame
		if private.mainFrame == private.embeddedFrame then
			private.mainFrame = nil
		end
		
		-- Finally destroy the main frame
		private.embeddedFrame:Hide()
		private.embeddedFrame:SetParent(nil)
		private.embeddedFrame = nil
	end
	
	-- Clean up character menu if open
	if private.characterMenu then
		private.characterMenu:Hide()
		private.characterMenu:SetParent(nil)
		private.characterMenu = nil
	end
end

function private.CreateMainFrame()
	-- Create main frame
	local frame = CreateFrame("Frame", "TSMDashboardFrame", UIParent)
	frame:SetSize(950, 700)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	
	-- Background
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	SafeSetColorTexture(bg, 0.05, 0.05, 0.05, 0.95)
	frame.bg = bg
	
	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -10)
	if private.accountingAvailable then
		title:SetText("|cffffd700TSM Dashboard - Gold Tracking & Analytics|r")
	else
		title:SetText("|cffffd700TSM Dashboard - Gold Tracking|r")
	end
	frame.title = title
	
	-- Close button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -5, -5)
	closeBtn:SetScript("OnClick", function()
		-- Close any open character menu
		if private.characterMenu and private.characterMenu:IsShown() then
			private.characterMenu:Hide()
		end
		frame:Hide()
	end)
	frame.closeBtn = closeBtn
	
	-- Header frame for controls
	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT", 10, -40)
	header:SetPoint("TOPRIGHT", -10, -40)
	header:SetHeight(30)
	frame.header = header
	
	-- Time range buttons
	private.CreateTimeRangeButtons(header)
	
	-- Character selection (always show, but simpler without accounting)
	private.CreateCharacterSelector(header)
	
	-- Graph mode selector (if accounting available)
	if private.accountingAvailable then
		private.CreateGraphModeSelector(header)
	end
	
	-- Graph frame
	local graphFrame = CreateFrame("Frame", nil, frame)
	graphFrame:SetPoint("TOPLEFT", 10, -80)
	graphFrame:SetPoint("TOPRIGHT", -10, -80)
	graphFrame:SetHeight(250)
	frame.graphFrame = graphFrame
	
	-- Create graph using our TSMGraph component
	local AceGUI = LibStub("AceGUI-3.0")
	local graph = AceGUI:Create("TSMGraph")
	graph.frame:SetParent(graphFrame)
	graph.frame:SetAllPoints()
	frame.graph = graph
	
	-- Stats frame (expanded for sales/expenses)
	local statsFrame = CreateFrame("Frame", nil, frame)
	statsFrame:SetPoint("TOPLEFT", 10, -340)
	statsFrame:SetPoint("TOPRIGHT", -10, -340)
	statsFrame:SetHeight(private.accountingAvailable and 80 or 40)
	
	local statsBg = statsFrame:CreateTexture(nil, "BACKGROUND")
	statsBg:SetAllPoints()
	SafeSetColorTexture(statsBg, 0.15, 0.15, 0.15, 0.8)
	
	-- Create stats sections
	private.CreateStatsSection(statsFrame)
	frame.statsFrame = statsFrame
	
	-- Details panel (transaction history & top items)
	if private.accountingAvailable then
		private.CreateDetailsPanel(frame)
	end
	
	private.mainFrame = frame
end

function private.CreateTimeRangeButtons(parent)
	local buttons = {}
	local xOffset = 0
	
	for i, range in ipairs(TIME_RANGES) do
		local btn = CreateFrame("Button", nil, parent)
		btn:SetSize(35, 22)
		btn:SetPoint("LEFT", xOffset, 0)
		
		local btnBg = btn:CreateTexture(nil, "BACKGROUND")
		btnBg:SetAllPoints()
		SafeSetColorTexture(btnBg, 0.2, 0.2, 0.2, 1)
		btn.bg = btnBg
		
		local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		btnText:SetPoint("CENTER")
		btnText:SetText(range.label)
		btn.text = btnText
		
		btn.range = range
		btn:SetScript("OnClick", function(self)
			private.OnTimeRangeClicked(self.range)
		end)
		
		btn:SetScript("OnEnter", function(self)
			SafeSetColorTexture(self.bg, 0.3, 0.3, 0.3, 1)
		end)
		
		btn:SetScript("OnLeave", function(self)
			if private.selectedTimeRange == self.range.key then
				SafeSetColorTexture(self.bg, 0.4, 0.35, 0, 1) -- Gold for selected
			else
				SafeSetColorTexture(self.bg, 0.2, 0.2, 0.2, 1)
			end
		end)
		
		buttons[range.key] = btn
		xOffset = xOffset + 40
	end
	
	parent.timeButtons = buttons
	private.selectedTimeRange = "all"
	SafeSetColorTexture(buttons["all"].bg, 0.4, 0.35, 0, 1)
end

function private.CreateCharacterSelector(parent)
	-- Create dropdown button
	local dropdown = CreateFrame("Button", nil, parent)
	dropdown:SetSize(120, 22)
	dropdown:SetPoint("LEFT", 290, 0)
	
	local dropdownBg = dropdown:CreateTexture(nil, "BACKGROUND")
	dropdownBg:SetAllPoints()
	SafeSetColorTexture(dropdownBg, 0.2, 0.2, 0.2, 1)
	dropdown.bg = dropdownBg
	
	local dropdownText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	dropdownText:SetPoint("CENTER", 0, 0)
	dropdownText:SetText("All Characters")
	dropdown.text = dropdownText
	
	dropdown:SetScript("OnEnter", function(self)
		SafeSetColorTexture(self.bg, 0.3, 0.3, 0.3, 1)
	end)
	
	dropdown:SetScript("OnLeave", function(self)
		SafeSetColorTexture(self.bg, 0.2, 0.2, 0.2, 1)
	end)
	
	dropdown:SetScript("OnClick", function(self)
		private.ShowCharacterMenu(self)
	end)
	
	parent.characterDropdown = dropdown
end

function private.ShowCharacterMenu(anchor)
	-- Close existing menu if open
	if private.characterMenu and private.characterMenu:IsShown() then
		private.characterMenu:Hide()
		return
	end
	
	-- Create menu frame
	local menu = CreateFrame("Frame", nil, UIParent)
	menu:SetSize(200, 300)
	menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	menu:SetFrameStrata("TOOLTIP")
	menu:EnableMouse(true)
	
	-- Store reference so we can close it later
	private.characterMenu = menu
	
	local bg = menu:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	SafeSetColorTexture(bg, 0.1, 0.1, 0.1, 0.95)
	menu.bg = bg
	
	local border = menu:CreateTexture(nil, "BORDER")
	border:SetAllPoints()
	SafeSetColorTexture(border, 0.4, 0.4, 0.4, 1)
	border:SetDrawLayer("BORDER", -1)
	
	-- Close button
	local closeBtn = CreateFrame("Button", nil, menu)
	closeBtn:SetSize(20, 20)
	closeBtn:SetPoint("TOPRIGHT", -2, -2)
	closeBtn:SetNormalFontObject("GameFontNormalSmall")
	closeBtn:SetText("×")
	closeBtn:SetScript("OnClick", function() menu:Hide() end)
	
	-- Title
	local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -10)
	title:SetText("|cffffd700Select Characters|r")
	
	-- Select All button
	local selectAll = CreateFrame("Button", nil, menu)
	selectAll:SetSize(90, 20)
	selectAll:SetPoint("TOPLEFT", 10, -35)
	local selectAllBg = selectAll:CreateTexture(nil, "BACKGROUND")
	selectAllBg:SetAllPoints()
	SafeSetColorTexture(selectAllBg, 0.2, 0.5, 0.2, 1)
	selectAll.bg = selectAllBg
	local selectAllText = selectAll:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	selectAllText:SetPoint("CENTER")
	selectAllText:SetText("Select All")
	selectAll:SetScript("OnClick", function()
		wipe(private.unselectedCharacters)
		private.RefreshGraph()
		private.UpdateCharacterDropdownText()
		menu:Hide()
	end)
	
	-- Deselect All button
	local deselectAll = CreateFrame("Button", nil, menu)
	deselectAll:SetSize(90, 20)
	deselectAll:SetPoint("TOPRIGHT", -10, -35)
	local deselectAllBg = deselectAll:CreateTexture(nil, "BACKGROUND")
	deselectAllBg:SetAllPoints()
	SafeSetColorTexture(deselectAllBg, 0.5, 0.2, 0.2, 1)
	deselectAll.bg = deselectAllBg
	local deselectAllText = deselectAll:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	deselectAllText:SetPoint("CENTER")
	deselectAllText:SetText("Deselect All")
	deselectAll:SetScript("OnClick", function()
		for _, char in ipairs(private.characterGuilds) do
			private.unselectedCharacters[char] = true
		end
		private.RefreshGraph()
		private.UpdateCharacterDropdownText()
		menu:Hide()
	end)
	
	-- Character list
	local yOffset = -65
	for i, char in ipairs(private.characterGuilds) do
		local checkbox = CreateFrame("CheckButton", nil, menu)
		checkbox:SetSize(16, 16)
		checkbox:SetPoint("TOPLEFT", 10, yOffset)
		
		local checkBg = checkbox:CreateTexture(nil, "BACKGROUND")
		checkBg:SetAllPoints()
		SafeSetColorTexture(checkBg, 0.2, 0.2, 0.2, 1)
		
		local check = checkbox:CreateTexture(nil, "OVERLAY")
		check:SetSize(12, 12)
		check:SetPoint("CENTER")
		SafeSetColorTexture(check, 0, 1, 0, 1)
		checkbox.check = check
		
		-- Set initial state
		local isSelected = not private.unselectedCharacters[char]
		check:SetShown(isSelected)
		
		checkbox:SetScript("OnClick", function(self)
			local nowSelected = not self.check:IsShown()
			self.check:SetShown(nowSelected)
			
			if nowSelected then
				private.unselectedCharacters[char] = nil
			else
				private.unselectedCharacters[char] = true
			end
			
			private.RefreshGraph()
			private.UpdateCharacterDropdownText()
		end)
		
		-- Character name (truncate "- Warcraft Reborn" and similar)
		local displayName = char
		-- Remove "- Warcraft Reborn" and similar realm suffixes
		displayName = displayName:gsub("%s*%-%s*Warcraft Reborn", "")
		displayName = displayName:gsub("%s*%-%s*Ascension", "")
		
		local name = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		name:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
		name:SetText(displayName)
		
		yOffset = yOffset - 25
		
		-- Stop if we run out of room
		if yOffset < -270 then
			break
		end
	end
	
	menu:Show()
	
	-- Close on escape or click outside
	menu:SetScript("OnHide", function(self)
		if private.characterMenu == self then
			private.characterMenu = nil
		end
		self:SetParent(nil)
		self = nil
	end)
end

function private.UpdateCharacterDropdownText()
	if not private.mainFrame or not private.mainFrame.header.characterDropdown then
		return
	end
	
	local selectedCount = #private.characterGuilds
	for _ in pairs(private.unselectedCharacters) do
		selectedCount = selectedCount - 1
	end
	
	if selectedCount == 0 then
		private.mainFrame.header.characterDropdown.text:SetText("No Characters")
	elseif selectedCount == #private.characterGuilds then
		private.mainFrame.header.characterDropdown.text:SetText("All Characters")
	else
		private.mainFrame.header.characterDropdown.text:SetText(selectedCount .. " Selected")
	end
end

function private.CreateGraphModeSelector(parent)
	local xOffset = 420
	
	-- Label
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", xOffset, 0)
	label:SetText("Graph Mode:")
	label:SetTextColor(0.7, 0.7, 0.7)
	xOffset = xOffset + 85
	
	local buttons = {}
	for i, mode in ipairs(GRAPH_MODES) do
		local btn = CreateFrame("Button", nil, parent)
		btn:SetSize(75, 22)
		btn:SetPoint("LEFT", xOffset, 0)
		
		local btnBg = btn:CreateTexture(nil, "BACKGROUND")
		btnBg:SetAllPoints()
		SafeSetColorTexture(btnBg, 0.2, 0.2, 0.2, 1)
		btn.bg = btnBg
		
		local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		btnText:SetPoint("CENTER")
		btnText:SetText(mode.label)
		btnText:SetFont(btnText:GetFont(), 9)
		btn.text = btnText
		
		btn.mode = mode
		btn:SetScript("OnClick", function(self)
			private.OnGraphModeClicked(self.mode)
		end)
		
		btn:SetScript("OnEnter", function(self)
			SafeSetColorTexture(self.bg, 0.3, 0.3, 0.3, 1)
		end)
		
		btn:SetScript("OnLeave", function(self)
			if private.graphMode == self.mode.key then
				SafeSetColorTexture(self.bg, 0.15, 0.4, 0.15, 1) -- Green for selected
			else
				SafeSetColorTexture(self.bg, 0.2, 0.2, 0.2, 1)
			end
		end)
		
		buttons[mode.key] = btn
		xOffset = xOffset + 80
	end
	
	parent.graphModeButtons = buttons
	SafeSetColorTexture(buttons["gold"].bg, 0.15, 0.4, 0.15, 1)
end

function private.CreateStatsSection(parent)
	if private.accountingAvailable then
		-- Gold section
		local goldLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		goldLabel:SetPoint("TOPLEFT", 10, -10)
		goldLabel:SetText("|cffffd700GOLD|r")
		
		local goldText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		goldText:SetPoint("TOPLEFT", 10, -25)
		goldText:SetText("Loading...")
		parent.goldText = goldText
		
		-- Sales section
		local salesLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		salesLabel:SetPoint("TOPLEFT", 250, -10)
		salesLabel:SetText("|cff00ff00SALES|r")
		
		local salesText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		salesText:SetPoint("TOPLEFT", 250, -25)
		salesText:SetText("Loading...")
		parent.salesText = salesText
		
		-- Expenses section
		local expensesLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		expensesLabel:SetPoint("TOPLEFT", 490, -10)
		expensesLabel:SetText("|cffff0000EXPENSES|r")
		
		local expensesText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		expensesText:SetPoint("TOPLEFT", 490, -25)
		expensesText:SetText("Loading...")
		parent.expensesText = expensesText
		
		-- Profit section
		local profitLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		profitLabel:SetPoint("TOPLEFT", 730, -10)
		profitLabel:SetText("|cff00ffffPROFIT|r")
		
		local profitText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		profitText:SetPoint("TOPLEFT", 730, -25)
		profitText:SetText("Loading...")
		parent.profitText = profitText
	else
		-- Simple gold stats (old style)
		local statsText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		statsText:SetPoint("CENTER")
		statsText:SetText("Loading...")
		parent.text = statsText
	end
end

function private.CreateDetailsPanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetPoint("TOPLEFT", 10, -430)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)
	
	local panelBg = panel:CreateTexture(nil, "BACKGROUND")
	panelBg:SetAllPoints()
	SafeSetColorTexture(panelBg, 0.1, 0.1, 0.1, 0.9)
	
	-- Title with toggle
	local titleBtn = CreateFrame("Button", nil, panel)
	titleBtn:SetPoint("TOPLEFT", 5, -5)
	titleBtn:SetPoint("TOPRIGHT", -5, -5)
	titleBtn:SetHeight(20)
	
	local titleText = titleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleText:SetPoint("LEFT", 5, 0)
	titleText:SetText("|cffffd700▼ Transaction Details|r")
	titleBtn.text = titleText
	
	titleBtn:SetScript("OnClick", function(self)
		private.detailsPanelVisible = not private.detailsPanelVisible
		if private.detailsPanelVisible then
			self.text:SetText("|cffffd700▼ Transaction Details|r")
			panel.content:Show()
		else
			self.text:SetText("|cffffd700► Transaction Details|r")
			panel.content:Hide()
		end
	end)
	
	-- Content frame
	local content = CreateFrame("Frame", nil, panel)
	content:SetPoint("TOPLEFT", 5, -30)
	content:SetPoint("BOTTOMRIGHT", -5, 5)
	panel.content = content
	
	-- Top items section (left)
	local topItemsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	topItemsLabel:SetPoint("TOPLEFT", 5, -5)
	topItemsLabel:SetText("|cff00ff00Top 5 Sellers|r")
	
	local topItemsText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	topItemsText:SetPoint("TOPLEFT", 5, -20)
	topItemsText:SetText("Loading...")
	topItemsText:SetJustifyH("LEFT")
	content.topItemsText = topItemsText
	
	-- Top expenses section (middle)
	local topExpensesLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	topExpensesLabel:SetPoint("TOPLEFT", 320, -5)
	topExpensesLabel:SetText("|cffff0000Top 5 Expenses|r")
	
	local topExpensesText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	topExpensesText:SetPoint("TOPLEFT", 320, -20)
	topExpensesText:SetText("Loading...")
	topExpensesText:SetJustifyH("LEFT")
	content.topExpensesText = topExpensesText
	
	-- Recent transactions (right)
	local recentLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	recentLabel:SetPoint("TOPLEFT", 635, -5)
	recentLabel:SetText("|cff00ffffRecent Transactions|r")
	
	local recentText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	recentText:SetPoint("TOPLEFT", 635, -20)
	recentText:SetText("Loading...")
	recentText:SetJustifyH("LEFT")
	content.recentText = recentText
	
	parent.detailsPanel = panel
end

function private.OnTimeRangeClicked(range)
	private.selectedTimeRange = range.key
	
	-- Update button colors (works for both standalone and embedded)
	local header = (private.mainFrame and private.mainFrame.header) or (private.embeddedFrame and private.embeddedFrame.header)
	if header and header.timeButtons then
		for key, btn in pairs(header.timeButtons) do
			if key == range.key then
				SafeSetColorTexture(btn.bg, 0.4, 0.35, 0, 1) -- Gold
			else
				SafeSetColorTexture(btn.bg, 0.2, 0.2, 0.2, 1)
			end
		end
	end
	
	-- Refresh appropriate graph
	if private.embeddedFrame then
		private.RefreshEmbeddedDashboard()
	else
		private.RefreshGraph()
	end
end

function private.OnGraphModeClicked(mode)
	private.graphMode = mode.key
	
	-- Update button colors (works for both standalone and embedded)
	local header = (private.mainFrame and private.mainFrame.header) or (private.embeddedFrame and private.embeddedFrame.header)
	if header and header.graphModeButtons then
		for key, btn in pairs(header.graphModeButtons) do
			if key == mode.key then
				SafeSetColorTexture(btn.bg, 0.15, 0.4, 0.15, 1) -- Green
			else
				SafeSetColorTexture(btn.bg, 0.2, 0.2, 0.2, 1)
			end
		end
	end
	
	-- Refresh appropriate graph
	if private.embeddedFrame then
		private.RefreshEmbeddedDashboard()
	else
		private.RefreshGraph()
	end
end

-- ============================================================================
-- Data Functions
-- ============================================================================

function private.RefreshData()
	-- Get list of characters/guilds
	wipe(private.characterGuilds)
	TSM.GoldTracker.GetCharacterGuilds(private.characterGuilds)
	
	-- Update character dropdown text
	private.UpdateCharacterDropdownText()
	
	private.RefreshGraph()
end

function private.RefreshGraph()
	if not private.mainFrame or not private.mainFrame.graph then
		return
	end
	
	-- Get time range
	local minTime, maxTime = TSM.GoldTracker.GetGraphTimeRange(private.unselectedCharacters)
	local currentTime = time()
	
	-- Apply selected time range
	if private.selectedTimeRange and private.selectedTimeRange ~= "all" then
		for _, range in ipairs(TIME_RANGES) do
			if range.key == private.selectedTimeRange and range.seconds > 0 then
				minTime = currentTime - range.seconds
				maxTime = currentTime
				break
			end
		end
	end
	
	-- Generate gold graph data
	wipe(private.graphData)
	local step = 3600 -- 1 hour
	local numPoints = math.min(100, math.floor((maxTime - minTime) / step))
	step = math.max(step, math.floor((maxTime - minTime) / numPoints))
	
	local goldData = {}
	for t = minTime, maxTime, step do
		local gold = TSM.GoldTracker.GetGoldAtTime(t, private.unselectedCharacters)
		table.insert(goldData, {
			x = t,
			y = gold / 10000, -- Convert copper to gold
		})
	end
	
	-- Add current time point
	local currentGold = TSM.GoldTracker.GetGoldAtTime(currentTime, private.unselectedCharacters)
	table.insert(goldData, {
		x = currentTime,
		y = currentGold / 10000,
	})
	
	-- Update graph based on mode
	if private.accountingAvailable and private.graphMode ~= "gold" and TSM.AccountingTracker.IsAvailable() then
		-- Multi-series mode
		local series = {}
		
		-- Always include gold
		table.insert(series, {
			name = "Gold",
			color = {1, 0.82, 0, 1}, -- Yellow/gold
			data = goldData,
		})
		
		-- Add sales if requested
		if private.graphMode == "gold_sales" or private.graphMode == "all" then
			local salesData = TSM.AccountingTracker.GetSalesTimeSeries(minTime, maxTime, step, nil)
			if #salesData > 0 then
				table.insert(series, {
					name = "Sales",
					color = {0, 1, 0, 1}, -- Green
					data = salesData,
				})
			end
		end
		
		-- Add expenses if requested
		if private.graphMode == "gold_expenses" or private.graphMode == "all" then
			local expenseData = TSM.AccountingTracker.GetExpenseTimeSeries(minTime, maxTime, step, nil)
			if #expenseData > 0 then
				table.insert(series, {
					name = "Expenses",
					color = {1, 0, 0, 1}, -- Red
					data = expenseData,
				})
			end
		end
		
		private.mainFrame.graph:SetData(series)
	else
		-- Single series mode (just gold)
		private.mainFrame.graph:SetData(goldData)
	end
	
	-- Update stats
	private.UpdateStats(minTime, maxTime)
end

function private.UpdateStats(minTime, maxTime)
	if not private.mainFrame or not private.mainFrame.statsFrame then
		return
	end
	
	local currentGold = TSM.GoldTracker.GetGoldAtTime(time(), private.unselectedCharacters)
	
	if private.accountingAvailable and TSM.AccountingTracker.IsAvailable() then
		-- Enhanced stats with sales/expenses
		local stats = TSM.AccountingTracker.GetSummaryStats(minTime, maxTime, nil)
		
		-- Gold stats
		local high, low = 0, math.huge
		for t = minTime, maxTime, 3600 do
			local gold = TSM.GoldTracker.GetGoldAtTime(t, private.unselectedCharacters)
			if gold > high then high = gold end
			if gold < low then low = gold end
		end
		if low == math.huge then low = 0 end
		
		local goldText = string.format(
			"Current: %s\nHigh: %s\nLow: %s",
			private.FormatGold(currentGold),
			private.FormatGold(high),
			private.FormatGold(low)
		)
		private.mainFrame.statsFrame.goldText:SetText(goldText)
		
		-- Sales stats
		local salesText = string.format(
			"Total: %s\nAvg/Day: %s\n%d transactions",
			private.FormatGold(stats.sales.total),
			private.FormatGold(stats.sales.avgPerDay),
			stats.sales.count
		)
		private.mainFrame.statsFrame.salesText:SetText(salesText)
		
		-- Expenses stats
		local expensesText = string.format(
			"Total: %s\nAvg/Day: %s\n%d transactions",
			private.FormatGold(stats.expenses.total),
			private.FormatGold(stats.expenses.avgPerDay),
			stats.expenses.count
		)
		private.mainFrame.statsFrame.expensesText:SetText(expensesText)
		
		-- Profit stats
		local profitText = string.format(
			"Total: %s\nAvg/Day: %s\nMargin: %.1f%%",
			private.FormatGold(stats.profit.total),
			private.FormatGold(stats.profit.avgPerDay),
			stats.sales.total > 0 and (stats.profit.total / stats.sales.total * 100) or 0
		)
		private.mainFrame.statsFrame.profitText:SetText(profitText)
		
		-- Update details panel
		if private.mainFrame.detailsPanel then
			private.UpdateDetailsPanel(minTime, maxTime)
		end
	else
		-- Simple gold stats
		local high, low = 0, math.huge
		for t = minTime, maxTime, 3600 do
			local gold = TSM.GoldTracker.GetGoldAtTime(t, private.unselectedCharacters)
			if gold > high then high = gold end
			if gold < low then low = gold end
		end
		if low == math.huge then low = 0 end
		
		local statsText = string.format(
			"|cffffd700Current:|r %s  |cff00ff00High:|r %s  |cffff0000Low:|r %s  |cffaaaaaa(%d characters/guilds tracked)|r",
			private.FormatGold(currentGold),
			private.FormatGold(high),
			private.FormatGold(low),
			#private.characterGuilds
		)
		
		private.mainFrame.statsFrame.text:SetText(statsText)
	end
end

function private.UpdateDetailsPanel(minTime, maxTime)
	if not private.mainFrame.detailsPanel or not private.mainFrame.detailsPanel.content then
		return
	end
	
	local content = private.mainFrame.detailsPanel.content
	
	-- Top sellers
	local topSellers = TSM.AccountingTracker.GetTopSellers(minTime, maxTime, 5, nil)
	local topSellersText = ""
	for i, item in ipairs(topSellers) do
		topSellersText = topSellersText .. string.format("%d. %s: %s\n",
			i, item.itemName, private.FormatGold(item.total))
	end
	if topSellersText == "" then
		topSellersText = "No sales in this period"
	end
	content.topItemsText:SetText(topSellersText)
	
	-- Top expenses
	local topExpenses = TSM.AccountingTracker.GetTopExpenses(minTime, maxTime, 5, nil)
	local topExpensesText = ""
	for i, item in ipairs(topExpenses) do
		topExpensesText = topExpensesText .. string.format("%d. %s: %s\n",
			i, item.itemName, private.FormatGold(item.total))
	end
	if topExpensesText == "" then
		topExpensesText = "No expenses in this period"
	end
	content.topExpensesText:SetText(topExpensesText)
	
	-- Recent transactions
	local recentSales = TSM.AccountingTracker.GetSalesData(minTime, maxTime, nil)
	local recentExpenses = TSM.AccountingTracker.GetExpenseData(minTime, maxTime, nil)
	
	-- Combine and sort by timestamp
	local allTransactions = {}
	for _, sale in ipairs(recentSales) do
		table.insert(allTransactions, {time = sale.timestamp, type = "SALE", name = sale.itemName, total = sale.total})
	end
	for _, expense in ipairs(recentExpenses) do
		table.insert(allTransactions, {time = expense.timestamp, type = expense.type:upper(), name = expense.itemName, total = expense.total})
	end
	
	table.sort(allTransactions, function(a, b) return a.time > b.time end)
	
	local recentText = ""
	for i = 1, math.min(8, #allTransactions) do
		local tx = allTransactions[i]
		local color = tx.type == "SALE" and "|cff00ff00" or "|cffff0000"
		recentText = recentText .. string.format("%s%s|r: %s\n%s\n",
			color, tx.type, tx.name, private.FormatGold(tx.total))
	end
	if recentText == "" then
		recentText = "No recent transactions"
	end
	content.recentText:SetText(recentText)
end

function private.FormatGold(copper)
	-- Use TSMAPI for money formatting (not TSM)
	return TSMAPI:FormatTextMoney(copper, "|cffffd700", true)
end

-- ============================================================================
-- Embedded Dashboard (for TSM Options)
-- ============================================================================

function private.CreateEmbeddedDashboard(parentFrame)
	-- Create container frame
	local frame = CreateFrame("Frame", nil, parentFrame)
	frame:SetAllPoints()
	
	-- Background
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	SafeSetColorTexture(bg, 0.05, 0.05, 0.05, 0.5)
	
	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -10)
	title:SetText("|cffffd700Gold Tracking & Analytics|r")
	
	-- Controls frame
	local controlsFrame = CreateFrame("Frame", nil, frame)
	controlsFrame:SetPoint("TOPLEFT", 10, -40)
	controlsFrame:SetPoint("TOPRIGHT", -10, -40)
	controlsFrame:SetHeight(30)
	controlsFrame:Show()
	
	-- Time range buttons
	private.CreateTimeRangeButtons(controlsFrame)
	
	-- Character selector button (reuse same function as standalone)
	private.CreateCharacterSelector(controlsFrame)
	-- Store embedded frame reference
	frame.header = controlsFrame
	
	-- Graph mode selector (if accounting available)
	if private.accountingAvailable then
		private.CreateGraphModeSelector(controlsFrame)
	end
	
	-- Graph area
	local graphFrame = CreateFrame("Frame", nil, frame)
	graphFrame:SetPoint("TOPLEFT", 10, -80)
	graphFrame:SetPoint("TOPRIGHT", -10, -80)
	graphFrame:SetHeight(250)
	graphFrame:Show()
	
	-- Create graph
	local AceGUI = LibStub("AceGUI-3.0")
	local graph = AceGUI:Create("TSMGraph")
	graph.frame:SetParent(graphFrame)
	graph.frame:SetAllPoints()
	graph.frame:Show()
	frame.graph = graph
	
	-- Stats frame
	local statsFrame = CreateFrame("Frame", nil, frame)
	statsFrame:SetPoint("TOPLEFT", 10, -340)
	statsFrame:SetPoint("TOPRIGHT", -10, -340)
	statsFrame:SetHeight(private.accountingAvailable and 80 or 40)
	statsFrame:Show()
	
	local statsBg = statsFrame:CreateTexture(nil, "BACKGROUND")
	statsBg:SetAllPoints()
	SafeSetColorTexture(statsBg, 0.15, 0.15, 0.15, 0.8)
	
	private.CreateStatsSection(statsFrame)
	frame.statsFrame = statsFrame
	
	-- Details panel (if accounting available)
	if private.accountingAvailable then
		local detailsFrame = CreateFrame("Frame", nil, frame)
		detailsFrame:SetPoint("TOPLEFT", 10, -430)
		detailsFrame:SetPoint("BOTTOMRIGHT", -10, 10)
		detailsFrame:Show()
		
		local detailsBg = detailsFrame:CreateTexture(nil, "BACKGROUND")
		detailsBg:SetAllPoints()
		SafeSetColorTexture(detailsBg, 0.1, 0.1, 0.1, 0.9)
		
		local detailsTitle = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		detailsTitle:SetPoint("TOP", 0, -10)
		detailsTitle:SetText("|cffffd700Transaction Details|r")
		
		local detailsText = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		detailsText:SetPoint("TOPLEFT", 10, -35)
		detailsText:SetText("Top items and recent transactions will appear here")
		detailsText:SetTextColor(0.6, 0.6, 0.6)
	end
	
	-- Store reference
	private.embeddedFrame = frame
	private.mainFrame = frame -- So character selector works
	
	-- Explicitly show the frame
	frame:Show()
	
	-- Get character list
	wipe(private.characterGuilds)
	TSM.GoldTracker.GetCharacterGuilds(private.characterGuilds)
	private.UpdateCharacterDropdownText()
	
	-- Refresh when frame becomes visible (handles tab switching)
	frame:SetScript("OnShow", function(self)
		if self == private.embeddedFrame then
			private.RefreshEmbeddedDashboard()
		end
	end)
	
	-- Load data after a short delay to prevent freezing
	-- Also refresh immediately if parent is already visible
	C_Timer.After(0.1, function()
		if frame and frame == private.embeddedFrame then
			private.RefreshEmbeddedDashboard()
		end
	end)
end

function private.RefreshEmbeddedDashboard()
	if not private.embeddedFrame or not private.embeddedFrame.graph then
		return
	end
	
	-- Get time range
	local minTime, maxTime = TSM.GoldTracker.GetGraphTimeRange(private.unselectedCharacters)
	local currentTime = time()
	
	-- Apply selected time range
	if private.selectedTimeRange and private.selectedTimeRange ~= "all" then
		for _, range in ipairs(TIME_RANGES) do
			if range.key == private.selectedTimeRange and range.seconds > 0 then
				minTime = currentTime - range.seconds
				maxTime = currentTime
				break
			end
		end
	end
	
	-- Generate gold graph data (use fewer points to avoid lag)
	local step = 7200 -- 2 hours (less points = faster)
	local numPoints = math.min(50, math.floor((maxTime - minTime) / step))
	step = math.max(step, math.floor((maxTime - minTime) / numPoints))
	
	local goldData = {}
	for t = minTime, maxTime, step do
		local gold = TSM.GoldTracker.GetGoldAtTime(t, private.unselectedCharacters)
		table.insert(goldData, {
			x = t,
			y = gold / 10000, -- Convert copper to gold
		})
	end
	
	-- Add current time point
	local currentGold = TSM.GoldTracker.GetGoldAtTime(currentTime, private.unselectedCharacters)
	table.insert(goldData, {
		x = currentTime,
		y = currentGold / 10000,
	})
	
	-- Update graph based on mode
	if private.accountingAvailable and private.graphMode ~= "gold" and TSM.AccountingTracker.IsAvailable() then
		-- Multi-series mode
		local series = {}
		
		-- Always include gold
		table.insert(series, {
			name = "Gold",
			color = {1, 0.82, 0, 1}, -- Yellow/gold
			data = goldData,
		})
		
		-- Add sales if requested
		if private.graphMode == "gold_sales" or private.graphMode == "all" then
			local salesData = TSM.AccountingTracker.GetSalesTimeSeries(minTime, maxTime, step, nil)
			if #salesData > 0 then
				table.insert(series, {
					name = "Sales",
					color = {0, 1, 0, 1}, -- Green
					data = salesData,
				})
			end
		end
		
		-- Add expenses if requested
		if private.graphMode == "gold_expenses" or private.graphMode == "all" then
			local expenseData = TSM.AccountingTracker.GetExpenseTimeSeries(minTime, maxTime, step, nil)
			if #expenseData > 0 then
				table.insert(series, {
					name = "Expenses",
					color = {1, 0, 0, 1}, -- Red
					data = expenseData,
				})
			end
		end
		
		private.embeddedFrame.graph:SetData(series)
	else
		-- Single series mode (just gold)
		if #goldData > 0 then
			private.embeddedFrame.graph:SetData(goldData)
		end
	end
	
	-- Update stats
	if private.embeddedFrame.statsFrame then
		private.UpdateEmbeddedStats(minTime, maxTime, currentGold)
	end
end

function private.UpdateEmbeddedStats(minTime, maxTime, currentGold)
	if not private.embeddedFrame or not private.embeddedFrame.statsFrame then
		return
	end
	
	local statsFrame = private.embeddedFrame.statsFrame
	
	if private.accountingAvailable and TSM.AccountingTracker.IsAvailable() then
		-- Enhanced stats
		local stats = TSM.AccountingTracker.GetSummaryStats(minTime, maxTime, nil)
		
		local goldText = string.format("Current: %s", private.FormatGold(currentGold))
		local salesText = string.format("Total: %s\n%d transactions", private.FormatGold(stats.sales.total), stats.sales.count)
		local expensesText = string.format("Total: %s\n%d transactions", private.FormatGold(stats.expenses.total), stats.expenses.count)
		local profitText = string.format("Total: %s", private.FormatGold(stats.profit.total))
		
		if statsFrame.goldText then
			statsFrame.goldText:SetText(goldText)
		end
		if statsFrame.salesText then
			statsFrame.salesText:SetText(salesText)
		end
		if statsFrame.expensesText then
			statsFrame.expensesText:SetText(expensesText)
		end
		if statsFrame.profitText then
			statsFrame.profitText:SetText(profitText)
		end
	else
		-- Simple stats
		if statsFrame.text then
			local chars = {}
			TSM.GoldTracker.GetCharacterGuilds(chars)
			statsFrame.text:SetText(string.format("|cffffd700Current:|r %s  |cffaaaa(%d characters tracked)|r",
				private.FormatGold(currentGold), #chars))
		end
	end
end

-- ============================================================================
-- Module Registration
-- ============================================================================

TSM.Dashboard = Dashboard
