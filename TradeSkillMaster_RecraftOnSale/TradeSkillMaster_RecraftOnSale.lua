-- ------------------------------------------------------------------------------ --
--                        TradeSkillMaster_RecraftOnSale                         --
--                                                                               --
--             A TradeSkillMaster Addon for Ascension WoW                        --
--    Automatically requeues crafted items when sold via Auction House           --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_RecraftOnSale", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_RecraftOnSale")

local savedDBDefaults = {
	global = {
		optionsTreeStatus = {},
	},
}

-- Match mode constants
TSM.MATCH_MODE = {
	EXACT_ITEM = 1,      -- Match by exact item ID
	FULL_NAME = 2,       -- Match by full item name
	BASE_NAME = 3,       -- Match by base name (without random enchant suffix)
}

-- Defaults for RecraftOnSale operations
TSM.operationDefaults = {
	-- Operation-specific settings
	enabled = true,
	matchMode = 3,       -- Default: BASE_NAME (without random enchant)
	quantityMultiplier = 1,
	maxQueuePerSale = 0,
	showNotification = true,

	-- Required TSM fields
	ignorePlayer = {},
	ignorerealm = {},
	relationships = {},
}

function TSM:OnInitialize()
	TSM.db = LibStub("AceDB-3.0"):New("AscensionTSM_RecraftOnSaleDB", savedDBDefaults, true)

	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end

	-- Clean up legacy GearMaster boolean fields from TSM groups
	TSM:CleanupLegacyData()

	TSM:RegisterModule()
	TSM:RegisterSaleEvent()
end

-- Remove old GearMaster boolean fields (whisperOnSale, recraftOnSale) from TSM groups
function TSM:CleanupLegacyData()
	local mainTSM = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster", true)
	if not mainTSM or not mainTSM.db or not mainTSM.db.profile or not mainTSM.db.profile.groups then
		return
	end

	local cleaned = false
	for groupPath, groupData in pairs(mainTSM.db.profile.groups) do
		if groupData.whisperOnSale ~= nil then
			groupData.whisperOnSale = nil
			cleaned = true
		end
		if groupData.recraftOnSale ~= nil then
			groupData.recraftOnSale = nil
			cleaned = true
		end
	end

	if cleaned then
		self:Print("Cleaned up legacy GearMaster data from TSM groups.")
	end
end

function TSM:RegisterModule()
	TSM.operations = {
		maxOperations = 1,
		callbackOptions = "Options:Load",
		callbackInfo = "GetOperationInfo",
	}

	TSM.icons = {
		{
			side = "module",
			desc = "RecraftOnSale",
			slashCommand = "recraft",
			callback = function() TSM:Print(L["RecraftOnSale module loaded."]) end,
			icon = "Interface\\Icons\\INV_Misc_Gear_01",
		},
	}

	TSMAPI:NewModule(TSM)
end

function TSM:GetOperationInfo(operationName)
	TSMAPI:UpdateOperation("RecraftOnSale", operationName)
	local operation = TSM.operations[operationName]
	if not operation then return end

	if not operation.enabled then
		return L["Disabled"]
	end

	local parts = {}
	tinsert(parts, L["Auto-requeue on sale"])

	if operation.quantityMultiplier > 1 then
		tinsert(parts, format(L["(%dx quantity)"], operation.quantityMultiplier))
	end

	if operation.maxQueuePerSale > 0 then
		tinsert(parts, format(L["(max %d per sale)"], operation.maxQueuePerSale))
	end

	return table.concat(parts, " ")
end

-- Listen for sale events via hook on AutoLootMailItem
function TSM:RegisterSaleEvent()
	hooksecurefunc("AutoLootMailItem", function(index)
		-- Check if this is a sale invoice
		local invoiceType, itemName, playerName, bid, _, _, ahcut, _, _, _, quantity = GetInboxInvoiceInfo(index)

		if invoiceType == "seller" and itemName then
			TSM:OnSaleCollected({
				itemName = itemName,
				buyer = playerName,
				quantity = quantity or 1,
				bid = bid,
				ahcut = ahcut,
				profit = (bid or 0) - (ahcut or 0),
			})
		end
	end)
end

