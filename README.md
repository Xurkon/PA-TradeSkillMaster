# TradeSkillMaster - Project Ascension

![Version](https://img.shields.io/badge/version-2.0.9-blue)
![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-orange)
![Project Ascension](https://img.shields.io/badge/Project-Ascension-purple)

A comprehensive auction house and crafting addon suite for **Project Ascension** (3.3.5a).

## Included Addons

| Addon | Description |
|-------|-------------|
| **TradeSkillMaster** | Core addon with API and utilities |
| **TradeSkillMaster_Accounting** | Track gold income and expenses |
| **TradeSkillMaster_AuctionDB** | Auction house price database |
| **TradeSkillMaster_Auctioning** | Automated posting and canceling |
| **TradeSkillMaster_Crafting** | Crafting queue and profit calculations |
| **TradeSkillMaster_Destroying** | Milling, prospecting, and disenchanting |
| **TradeSkillMaster_ItemTracker** | Track inventory across characters |
| **TradeSkillMaster_Mailing** | Automated mailing operations |
| **TradeSkillMaster_Shopping** | Auction house shopping lists |
| **TradeSkillMaster_Warehousing** | Bank and guild bank operations |

## Ascension-Specific Features

### ItemTracker v2.0.9

- **Personal Bank Tracking** - Automatically tracks items in your Personal Bank
- **Realm Bank Tracking** - Tracks items in the shared Realm Bank
- Uses Ascension events: `ASCENSION_PERSONAL_BANK_UPDATE`, `ASCENSION_REALM_BANK_UPDATE`
- PBank and RBank columns added to Inventory Viewer

## Installation

1. Download or clone this repository
2. Copy all folders to `Interface/AddOns/`
3. Restart WoW or `/reload`

## Credits

- **Original Authors:** Sapu94, Bart39, and the TSM Team
- **Project Ascension Updates:** [Xurkon](https://github.com/Xurkon)

## License

See individual addon LICENSE files.
