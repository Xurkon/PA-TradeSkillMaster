# TradeSkillMaster: Revived — Project Ascension

[![Documentation](https://img.shields.io/badge/📖_Docs-GitHub_Pages-2ea44f?style=for-the-badge)](https://xurkon.github.io/PA-TradeSkillMaster/)

![Version](https://img.shields.io/badge/version-v2.9.2--PA-blue)
![Base](https://img.shields.io/badge/base-v2.8.3-green)
![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-orange)
![Project Ascension](https://img.shields.io/badge/Project-Ascension-purple)

A comprehensive auction house, crafting, and gold-making addon suite for **Project Ascension** (3.3.5a). Based on TSM v2.8.3 with extensive modernization and Ascension-specific enhancements.

---

## ✨ Features

### Core Improvements (Rev701)

- **Fixed Market Value Algorithm** — Prices are now calculated correctly (previously broken in all prior versions)
- **Rewritten Auction Scanning** — 1.3x–27.3x faster, uses <5% memory of old algorithm
- **Shopping Reliability** — Tolerates AH desync, prevents "must meet minimum bid" errors
- **Performance Optimizations** — Cached gather strings, reused tables, reduced garbage collection
- **SharedMedia Support** — Customizable fonts via LibSharedMedia
- **Accurate Time Estimates** — Full Scan shows `elapsed / ~estimated total` time

### Ascension-Specific Features

- **Personal Bank Tracking** — Tracks items in your Personal Bank
- **Realm Bank Tracking** — Tracks items in the shared Realm Bank  
- **Custom Events** — `ASCENSION_PERSONAL_BANK_UPDATE`, `ASCENSION_REALM_BANK_UPDATE`
- **Inventory Viewer** — PBank and RBank columns added

---

## 📦 Included Modules

| Module | Description |
|--------|-------------|
| **TradeSkillMaster** | Core addon with API, utilities, and settings |
| **TSM_Accounting** | Track gold income, expenses, and sales history |
| **TSM_AuctionDB** | Auction house price database and market values |
| **TSM_Auctioning** | Automated posting, canceling, and undercutting |
| **TSM_Crafting** | Crafting queue, cost calculations, and profit analysis |
| **TSM_Destroying** | Milling, prospecting, and disenchanting automation |
| **TSM_ItemTracker** | Track inventory across all characters and banks |
| **TSM_Mailing** | Automated mailing operations |
| **TSM_Shopping** | Shopping lists, sniper, and deal finding |
| **TSM_Warehousing** | Bank and guild bank inventory management |
| **TSM_CsvExtractor** | Export TSM groups to CSV for spreadsheets |
| **TSM_RecraftOnSale** | Auto-requeue crafts when items sell on AH |
| **TSM_CRM** | Customer relationship management - auto-whisper buyers |

---

## 📥 Installation

1. Download or clone this repository
2. Copy **all folders** to `Interface/AddOns/`
3. Restart WoW or type `/reload`

---

## 🔧 Commands

| Command | Description |
|---------|-------------|
| `/tsm` | Open the main TSM window |
| `/tsm bankui` | Open the Bank UI |
| `/tsm freset` | Reset all frame positions |
| `/tsm version` | Display version information |

---

## 📜 Changelog

See [ChangeLog.txt](ChangeLog.txt) for full version history.

**Recent Highlights:**

- **v2.9.2-PA** — Added CsvExtractor, RecraftOnSale, and CRM modules (ksoltanidev)
- **v2.9.1-PA** — Crafting Gathering integration for Personal/Realm banks (ksoltanidev)
- **v2.9.0-PA** — Ascension Personal/Realm Bank tracking, MIT license
- **Rev701** — Major shopping, scanning, and market value algorithm overhaul
- **v2.8.3.666** — Fixed market value algorithm, rewritten scanning

---

## 👥 Credits

| Role | Contributors |
|------|--------------|
| **Original Authors** | Sapu94, Bart39 |
| **TSM Revived** | Gnomezilla, BlueAo, andrew6180, Yoshiyuka, DimaSheiko |
| **Modern TSM (Rev701)** | XiusTV |
| **CsvExtractor & RecraftOnSale** | [ksoltanidev](https://github.com/ksoltanidev) |
| **Crafting Bank Integration** | [ksoltanidev](https://github.com/ksoltanidev) |
| **Project Ascension Port** | [Xurkon](https://github.com/Xurkon) |

---

## 📄 License

See [LICENSE](LICENSE) for details.

[Documentation](docs/index.html)
