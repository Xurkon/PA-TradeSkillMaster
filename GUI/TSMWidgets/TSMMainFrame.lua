-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- Much of this code is copied from .../AceGUI-3.0/widgets/AceGUIContainer-Frame.lua
-- This Frame container is modified to fit TSM's theme / needs
local TSM = select(2, ...)
local Type, Version = "TSMMainFrame", 2
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ICON_TEXT_COLOR = {165/255, 168/255, 188/255, .7}


--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Frame_OnClose(frame)
	frame.obj:Fire("OnClose")
end

local function CloseButton_OnClick(frame)
	PlaySound("gsTitleOptionExit")
	frame.obj:Hide()
end

local function Frame_OnMouseDown(frame)
	frame.toMove:GetScript("OnMouseDown")(frame.toMove)
	AceGUI:ClearFocus()
end

local function Frame_OnMouseUp(frame)
	frame.toMove:GetScript("OnMouseUp")(frame.toMove)
	AceGUI:ClearFocus()
end

local function Sizer_OnMouseUp(mover)
	local frame = mover:GetParent()
	frame:StopMovingOrSizing()
	frame:SavePositionAndSize()
	local self = frame.obj
	local status = self.status or self.localstatus
	status.width = frame:GetWidth()
	status.height = frame:GetHeight()
	status.top = frame:GetTop()
	status.left = frame:GetLeft()
end

local function Sizer_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOMRIGHT")
	AceGUI:ClearFocus()
end

local function Icon_OnEnter(btn)
	btn.dark:Hide()
	GameTooltip:SetOwner(btn, btn:GetParent().tooltipAnchor)
	GameTooltip:SetText(btn.title)
	GameTooltip:Show()
end

local function Icon_OnLeave(btn)
	if btn.obj.selected ~= btn then
		btn.dark:Show()
	end
	GameTooltip:Hide()
