-- ------------------------------------------------------------------------------ --
--                        TradeSkillMaster_CsvExtractor                           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.   --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_CsvExtractor", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_CsvExtractor")

-- Get reference to TSM core
local TSMCore = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster")

-- Field definitions
local FIELDS = {
	{ key = "itemId", label = L["Item ID"], default = true },
	{ key = "itemName", label = L["Item Name"], default = true },
	{ key = "itemLink", label = L["Item Link"], default = false },
	{ key = "marketValue", label = L["Market Value"], default = true },
	{ key = "minBuyout", label = L["Min Buyout"], default = true },
	{ key = "craftingCost", label = L["Crafting Cost"], default = false },
	{ key = "vendorSell", label = L["Vendor Sell Price"], default = false },
	{ key = "itemLevel", label = L["Item Level"], default = false },
	{ key = "quality", label = L["Quality"], default = false },
	{ key = "stackSize", label = L["Stack Size"], default = false },
	{ key = "totalStock", label = L["Total Stock"], default = false },
}

-- Default saved variables
local savedDBDefaults = {
	profile = {
		selectedGroup = nil,
		includeHeaders = true,
		fields = {},
	},
}

-- Initialize default field settings
for _, field in ipairs(FIELDS) do
	savedDBDefaults.profile.fields[field.key] = field.default
end

function TSM:OnInitialize()
	-- Load saved variables
	TSM.db = LibStub("AceDB-3.0"):New("AscensionTSM_CsvExtractorDB", savedDBDefaults, true)

	-- Make module references accessible on TSM object (required for callback strings like "Config:Load")
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end

	-- Register module with TSM
	TSM:RegisterModule()
end

function TSM:RegisterModule()
	TSM.icons = {
		{ side = "module", desc = "CsvExtractor", slashCommand = "csvextract", callback = "Config:Load", icon = "Interface\\Icons\\INV_Scroll_03" },
	}

	TSM.slashCommands = {
		{ key = "csvexport", label = L["CSV Extractor"], callback = function() TSMAPI:OpenFrame() end },
	}

	TSMAPI:NewModule(TSM)
end

-- ============================================================================
-- Config Module (for TSM icon callback)
-- ============================================================================

local Config = TSM:NewModule("Config", "AceEvent-3.0")

function Config:Load(parent)
	local Options = TSM:GetModule("Options")
	Options:Load(parent)
end

-- ============================================================================
-- Options Module
-- ============================================================================

local Options = TSM:NewModule("Options", "AceEvent-3.0")

function Options:Load(parent)
	Options.treeGroup = AceGUI:Create("TSMTreeGroup")
	Options.treeGroup:SetLayout("Fill")
	Options.treeGroup:SetCallback("OnGroupSelected", function(...) Options:SelectTree(...) end)
	parent:AddChild(Options.treeGroup)

	Options:UpdateTree()
	Options.treeGroup:SelectByPath(1)
end

function Options:UpdateTree()
	Options.treeGroup:SetTree({
		{ value = 1, text = L["Help"] },
		{ value = 2, text = L["Export"] },
	})
end

function Options:SelectTree(treeGroup, _, selection)
	treeGroup:ReleaseChildren()

	local major = tonumber(selection)
	if major == 1 then
		Options:DrawHelp(treeGroup)
	elseif major == 2 then
		Options:DrawExport(treeGroup)
	end
end