function TSM:OnSaleCollected(saleData)
	local itemName = saleData.itemName
	local quantity = saleData.quantity or 1

	-- We need to find matching items for each possible operation's matchMode
	-- First, collect all items that could potentially match
	local matches = self:FindAllMatchingItems(itemName)
	if not matches or #matches == 0 then return end

	-- Process each match and check if it has a valid operation
	for _, match in ipairs(matches) do
		local itemString = match.itemString
		local groupPath = match.groupPath

		-- Get the RecraftOnSale operation for this group
		local operations = TSMAPI:GetItemOperation(itemString, "RecraftOnSale")
		if operations and operations[1] then
			local operationName = operations[1]
			TSMAPI:UpdateOperation("RecraftOnSale", operationName)
			local operation = TSM.operations[operationName]

			if operation and operation.enabled then
				-- Check if this match is valid for the operation's matchMode
				if self:IsValidMatch(itemName, match, operation.matchMode) then
					-- Calculate quantity to requeue
					local queueQuantity = quantity * operation.quantityMultiplier
					if operation.maxQueuePerSale > 0 then
						queueQuantity = min(queueQuantity, operation.maxQueuePerSale)
					end

					-- Add to craft queue
					local success = self:AddToCraftQueue(itemString, queueQuantity, itemName)

					if operation.showNotification then
						if success then
							self:Print(format(L["Added %dx %s to craft queue"], queueQuantity, itemName))
						else
							self:Print(format(L["Could not add %s to craft queue - recipe not found"], itemName))
						end
					end

					-- Only process the first valid match
					return
				end
			end
		end
	end
end

-- Extract base item name (remove " of X" suffix for random enchants)
function TSM:GetBaseName(itemName)
	return strmatch(itemName, "^(.-)%s+of%s+") or itemName
end

-- Find all items in TSM groups that could potentially match the sold item
function TSM:FindAllMatchingItems(soldItemName)
	local matches = {}
	local baseSoldName = self:GetBaseName(soldItemName)

	local mainTSM = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster", true)
	if not mainTSM or not mainTSM.db or not mainTSM.db.profile then
		return matches
	end

	for itemString, groupPath in pairs(mainTSM.db.profile.items) do
		local baseItemString = TSMAPI:GetBaseItemString(itemString)
		local itemFullName = TSMAPI:GetSafeItemInfo(baseItemString)

		if itemFullName then
			local baseGroupItemName = self:GetBaseName(itemFullName)

			-- Check if this could be a match (by base name at minimum)
			if baseSoldName == baseGroupItemName then
				tinsert(matches, {
					itemString = baseItemString,
					groupPath = groupPath,
					fullName = itemFullName,
					baseName = baseGroupItemName,
				})
			end
		end
	end

	return matches
end

-- Check if a match is valid for the given matchMode
function TSM:IsValidMatch(soldItemName, match, matchMode)
	if matchMode == TSM.MATCH_MODE.EXACT_ITEM then
		-- Exact match: full item name must match exactly
		return soldItemName == match.fullName

	elseif matchMode == TSM.MATCH_MODE.FULL_NAME then
		-- Full name match: compare full names (case-sensitive)
		return soldItemName == match.fullName

	elseif matchMode == TSM.MATCH_MODE.BASE_NAME then
		-- Base name match: compare without random enchant suffix
		local baseSoldName = self:GetBaseName(soldItemName)
		return baseSoldName == match.baseName

	end

	return false
end

-- Add an item to the TSM_Crafting queue
function TSM:AddToCraftQueue(itemString, quantity, itemName)
	local TSM_Crafting = LibStub("AceAddon-3.0"):GetAddon("TSM_Crafting", true)
	if not TSM_Crafting then return false end

	-- Update the reverse lookup table
	if TSM_Crafting.UpdateCraftReverseLookup then
		TSM_Crafting:UpdateCraftReverseLookup()
	end

	if not TSM_Crafting.craftReverseLookup or not TSM_Crafting.craftReverseLookup[itemString] then
		return false
	end

	local spellIDs = TSM_Crafting.craftReverseLookup[itemString]
	if not spellIDs or #spellIDs == 0 then return false end

	-- Use first spell ID found
	local spellID = spellIDs[1]

	-- Get craft data
	local craft = TSM_Crafting.db.realm.crafts[spellID]
	if not craft then return false end

	-- Calculate how many casts needed (account for multi-result crafts)
	local numResult = craft.numResult or 1
	local craftCount = math.ceil(quantity / numResult)

	-- Add to queue via official API
	TSMAPI:ModuleAPI("Crafting", "addQueue", spellID, craftCount)

	return true
end