end


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.frame:RefreshPosition()
		self.frame:SetFrameStrata("MEDIUM")
		self:SetTitle()
		self:ApplyStatus()
		self:Show()
		
		-- FIXED: Force layout after frame is shown to prevent jittering
		TSMAPI:CreateTimeDelay("layoutIconsDelay", 0.05, function()
			if self.LayoutIcons then
				self:LayoutIcons()
			end
		end)
	end,

	["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
	end,
	
	-- MODERNIZED: Dynamic-width menu bar - buttons size to text content
	["LayoutIcons"] = function(self)
		-- Prevent layout loops that cause jittering
		if self.isLayingOut then return end
		self.isLayingOut = true
		
		for _, container in ipairs({self.topLeftIcons, self.topRightIcons}) do
			if type(container.icons) == "table" and container.icons[1] then
				local numIcons = #container.icons
				local containerWidth = container:GetWidth()
				
				-- Ensure we have valid width before calculating
				if containerWidth <= 0 then
					self.isLayingOut = false
					return
				end
				
				local menuHeight = 32
				local padding = 16  -- Horizontal padding inside each button
				local spacing = 6   -- Space between buttons
				
				-- Calculate width needed for each button based on text
				local buttonWidths = {}
				local totalWidth = 0
				
				for i, btn in ipairs(container.icons) do
					if btn.textLabel then
						-- Get text width + padding
						local textWidth = btn.textLabel:GetStringWidth()
						local buttonWidth = ceil(textWidth + padding)
						buttonWidths[i] = max(70, buttonWidth)  -- Minimum 70px
						totalWidth = totalWidth + buttonWidths[i]
					end
				end
				
				-- Add spacing between buttons
				totalWidth = totalWidth + (numIcons - 1) * spacing
				
				-- Check if we need multiple rows
				local numRows = 1
				if totalWidth > containerWidth then
					-- Need to wrap - calculate rows
					numRows = 1
					local currentRowWidth = 0
					local itemsInCurrentRow = 0
					
					for i, width in ipairs(buttonWidths) do
						if currentRowWidth + width + (itemsInCurrentRow > 0 and spacing or 0) > containerWidth then
							-- Start new row
							numRows = numRows + 1
							currentRowWidth = width
							itemsInCurrentRow = 1
						else
							currentRowWidth = currentRowWidth + width + (itemsInCurrentRow > 0 and spacing or 0)
							itemsInCurrentRow = itemsInCurrentRow + 1
						end
					end
				end
				
				-- Update container height
				local newHeight = numRows * menuHeight + (numRows - 1) * 4
				if container:GetHeight() ~= newHeight then
					container:SetHeight(newHeight)
				end
				
				-- Position buttons with dynamic widths
				local currentX = 0
				local currentY = 0
				local currentRow = 1
				local rowWidth = 0
				
				for i, btn in ipairs(container.icons) do
					local btnWidth = buttonWidths[i]
					
					-- Check if we need to wrap to next row
					if currentX + btnWidth > containerWidth and currentX > 0 then
						currentRow = currentRow + 1
						currentX = 0
						currentY = currentY - (menuHeight + 4)
					end
					
					btn:ClearAllPoints()
					btn:SetPoint("TOPLEFT", container, "TOPLEFT", currentX, currentY)
					btn:SetWidth(btnWidth)
					btn:SetHeight(menuHeight)
					
					currentX = currentX + btnWidth + spacing
				end
			end
		end
		
		self.isLayingOut = false
	end,

	["OnWidthSet"] = function(self, width)
		-- Prevent layout loops that cause jittering
		if self.isSettingWidth then return end
		self.isSettingWidth = true
		
		self.content.width = self.content:GetWidth()
		
		-- MODERNIZED: Single horizontal menu bar spanning full width
		self.topLeftIcons:ClearAllPoints()
		self.topLeftIcons:SetPoint("TOPLEFT", 10, -45)  -- Below TSM logo
		self.topLeftIcons:SetPoint("TOPRIGHT", -10, -45)
		self.topLeftIcons:SetHeight(32)
		self.topLeftIcons:Show()
		
		-- Hide the right container (we're using one unified menu bar)
		self.topRightIcons:ClearAllPoints()
		self.topRightIcons:SetHeight(0)
		self.topRightIcons:Hide()
		
		-- Hide section labels (not needed for unified menu)
		if self.topLeftIcons.sectionLabel then
			self.topLeftIcons.sectionLabel:Hide()
		end
		if self.topRightIcons.sectionLabel then
			self.topRightIcons.sectionLabel:Hide()
		end
		
		self:LayoutIcons()
		
		-- Content starts right below menu bar (fixed position to prevent jitter)
		local menuHeight = self.topLeftIcons:GetHeight()
		self.content:ClearAllPoints()
		self.content:SetPoint("TOPLEFT", 11, -(45 + menuHeight + 5))
		self.content:SetPoint("BOTTOMRIGHT", -11, 20)
		
		self.isSettingWidth = false
	end,

	["OnHeightSet"] = function(self, height)
		self.content.height = self.content:GetHeight()
	end,

	["SetTitle"] = function(self, title)
		self.titletext:SetText(title)
	end,
	
	["SetIconText"] = function(self, title)
		self.icontext:SetText(title)
	end,
	
	["SetIconLabels"] = function(self, topLeft, topRight)
		self.topLeftIcons.label = topLeft
		self.topRightIcons.label = topRight
	end,

	["Hide"] = function(self)
		self.frame:Hide()
	end,

	["Show"] = function(self)
		self.frame:Show()
	end,
	
	-- MODERNIZED: Update selected state for text-only menu
	["UpdateSelected"] = function(self)
		for _, container in ipairs({self.topLeftIcons, self.topRightIcons}) do
			if type(container.icons) == "table" then
				for _, btn in ipairs(container.icons) do
					-- Reset unselected buttons
					if btn.selectedBar then
						btn.selectedBar:Hide()
					end
					if btn.textLabel then
						TSMAPI.Design:SetWidgetTextColor(btn.textLabel)
					end
				end
			end
		end
		-- Highlight selected button
		if self.selected.selectedBar then
			self.selected.selectedBar:Show()
		end
		if self.selected.textLabel then
			TSMAPI.Design:SetTitleTextColor(self.selected.textLabel)  -- Gold text
		end
	end,
	
	-- MODERNIZED: Create dynamic-width text menu buttons (no truncation!)
	["AddIcon"] = function(self, info)
		local container = self[info.where.."Icons"]
		assert(container, "Invalid icon container.")
		
		-- Create text-only menu button (no icon!)
		local btn = CreateFrame("Button", nil, container)
		btn:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1
		})
		TSMAPI.Design:SetContentColor(btn)
		btn.title = info.name
		btn.info = info
		btn.obj = self
		info.frame = btn
		
		-- Create text label (centered in button, full text - no truncation!)
		local textLabel = btn:CreateFontString(nil, "OVERLAY")
		textLabel:SetFont(TSMAPI.Design:GetContentFont("normal"))
		textLabel:SetJustifyH("CENTER")
		textLabel:SetJustifyV("MIDDLE")
		textLabel:SetPoint("CENTER")
		textLabel:SetWordWrap(false)
		TSMAPI.Design:SetWidgetTextColor(textLabel)
		textLabel:SetText(info.name)  -- Full name, no truncation
		btn.textLabel = textLabel
		btn:SetFontString(textLabel)
		
		-- Create highlight overlay for hover
		local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetTexture(1, 1, 1, .15)
		highlight:SetBlendMode("ADD")
		btn.highlight = highlight
		
		-- Create selection underline (gold bar at bottom when selected)
		local selectedBar = btn:CreateTexture(nil, "OVERLAY")
		selectedBar:SetHeight(3)
		selectedBar:SetPoint("BOTTOMLEFT", 2, 0)
		selectedBar:SetPoint("BOTTOMRIGHT", -2, 0)
		selectedBar:SetTexture(255/255, 209/255, 0/255, 1)  -- Gold color
		selectedBar:Hide()
		btn.selectedBar = selectedBar
		
		-- Dark overlay to hide (we'll use this for unselected state)
		local dark = btn:CreateTexture(nil, "BACKGROUND")
		dark:SetAllPoints()
		dark:SetTexture(0, 0, 0, 0)  -- Invisible by default
		btn.dark = dark
		
		-- Hover effect - highlight text and show full name in tooltip
		btn:SetScript("OnEnter", function(b)
			if b.textLabel then
				TSMAPI.Design:SetTitleTextColor(b.textLabel)  -- Gold on hover
			end
			-- Always show tooltip with full name (useful for truncated names)
			if b.title then
				GameTooltip:SetOwner(b, "ANCHOR_TOP")
				GameTooltip:SetText(b.title)  -- Show full name
				GameTooltip:Show()
			end
		end)
		
		btn:SetScript("OnLeave", function(b)
			GameTooltip:Hide()
			if b ~= self.selected and b.textLabel then
				TSMAPI.Design:SetWidgetTextColor(b.textLabel)  -- Back to normal
			end
		end)
		
		btn:SetScript("OnClick", function(btn)
			if #self.children > 0 then
				self:ReleaseChildren()
			end
			self:SetTitle("")  -- Clear the title (we don't show it anymore)
			btn.info.loadGUI(self)
			self.selected = btn
			self:UpdateSelected()
		end)
		
		container.icons = container.icons or {}
		tinsert(container.icons, btn)
		
		-- FIXED: Don't call LayoutIcons here - it causes jittering
		-- Let OnWidthSet handle it once when the frame is ready
	end,

	-- called to set an external table to store status in
	["SetStatusTable"] = function(self, status)
		assert(type(status) == "table")
		self.status = status
		self:ApplyStatus()
	end,

	["ApplyStatus"] = function(self)
		local status = self.status or self.localstatus
		local frame = self.frame
		self:SetWidth(status.width or self.frame:GetWidth())
		self:SetHeight(status.height or self.frame:GetHeight())
		frame:ClearAllPoints()
		if status.top and status.left then
			frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
			frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
		else
			frame:SetPoint("CENTER")
		end
	end,
}


--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frameName = Type..AceGUI:GetNextWidgetNum(Type)

	local frameDefaults = {
		x = UIParent:GetWidth()/2,
		y = UIParent:GetHeight()/2,
		width = 823,
		height = 686,
		scale = 1,
	}
	local frame = TSMAPI:CreateMovableFrame(frameName, frameDefaults)
	frame:SetFrameStrata("MEDIUM")
	TSMAPI.Design:SetFrameBackdropColor(frame)
	frame:SetResizable(true)
	frame:SetMinResize(600, 400)
	frame:SetScript("OnHide", Frame_OnClose)
	frame.toMove = frame
	tinsert(UISpecialFrames, frameName)
	
	-- MODERNIZED: Add small TSM logo/text in top-left corner (retail-style)
	local logoText = frame:CreateFontString(nil, "OVERLAY")
	logoText:SetPoint("TOPLEFT", 15, -15)
	logoText:SetFont(TSMAPI.Design:GetBoldFont(), 18)
	TSMAPI.Design:SetTitleTextColor(logoText)  -- Gold color
	logoText:SetText("TSM")
	
	-- MODERNIZED: Version number in top-right corner (subtle)
	local versionText = frame:CreateFontString(nil, "OVERLAY")
	versionText:SetPoint("TOPRIGHT", -15, -15)
	versionText:SetFont(TSMAPI.Design:GetContentFont("small"))
	versionText:SetTextColor(0.5, 0.5, 0.5, 0.8)  -- Subtle gray
	versionText:SetText(TSM._version or "")
	
	local closebutton = CreateFrame("Button", nil, frame)
	TSMAPI.Design:SetContentColor(closebutton)
	local highlight = closebutton:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetTexture(1, 1, 1, .2)
	highlight:SetBlendMode("BLEND")
	closebutton.highlight = highlight
	closebutton:SetPoint("BOTTOMRIGHT", -29, -14)
	closebutton:SetHeight(29)
	closebutton:SetWidth(86)
	closebutton:SetScript("OnClick", CloseButton_OnClick)
	closebutton:Show()
	local label = closebutton:CreateFontString()
	label:SetPoint("TOP")
	label:SetJustifyH("CENTER")
	label:SetJustifyV("CENTER")
	label:SetHeight(28)
	label:SetFont(TSMAPI.Design:GetContentFont(), 28)
	TSMAPI.Design:SetWidgetTextColor(label)
	label:SetText(CLOSE)
	closebutton:SetFontString(label)
	
	-- MODERNIZED: Hide the big TSM logo (too bulky, not needed with menu bar)
	local iconBtn = CreateFrame("Button", nil, frame)
	iconBtn:SetWidth(286)
	iconBtn:SetHeight(286)
	iconBtn:SetPoint("TOP", 0, 174)
	iconBtn:SetScript("OnMouseDown", Frame_OnMouseDown)
	iconBtn:SetScript("OnMouseUp", Frame_OnMouseUp)
	iconBtn.toMove = frame
	iconBtn:Hide()  -- MODERNIZED: Hidden - we have menu bar now
	local icon = iconBtn:CreateTexture()
	icon:SetAllPoints()
	icon:SetTexture("Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon_Pocket")
	icon:SetAlpha(0)  -- MODERNIZED: Make invisible
	frame.icon = icon

	local sizer = CreateFrame("Frame", nil, frame)
	sizer:SetPoint("BOTTOMRIGHT", -2, 2)
	sizer:SetWidth(20)
	sizer:SetHeight(20)
	sizer:EnableMouse()
	sizer:SetScript("OnMouseDown",Sizer_OnMouseDown)
	sizer:SetScript("OnMouseUp", Sizer_OnMouseUp)
	local image = sizer:CreateTexture(nil, "BACKGROUND")
	image:SetAllPoints()
	image:SetTexture("Interface\\Addons\\TradeSkillMaster\\Media\\Sizer")
	
	-- MODERNIZED: Content area positioning will be adjusted dynamically
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 11, -62)  -- Will be adjusted by OnWidthSet
	content:SetPoint("BOTTOMRIGHT", -11, 20)
	
	-- MODERNIZED: Hide title text (we have menu bar now, don't need central text)
	local titletext = frame:CreateFontString()
	titletext:SetPoint("TOP", 0, -32)
	titletext:SetHeight(22)
	titletext:SetJustifyH("CENTER")
	titletext:SetJustifyV("CENTER")
	titletext:SetFont(TSMAPI.Design:GetContentFont(), 22)
	TSMAPI.Design:SetTitleTextColor(titletext)
	titletext:SetAlpha(0)  -- MODERNIZED: Hide title text
	
	-- MODERNIZED: Hide version text (Rev668) - not needed
	local icontext = iconBtn:CreateFontString(nil, "OVERLAY")
	icontext:SetPoint("TOP", frame, "TOP", 0, 14)
	icontext:SetHeight(29)
	icontext:SetJustifyH("CENTER")
	icontext:SetJustifyV("CENTER")
	icontext:SetFont(TSMAPI.Design:GetContentFont(), 27)
	icontext:SetTextColor(unpack(ICON_TEXT_COLOR))
	icontext:SetAlpha(0)  -- MODERNIZED: Hide version text
	
	-- local helpButton = CreateFrame("Button", nil, frame, "MainHelpPlateButton")
	local helpButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	helpButton:SetPoint("BOTTOMLEFT", -10, -30)
	helpButton:SetScript("OnEnter", function(self)
		HelpPlateTooltip.ArrowRIGHT:Show()
		HelpPlateTooltip.ArrowGlowRIGHT:Show()
		HelpPlateTooltip:SetPoint("LEFT", self, "RIGHT", 10, 0)
		HelpPlateTooltip.Text:SetText(L["Click this to open TSM Assistant."])
		HelpPlateTooltip:Show()
	end)
	helpButton:SetScript("OnLeave", function(self)
		HelpPlateTooltip.ArrowRIGHT:Hide()
		HelpPlateTooltip.ArrowGlowRIGHT:Hide()
		HelpPlateTooltip:ClearAllPoints()
		HelpPlateTooltip:Hide()
	end)
	helpButton:SetScript("OnClick", TSM.Assistant.Open)

	local widget = {
		type = Type,
		localstatus = {},
		frame = frame,
		-- container for children
		content = content,
		-- changable labels
		titletext = titletext,
		icontext = icontext,
		-- containers for the icons - size/pos set by OnWidthSet
		topLeftIcons = CreateFrame("Frame", nil, frame),
		topRightIcons = CreateFrame("Frame", nil, frame),
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	closebutton.obj = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)