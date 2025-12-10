local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_RecraftOnSale", "enUS", true)
if not L then return end

-- General
L["RecraftOnSale"] = true
L["RecraftOnSale module loaded."] = true
L["Disabled"] = true
L["Auto-requeue on sale"] = true
L["(%dx quantity)"] = true
L["(max %d per sale)"] = true
L["Added %dx %s to craft queue"] = true
L["Could not add %s to craft queue - recipe not found"] = true

-- Options Tree
L["Options"] = true
L["Operations"] = true
L["General"] = true
L["Relationships"] = true
L["Management"] = true
L["New Operation"] = true
L["Operation Name"] = true
L["Error: Operation '%s' already exists."] = true

-- General Settings
L["This module automatically adds sold items to your craft queue based on operations assigned to groups."] = true
L["To use: Create an operation below, then assign it to a TSM group containing craftable items."] = true
L["RecraftOnSale operations define how items are automatically added to your craft queue when sold."] = true

-- Operation Settings
L["Recraft Settings"] = true
L["Enable Recraft on Sale"] = true
L["When enabled, items from groups with this operation will be added to the craft queue when sold."] = true
L["Match Mode"] = true
L["Exact Item (by Item ID)"] = true
L["Full Name"] = true
L["Base Name (without random enchant)"] = true
L["How to match sold items with items in your groups:\n\n|cff00ff00Exact Item|r - Only match if the exact item ID matches (most restrictive)\n\n|cff00ff00Full Name|r - Match by the complete item name\n\n|cff00ff00Base Name|r - Match ignoring random enchant suffixes like 'of the Tiger' (default, most flexible)"] = true
L["Quantity Multiplier"] = true
L["Multiply the sold quantity by this value. 1 = requeue exact amount sold, 2 = double, etc."] = true
L["Max Queue Per Sale"] = true
L["Maximum items to queue per sale. 0 = unlimited."] = true
L["Show Notification"] = true
L["Display a chat message when items are added to the queue."] = true
