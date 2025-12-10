-- TSMCustomStringInput - Custom price string editor with popout
-- Simplified version of retail TSM4 CustomStringSingleLineInput

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

do
	local Type = "TSMCustomStringInput"
	local Version = 1
	
	local function Constructor()
		-- Base on TSMEditBox
		local editbox = AceGUI:Create("TSMEditBox")
		if not editbox then
			-- Fallback to regular EditBox if TSMEditBox not available
			editbox = AceGUI:Create("EditBox")
		end
		
		local widget = {
			editbox = editbox,
			frame = editbox.frame,
			type = Type,
		}
		
		-- Add popout button
		local popoutBtn = CreateFrame("Button", nil, editbox.frame)
		popoutBtn:SetSize(20, 20)
		popoutBtn:SetPoint("RIGHT", editbox.frame, "RIGHT", -4, 0)
		
		-- Popout icon (simple arrow)
		local popoutIcon = popoutBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		popoutIcon:SetAllPoints()
		popoutIcon:SetText("→")
		popoutIcon:SetTextColor(0.6, 0.8, 1, 1)
		
		popoutBtn:SetScript("OnClick", function()
			widget:ShowPopout()
		end)
		
		popoutBtn:SetScript("OnEnter", function()
			popoutIcon:SetTextColor(0.8, 0.9, 1, 1)
			GameTooltip:SetOwner(popoutBtn, "ANCHOR_RIGHT")
			GameTooltip:SetText("Open custom price editor")
			GameTooltip:Show()
		end)
		
		popoutBtn:SetScript("OnLeave", function()
			popoutIcon:SetTextColor(0.6, 0.8, 1, 1)
			GameTooltip:Hide()
		end)
		
		widget.popoutBtn = popoutBtn
		
		-- Validation indicator
		local validIcon = editbox.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		validIcon:SetPoint("LEFT", editbox.frame, "LEFT", 4, 0)
		validIcon:SetSize(16, 16)
		widget.validIcon = validIcon
		
		-- Methods
		function widget:OnAcquire()
			if self.editbox.OnAcquire then
				self.editbox:OnAcquire()
			end
			self:SetText("")
			self:SetValid(true)
		end
		
		function widget:OnRelease()
			if self.editbox.OnRelease then
				self.editbox:OnRelease()
			end
		end
		
		function widget:SetText(text)
			self.editbox:SetText(text)
			self:Validate(text)
		end
		
		function widget:GetText()
			return self.editbox:GetText()
		end
		
		function widget:SetLabel(text)
			if self.editbox.SetLabel then
				self.editbox:SetLabel(text)
			end
		end
		
		function widget:SetCallback(event, handler)
			if event == "OnTextChanged" then
				self.editbox:SetCallback("OnTextChanged", function(_, _, text)
					self:Validate(text)
					handler(self, event, text)
				end)
			else
				self.editbox:SetCallback(event, handler)
			end
		end
		
		function widget:Validate(text)
			-- Basic validation - check for valid price source syntax
			-- In real implementation, use TSMAPI:ValidateCustomPrice
			local isValid = true
			
			if text and text ~= "" then
				-- Simple check: ensure no unclosed parentheses
				local openCount = select(2, string.gsub(text, "%(", ""))
				local closeCount = select(2, string.gsub(text, "%)", ""))
				isValid = (openCount == closeCount)
				
				-- Check for basic syntax (optional)
				-- You can add more validation here
			end
			
			self:SetValid(isValid)
			return isValid
		end
		
		function widget:SetValid(valid)
			if valid then
				self.validIcon:SetText("|cff00ff00✓|r")
				self.validIcon:Show()
			else
				self.validIcon:SetText("|cffff0000✗|r")
				self.validIcon:Show()
			end
		end
		
		function widget:ShowPopout()
			-- Create a larger editor window
			local popup = AceGUI:Create("Window")
			if not popup then
				-- Fallback: use Frame
				popup = AceGUI:Create("Frame")
			end
			
			popup:SetTitle("Custom Price String Editor")
			popup:SetWidth(600)
			popup:SetHeight(400)
			popup:SetLayout("Fill")
			
			-- Multi-line editor
			local multiLine = AceGUI:Create("MultiLineEditBox")
			if not multiLine then
				-- Fallback
				multiLine = AceGUI:Create("EditBox")
			end
			
			multiLine:SetLabel("Custom Price String")
			multiLine:SetText(self:GetText())
			multiLine:SetCallback("OnTextChanged", function(_, _, text)
				self:SetText(text)
			end)
			popup:AddChild(multiLine)
			
			popup.frame:SetPoint("CENTER")
			popup.frame:Show()
		end
		
		-- Proxy other methods to editbox
		function widget:SetWidth(width)
			if self.editbox.SetWidth then
				self.editbox:SetWidth(width)
			end
		end
		
		function widget:SetHeight(height)
			if self.editbox.SetHeight then
				self.editbox:SetHeight(height)
			end
		end
		
		function widget:SetDisabled(disabled)
			if self.editbox.SetDisabled then
				self.editbox:SetDisabled(disabled)
			end
			self.popoutBtn:SetEnabled(not disabled)
		end
		
		return AceGUI:RegisterAsWidget(widget)
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

