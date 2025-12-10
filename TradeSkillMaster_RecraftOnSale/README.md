# TradeSkillMaster_RecraftOnSale

A TradeSkillMaster addon for **Ascension WoW** that automatically adds sold items to your craft queue.

## Features

- **Automatic Requeue**: When you collect gold from an AH sale, the sold item is automatically added to your TSM craft queue
- **Operation-Based**: Uses the standard TSM operation system - create operations and assign them to groups
- **Match Modes**: Choose how items are matched:
  - **Exact Item**: Match by exact item ID (most restrictive)
  - **Full Name**: Match by complete item name
  - **Base Name**: Ignore random enchant suffixes like "of the Tiger" (default, most flexible)
- **Configurable Options**:
  - Quantity multiplier (1x = exact amount sold, 2x = double, etc.)
  - Max queue per sale (limit how many are queued per sale)
  - Chat notifications

## Requirements

- **Ascension WoW** (WotLK 3.3.5 client)
- **TradeSkillMaster** (Ascension version)
- **TradeSkillMaster_Crafting**
- **TradeSkillMaster_Mailing**

## Installation

1. Download and extract to your `Interface/AddOns` folder
2. The folder should be named `TradeSkillMaster_RecraftOnSale`

## How It Works

The addon uses two methods to detect AH sales:

### Method 1: Hook (Default, works out of the box)

The addon hooks `AutoLootMailItem` to detect when you collect sale mail. This works without any modifications to TSM.

**Limitation**: The hook fires BEFORE the mail is looted. If your bags are full and the loot fails, the item may still be queued.

### Method 2: TSM Event (Recommended, requires patch)

If you apply a small patch to `TradeSkillMaster_Mailing`, the addon will use a more reliable event-based system that only fires AFTER the sale is successfully collected.

See `TSM_MAILING_PATCH.md` for the patch details and instructions.

## Usage

1. Open TSM (`/tsm`)
2. Go to the **RecraftOnSale** module in the sidebar
3. Create a new **Operation** with your desired settings
4. Assign the operation to TSM groups containing craftable items
5. When you collect AH sale mail, items will automatically be added to your craft queue

## Operation Settings

| Setting | Description |
|---------|-------------|
| **Enable Recraft on Sale** | Toggle the operation on/off |
| **Match Mode** | How to match sold items (Exact/Full Name/Base Name) |
| **Quantity Multiplier** | Multiply sold quantity (1-10x) |
| **Max Queue Per Sale** | Limit items queued per sale (0 = unlimited) |
| **Show Notification** | Display chat message when items are queued |

## Match Mode Examples

If you sell "Breastplate of the Tiger":

| Mode | Matches in Group |
|------|------------------|
| **Exact Item** | Only "Breastplate of the Tiger" |
| **Full Name** | Only "Breastplate of the Tiger" |
| **Base Name** | "Breastplate", "Breastplate of the Bear", "Breastplate of the Tiger", etc. |

Use **Base Name** (default) for crafted items with random enchants.

## License

MIT License - See LICENSE.txt
