-- TSMCollapsibleContainer - Expandable/collapsible section
-- Based on retail TSM4 LibTSMUI CollapsibleContainer

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

do
	local Type = "TSMCollapsibleContainer"
	local Version = 1
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:SetSize(400, 300)
		
		local widget = {
			frame = frame,
			type = Type,
			children = {},
			contentChild = nil,
			isCollapsed = false,
			headingText = "Section",
		}
		
		-- Header frame
		local header = CreateFrame("Button", nil, frame)
		header:SetHeight(24)
		header:SetPoint("TOPLEFT")
		header:SetPoint("TOPRIGHT")
		widget.header = header
		
		-- Header background
		local headerBg = header:CreateTexture(nil, "BACKGROUND")
		headerBg:SetAllPoints()
		headerBg:SetColorTexture(0.15, 0.15, 0.15, 1)
		
		-- Expand/collapse icon
		local icon = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		icon:SetPoint("LEFT", 4, 0)
		icon:SetText("-")  -- Expanded
		icon:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		widget.icon = icon
		
		-- Heading text
		local heading = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		heading:SetPoint("LEFT", icon, "RIGHT", 4, 0)
		heading:SetText("Section")
		widget.heading = heading
		
		-- Content frame
		local content = CreateFrame("Frame", nil, frame)
		content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
		content:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -4)
		content:SetPoint("BOTTOM")
		
		-- Content background (visible so you can see it expand/collapse)
		local contentBg = content:CreateTexture(nil, "BACKGROUND")
		contentBg:SetAllPoints()
		contentBg:SetColorTexture(0.25, 0.25, 0.25, 1)  -- Slightly lighter than header
		
		widget.contentFrame = content
		widget.contentBg = contentBg
		
		-- Click to toggle
		header:SetScript("OnClick", function()
			widget:ToggleCollapsed()
		end)
		
		-- Hover effect
		header:SetScript("OnEnter", function()
			headerBg:SetColorTexture(0.2, 0.2, 0.2, 1)
		end)
		header:SetScript("OnLeave", function()
			headerBg:SetColorTexture(0.15, 0.15, 0.15, 1)
		end)
		
		-- Methods
		function widget:OnAcquire()
			self.isCollapsed = false
			self.contentHeight = 100  -- Default content height
			self:UpdateDisplay()
		end
		
		function widget:OnRelease()
			if self.contentChild and self.contentChild.Release then
				self.contentChild:Release()
			end
			self.contentChild = nil
			wipe(self.children)
		end
		
		function widget:SetHeadingText(text)
			self.headingText = text
			self.heading:SetText(text)
		end
		
		function widget:SetCollapsed(collapsed)
			self.isCollapsed = collapsed
			self:UpdateDisplay()
		end
		
		function widget:ToggleCollapsed()
			self:SetCollapsed(not self.isCollapsed)
		end
		
		function widget:UpdateDisplay()
			if self.isCollapsed then
				self.icon:SetText("+")
				self.contentFrame:Hide()
				self.frame:SetHeight(28)  -- Just header height
			else
				self.icon:SetText("-")
				self.contentFrame:Show()
				-- Set total height = header + content
				self.frame:SetHeight(28 + self.contentHeight)
			end
		end
		
		function widget:SetContentHeight(height)
			self.contentHeight = height or 100
			if not self.isCollapsed then
				self.frame:SetHeight(28 + self.contentHeight)
			end
		end
		
		function widget:AddChild(child)
			if self.contentChild and self.contentChild.Release then
				self.contentChild:Release()
			end
			self.contentChild = child
			child.frame:SetParent(self.contentFrame)
			child.frame:ClearAllPoints()
			child.frame:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", 0, 0)
			child.frame:SetPoint("BOTTOMRIGHT", self.contentFrame, "BOTTOMRIGHT", 0, 0)
		end
		
		function widget:OnWidthSet(width)
			-- Width propagates naturally
		end
		
		function widget:OnHeightSet(height)
			-- Store the desired content height (excluding header)
			if height > 28 then
				self.contentHeight = height - 28
			end
			if not self.isCollapsed then
				self.frame:SetHeight(height)
			end
		end
		
		function widget:SetLayout(layout)
			-- Pass layout to content child
			if self.contentChild and self.contentChild.SetLayout then
				self.contentChild:SetLayout(layout)
			end
		end
		
		return AceGUI:RegisterAsWidget(widget)
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

