-- Locale for enUS
local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_CsvExtractor", "enUS", true)
if not L then return end

-- General
L["CSV Extractor"] = "CSV Extractor"
L["Help"] = "Help"
L["Options"] = "Options"
L["Export"] = "Export"

-- Help texts
L["CsvExtractor allows you to export items from a TSM group to CSV format."] = "CsvExtractor allows you to export items from a TSM group to CSV format."
L["Select a group, choose the fields you want to export, and click Export."] = "Select a group, choose the fields you want to export, and click Export."
L["The CSV output will be displayed in a text box that you can copy."] = "The CSV output will be displayed in a text box that you can copy."

-- Options
L["Select Group"] = "Select Group"
L["Select the TSM group to export."] = "Select the TSM group to export."
L["Include Headers"] = "Include Headers"
L["Include column headers in the CSV output."] = "Include column headers in the CSV output."
L["Fields to Export"] = "Fields to Export"

-- Field names
L["Item ID"] = "Item ID"
L["Item Name"] = "Item Name"
L["Item Link"] = "Item Link"
L["Market Value"] = "Market Value"
L["Min Buyout"] = "Min Buyout"
L["Crafting Cost"] = "Crafting Cost"
L["Vendor Sell Price"] = "Vendor Sell Price"
L["Item Level"] = "Item Level"
L["Quality"] = "Quality"
L["Stack Size"] = "Stack Size"
L["Total Stock"] = "Total Stock"

-- Export dialog
L["CSV Output"] = "CSV Output"
L["Copy the text below (Ctrl+A to select all, Ctrl+C to copy)"] = "Copy the text below (Ctrl+A to select all, Ctrl+C to copy)"
L["Close"] = "Close"

-- Messages
L["Please select a group first."] = "Please select a group first."
L["Please select at least one field to export."] = "Please select at least one field to export."
L["No items found in the selected group."] = "No items found in the selected group."
L["Exported %d items to CSV."] = "Exported %d items to CSV."
