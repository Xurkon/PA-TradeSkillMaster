-- ------------------------------------------------------------------------------ --
--                        TradeSkillMaster_RecraftOnSale                         --
--                              Options Module                                   --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Options = TSM:NewModule("Options", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_RecraftOnSale")

function Options:Load(parent, operation, group)
	Options.currentGroup = group

	Options.treeGroup = AceGUI:Create("TSMTreeGroup")
	Options.treeGroup:SetLayout("Fill")
	Options.treeGroup:SetCallback("OnGroupSelected", function(...) Options:SelectTree(...) end)
	Options.treeGroup:SetStatusTable(TSM.db.global.optionsTreeStatus)
	parent:AddChild(Options.treeGroup)

	Options:UpdateTree()

	if operation then
		Options.treeGroup:SelectByPath(2, operation)
	else
		Options.treeGroup:SelectByPath(1)
	end
end

function Options:UpdateTree()
	local operationTreeChildren = {}
	for name in pairs(TSM.operations) do
		if name ~= "maxOperations" and name ~= "callbackOptions" and name ~= "callbackInfo" then
			tinsert(operationTreeChildren, { value = name, text = name })
		end
	end
	sort(operationTreeChildren, function(a, b) return a.value < b.value end)

	Options.treeGroup:SetTree({
		{ value = 1, text = L["Options"] },
		{ value = 2, text = L["Operations"], children = operationTreeChildren },
	})
end

function Options:SelectTree(treeGroup, _, selection)
	treeGroup:ReleaseChildren()

	local major, minor = ("\001"):split(selection)
	major = tonumber(major)

	if major == 1 then
		Options:DrawGeneralSettings(treeGroup)
	elseif minor then
		Options:DrawOperationSettings(treeGroup, minor)
	else
		Options:DrawNewOperation(treeGroup)
	end
end

function Options:DrawGeneralSettings(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["RecraftOnSale"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["This module automatically adds sold items to your craft queue based on operations assigned to groups."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Label",
							relativeWidth = 1,
							text = L["To use: Create an operation below, then assign it to a TSM group containing craftable items."],
						},
					},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function Options:DrawNewOperation(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["New Operation"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["RecraftOnSale operations define how items are automatically added to your craft queue when sold."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "EditBox",
							label = L["Operation Name"],
							relativeWidth = 0.8,
							callback = function(self, _, name)
								name = (name or ""):trim()
								if name == "" then return end
								if TSM.operations[name] then
									self:SetText("")
									return TSM:Printf(L["Error: Operation '%s' already exists."], name)
								end
								TSM.operations[name] = CopyTable(TSM.operationDefaults)
								Options:UpdateTree()
								Options.treeGroup:SelectByPath(2, name)
								TSMAPI:NewOperationCallback("RecraftOnSale", Options.currentGroup, name)
							end,
						},
					},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function Options:DrawOperationSettings(container, operationName)
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({
		{ value = 1, text = L["General"] },
		{ value = 2, text = L["Relationships"] },
		{ value = 3, text = L["Management"] },
	})
	tg:SetCallback("OnGroupSelected", function(self, _, value)
		tg:ReleaseChildren()
		TSMAPI:UpdateOperation("RecraftOnSale", operationName)
		if value == 1 then
			Options:DrawOperationGeneral(self, operationName)
		elseif value == 2 then
			Options:DrawOperationRelationships(self, operationName)
		elseif value == 3 then
			TSMAPI:DrawOperationManagement(TSM, self, operationName)
		end
	end)
	container:AddChild(tg)
	tg:SelectTab(1)
end

function Options:DrawOperationGeneral(container, operationName)
	local operation = TSM.operations[operationName]

	-- Match mode dropdown options
	local matchModeList = {
		[TSM.MATCH_MODE.EXACT_ITEM] = L["Exact Item (by Item ID)"],
		[TSM.MATCH_MODE.FULL_NAME] = L["Full Name"],
		[TSM.MATCH_MODE.BASE_NAME] = L["Base Name (without random enchant)"],
	}

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Recraft Settings"],
					children = {
						{
							type = "CheckBox",
							label = L["Enable Recraft on Sale"],
							settingInfo = { operation, "enabled" },
							relativeWidth = 1,
							disabled = operation.relationships.enabled,
							tooltip = L["When enabled, items from groups with this operation will be added to the craft queue when sold."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = L["Match Mode"],
							settingInfo = { operation, "matchMode" },
							relativeWidth = 1,
							disabled = operation.relationships.matchMode,
							list = matchModeList,
							tooltip = L["How to match sold items with items in your groups:\n\n|cff00ff00Exact Item|r - Only match if the exact item ID matches (most restrictive)\n\n|cff00ff00Full Name|r - Match by the complete item name\n\n|cff00ff00Base Name|r - Match ignoring random enchant suffixes like 'of the Tiger' (default, most flexible)"],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Slider",
							label = L["Quantity Multiplier"],
							settingInfo = { operation, "quantityMultiplier" },
							relativeWidth = 0.5,
							disabled = operation.relationships.quantityMultiplier,
							min = 1,
							max = 10,
							step = 1,
							tooltip = L["Multiply the sold quantity by this value. 1 = requeue exact amount sold, 2 = double, etc."],
						},
						{
							type = "Slider",
							label = L["Max Queue Per Sale"],
							settingInfo = { operation, "maxQueuePerSale" },
							relativeWidth = 0.5,
							disabled = operation.relationships.maxQueuePerSale,
							min = 0,
							max = 100,
							step = 1,
							tooltip = L["Maximum items to queue per sale. 0 = unlimited."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Show Notification"],
							settingInfo = { operation, "showNotification" },
							relativeWidth = 1,
							disabled = operation.relationships.showNotification,
							tooltip = L["Display a chat message when items are added to the queue."],
						},
					},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function Options:DrawOperationRelationships(container, operationName)
	local settingInfo = {
		{
			label = L["Recraft Settings"],
			{ key = "enabled", label = L["Enable Recraft on Sale"] },
			{ key = "matchMode", label = L["Match Mode"] },
			{ key = "quantityMultiplier", label = L["Quantity Multiplier"] },
			{ key = "maxQueuePerSale", label = L["Max Queue Per Sale"] },
			{ key = "showNotification", label = L["Show Notification"] },
		},
	}
	TSMAPI:ShowOperationRelationshipTab(TSM, container, TSM.operations[operationName], settingInfo)
end