function Options:DrawHelp(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["CSV Extractor"],
					children = {
						{
							type = "Label",
							text = L["CsvExtractor allows you to export items from a TSM group to CSV format."],
							relativeWidth = 1,
						},
						{
							type = "Label",
							text = L["Select a group, choose the fields you want to export, and click Export."],
							relativeWidth = 1,
						},
						{
							type = "Label",
							text = L["The CSV output will be displayed in a text box that you can copy."],
							relativeWidth = 1,
						},
					},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function Options:DrawExport(container)
	-- Get list of groups for dropdown
	local groupList = Options:GetGroupList()

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Select Group"],
					children = {
						{
							type = "Dropdown",
							label = L["Select Group"],
							list = groupList,
							value = TSM.db.profile.selectedGroup,
							relativeWidth = 1,
							callback = function(_, _, value)
								TSM.db.profile.selectedGroup = value
							end,
							tooltip = L["Select the TSM group to export."],
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Options"],
					children = {
						{
							type = "CheckBox",
							label = L["Include Headers"],
							settingInfo = { TSM.db.profile, "includeHeaders" },
							relativeWidth = 1,
							tooltip = L["Include column headers in the CSV output."],
						},
					},
				},
				{
					type = "Spacer",
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Fields to Export"],
					children = Options:GetFieldCheckboxes(),
				},
				{
					type = "Spacer",
				},
				{
					type = "Button",
					text = L["Export"],
					relativeWidth = 0.3,
					callback = function()
						Options:DoExport()
					end,
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function Options:GetGroupList()
	local list = {}
	local groupPaths = TSMCore:GetGroupPathList()

	for _, groupPath in ipairs(groupPaths) do
		-- Format group path for display (replace ` with ->)
		local displayName = TSMAPI:FormatGroupPath(groupPath)
		list[groupPath] = displayName
	end

	return list
end

function Options:GetFieldCheckboxes()
	local children = {}

	for _, field in ipairs(FIELDS) do
		tinsert(children, {
			type = "CheckBox",
			label = field.label,
			settingInfo = { TSM.db.profile.fields, field.key },
			relativeWidth = 0.5,
		})
	end

	return children
end

function Options:DoExport()
	local groupPath = TSM.db.profile.selectedGroup

	-- Validate group selection
	if not groupPath or groupPath == "" then
		TSM:Print(L["Please select a group first."])
		return
	end

	-- Validate at least one field selected
	local hasField = false
	for _, field in ipairs(FIELDS) do
		if TSM.db.profile.fields[field.key] then
			hasField = true
			break
		end
	end

	if not hasField then
		TSM:Print(L["Please select at least one field to export."])
		return
	end

	-- Get all items from the group (including subgroups)
	local items = Options:GetGroupItems(groupPath)

	if not items or not next(items) then
		TSM:Print(L["No items found in the selected group."])
		return
	end

	-- Generate CSV
	local csv = Options:GenerateCSV(items)

	-- Show export dialog
	Options:ShowExportDialog(csv, #items)
end

function Options:GetGroupItems(groupPath)
	-- Get all items including subgroups
	local allItems = {}
	local escapedPath = TSMAPI:StrEscape(groupPath)
	local groupSep = TSMCore.GROUP_SEP or "`"

	for itemString, itemPath in pairs(TSMCore.db.profile.items) do
		-- Match exact group or subgroups
		if itemPath == groupPath or strfind(itemPath, "^" .. escapedPath .. groupSep) then
			tinsert(allItems, itemString)
		end
	end

	return allItems
end

function Options:GenerateCSV(items)
	local lines = {}
	local selectedFields = {}

	-- Build list of selected fields
	for _, field in ipairs(FIELDS) do
		if TSM.db.profile.fields[field.key] then
			tinsert(selectedFields, field)
		end
	end

	-- Add header row if enabled
	if TSM.db.profile.includeHeaders then
		local headers = {}
		for _, field in ipairs(selectedFields) do
			tinsert(headers, Options:EscapeCSV(field.label))
		end
		tinsert(lines, table.concat(headers, ","))
	end

	-- Get addon references
	local AuctionDB = LibStub("AceAddon-3.0"):GetAddon("TSM_AuctionDB", true)
	local Crafting = LibStub("AceAddon-3.0"):GetAddon("TSM_Crafting", true)
	local ItemTracker = LibStub("AceAddon-3.0"):GetAddon("TSM_ItemTracker", true)

	-- Sort items by name
	sort(items, function(a, b)
		local nameA = GetItemInfo(a) or ""
		local nameB = GetItemInfo(b) or ""
		return nameA < nameB
	end)

	-- Process each item
	local itemCount = 0
	for _, itemString in ipairs(items) do
		local values = {}
		local itemName, itemLink, quality, itemLevel, _, _, _, stackSize, _, _, vendorPrice = TSMAPI:GetSafeItemInfo(itemString)
		local itemId = TSMAPI:GetItemID(itemString)

		for _, field in ipairs(selectedFields) do
			local value = ""

			if field.key == "itemId" then
				value = itemId or ""
			elseif field.key == "itemName" then
				value = itemName or ""
			elseif field.key == "itemLink" then
				value = itemLink or ""
			elseif field.key == "marketValue" then
				local marketValue = TSMAPI:GetItemValue(itemString, "DBMarket")
				value = marketValue and Options:FormatCopper(marketValue) or ""
			elseif field.key == "minBuyout" then
				local minBuyout = TSMAPI:GetItemValue(itemString, "DBMinBuyout")
				value = minBuyout and Options:FormatCopper(minBuyout) or ""
			elseif field.key == "craftingCost" then
				local craftCost = TSMAPI:GetItemValue(itemString, "Crafting")
				value = craftCost and Options:FormatCopper(craftCost) or ""
			elseif field.key == "vendorSell" then
				value = vendorPrice and Options:FormatCopper(vendorPrice) or ""
			elseif field.key == "itemLevel" then
				value = itemLevel or ""
			elseif field.key == "quality" then
				value = quality or ""
			elseif field.key == "stackSize" then
				value = stackSize or ""
			elseif field.key == "totalStock" then
				if ItemTracker then
					local playerTotal, altTotal = ItemTracker:GetPlayerTotal(itemString)
					local guildTotal = ItemTracker:GetGuildTotal(itemString) or 0
					local auctionTotal = ItemTracker:GetAuctionsTotal(itemString) or 0
					local personalBanksTotal = ItemTracker:GetPersonalBanksTotal(itemString) or 0
					local realmBankTotal = ItemTracker:GetRealmBankTotal(itemString) or 0
					local total = (playerTotal or 0) + (altTotal or 0) + guildTotal + auctionTotal + personalBanksTotal + realmBankTotal
					value = total
				else
					value = ""
				end
			end

			tinsert(values, Options:EscapeCSV(tostring(value)))
		end

		tinsert(lines, table.concat(values, ","))
		itemCount = itemCount + 1
	end

	return table.concat(lines, "\n"), itemCount
end

function Options:EscapeCSV(str)
	if not str then return "" end
	str = tostring(str)
	-- If contains comma, quote, or newline, wrap in quotes and escape quotes
	if strfind(str, '[,"\n]') then
		str = '"' .. gsub(str, '"', '""') .. '"'
	end
	return str
end

function Options:FormatCopper(copper)
	-- Return copper value as a number (for easy spreadsheet use)
	return copper
end

function Options:ShowExportDialog(csv, itemCount)
	-- Create dialog frame
	local frame = AceGUI:Create("TSMWindow")
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame:SetTitle(L["CSV Output"])
	frame:SetLayout("Fill")
	frame:SetWidth(600)
	frame:SetHeight(400)

	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	frame:AddChild(scrollContainer)

	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetLabel(L["Copy the text below (Ctrl+A to select all, Ctrl+C to copy)"])
	editBox:SetFullWidth(true)
	editBox:SetFullHeight(true)
	editBox:SetText(csv)
	editBox:DisableButton(true)
	scrollContainer:AddChild(editBox)

	-- Focus and select all text
	editBox:SetFocus()
	editBox.editBox:HighlightText()

	TSM:Printf(L["Exported %d items to CSV."], itemCount)
end
