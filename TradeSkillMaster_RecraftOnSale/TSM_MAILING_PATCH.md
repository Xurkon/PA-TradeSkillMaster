# TSM_Mailing Patch Proposal

## Problem

Currently, `TradeSkillMaster_Mailing` does not fire any event when a sale is collected from the mailbox. This makes it difficult for external addons to react to AH sales without modifying TSM core code.

The `RecraftOnSale` addon uses a `hooksecurefunc` on `AutoLootMailItem` as a workaround, but this approach has limitations:

### Hook Limitations

1. **Timing Issue**: The hook fires BEFORE the mail is actually looted. If the player's bags are full, the loot will fail but the hook has already triggered.

2. **No Confirmation**: There's no way to know if the mail was successfully looted after the hook fires.

3. **Duplicate Risk**: If multiple addons hook the same function, there's potential for race conditions.

## Proposed Solution

Add a custom TSM event `TSM:MAILING:SALE_COLLECTED` that fires AFTER a sale mail is successfully collected.

### Implementation

In `TradeSkillMaster_Mailing/Modules/Inbox.lua`, find the `LootMailItem` function (around line 491).

After the "Collected sale" print statement (around line 514), add:

```lua
elseif invoiceType == "seller" then
    TSM:Printf(L["Collected sale of %s (%d) for %s."], itemName, quantity or 1, TSMAPI:FormatTextMoney(bid - ahcut, greenColor))

    -- ADD THIS BLOCK: Fire event for external addons
    TSMAPI:FireEvent("TSM:MAILING:SALE_COLLECTED", {
        itemName = itemName,
        buyer = playerName,
        quantity = quantity or 1,
        bid = bid,
        ahcut = ahcut,
        profit = bid - ahcut,
        timestamp = time()
    })
```

### Full Context (lines ~510-530)

```lua
local redColor = "|cffFF0000"
local greenColor = "|cff00FF00"
local yellowColor = "|cffFFFF00"

if invoiceType == "buyer" then
    local itemLink = GetInboxItemLink(index, 1) or itemName
    TSM:Printf(L["Collected purchase of %s (%d) for %s."], itemLink, quantity or 1, TSMAPI:FormatTextMoney(bid, redColor))
elseif invoiceType == "seller" then
    TSM:Printf(L["Collected sale of %s (%d) for %s."], itemName, quantity or 1, TSMAPI:FormatTextMoney(bid - ahcut, greenColor))

    -- Fire event for external addons (RecraftOnSale, custom trackers, etc.)
    TSMAPI:FireEvent("TSM:MAILING:SALE_COLLECTED", {
        itemName = itemName,
        buyer = playerName,
        quantity = quantity or 1,
        bid = bid,
        ahcut = ahcut,
        profit = bid - ahcut,
        timestamp = time()
    })
elseif invoiceType == "seller_temp_invoice" then
    TSM:Printf("Removing pending sale of %s (%d) for %s.", itemName, quantity or 1, TSMAPI:FormatTextMoney(bid - ahcut, yellowColor))
    DeleteInboxItem(index)
    return
end
```

## Benefits

1. **Reliable Timing**: Event fires after successful collection, not before
2. **Rich Data**: Includes item name, buyer, quantity, bid, AH cut, and profit
3. **Extensible**: Other addons can listen for this event without hooks
4. **Non-Breaking**: Existing functionality is unchanged

## Use Cases

- **RecraftOnSale**: Automatically requeue crafted items when sold
- **Sale Notifications**: Send thank-you whispers to buyers
- **Profit Tracking**: Custom profit logging/analytics
- **Discord/External Webhooks**: Notify external services of sales

## Event Data Structure

```lua
{
    itemName = "Runed Scarlet Ruby",  -- Full item name as shown in mail
    buyer = "PlayerName",              -- Name of the buyer
    quantity = 1,                      -- Number of items sold
    bid = 500000,                      -- Sale price in copper
    ahcut = 25000,                     -- AH fee in copper
    profit = 475000,                   -- Net profit (bid - ahcut)
    timestamp = 1702156800            -- Unix timestamp
}
```

## Listening for the Event

```lua
local eventObj = TSMAPI:GetEventObject()
eventObj:SetCallback("TSM:MAILING:SALE_COLLECTED", function(event, saleData)
    print("Sold " .. saleData.itemName .. " to " .. saleData.buyer)
end)
```
