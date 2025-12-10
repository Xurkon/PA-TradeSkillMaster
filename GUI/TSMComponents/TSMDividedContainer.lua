-- TSMDividedContainer - Resizable split panel
-- Based on retail TSM4 LibTSMUI DividedContainer

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

-- ============================================================================
-- TSMDividedContainer Widget
-- ============================================================================

do
	local Type = "TSMDividedContainer"
	local Version = 1
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:SetSize(400, 300)
		
		local widget = {
			frame = frame,
			type = Type,
			children = {},
			leftChild = nil,
			rightChild = nil,
			dividerPosition = 0.5,  -- 50% default
			minLeftWidth = 100,
			minRightWidth = 100,
			isDragging = false,
		}
		
		-- Create container frames
		local leftFrame = CreateFrame("Frame", nil, frame)
		leftFrame:SetPoint("TOPLEFT")
		leftFrame:SetPoint("BOTTOMLEFT")
		widget.leftFrame = leftFrame
		
		local rightFrame = CreateFrame("Frame", nil, frame)
		rightFrame:SetPoint("TOPRIGHT")
		rightFrame:SetPoint("BOTTOMRIGHT")
		widget.rightFrame = rightFrame
		
		-- Create divider
		local divider = CreateFrame("Frame", nil, frame)
		divider:SetWidth(4)
		divider:SetPoint("TOP")
		divider:SetPoint("BOTTOM")
		divider:EnableMouse(true)
		divider:SetScript("OnEnter", function(self)
			SetCursor("UI_RESIZE_LR_CURSOR")
		end)
		divider:SetScript("OnLeave", function(self)
			ResetCursor()
		end)
		divider:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				widget.isDragging = true
			end
		end)
		divider:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				widget.isDragging = false
			end
		end)
		divider:SetScript("OnUpdate", function(self)
			if widget.isDragging then
				local parentWidth = frame:GetWidth()
				local mouseX = GetCursorPosition() / UIParent:GetEffectiveScale()
				local frameX = frame:GetLeft()
				local relativeX = mouseX - frameX
				
				-- Calculate new position (clamped to min widths)
				local newPosition = relativeX / parentWidth
				newPosition = math.max(widget.minLeftWidth / parentWidth, newPosition)
				newPosition = math.min(1 - (widget.minRightWidth / parentWidth), newPosition)
				
				if newPosition ~= widget.dividerPosition then
					widget:SetDividerPosition(newPosition)
				end
			end
		end)
		
		-- Visual divider line
		local dividerTexture = divider:CreateTexture(nil, "BACKGROUND")
		dividerTexture:SetAllPoints()
		dividerTexture:SetColorTexture(0.3, 0.3, 0.3, 1)
		
		widget.divider = divider
		widget.dividerTexture = dividerTexture
		
		-- Methods
		function widget:OnAcquire()
			self:SetDividerPosition(0.5)
		end
		
		function widget:OnRelease()
			self.leftChild = nil
			self.rightChild = nil
			wipe(self.children)
		end
		
		function widget:SetDividerPosition(position)
			self.dividerPosition = position
			self:UpdateLayout()
		end
		
		function widget:UpdateLayout()
			local width = self.frame:GetWidth()
			local leftWidth = width * self.dividerPosition
			local rightWidth = width - leftWidth - 4  -- 4px for divider
			
			self.leftFrame:SetWidth(leftWidth)
			self.rightFrame:SetWidth(rightWidth)
			
			self.divider:SetPoint("LEFT", self.leftFrame, "RIGHT", 0, 0)
		end
		
		function widget:SetLeftChild(child)
			if self.leftChild then
				self.leftChild:Release()
			end
			self.leftChild = child
			child.frame:SetParent(self.leftFrame)
			child.frame:SetAllPoints(self.leftFrame)
			if child.SetLayout then
				child:SetLayout("Fill")
			end
		end
		
		function widget:SetRightChild(child)
			if self.rightChild then
				self.rightChild:Release()
			end
			self.rightChild = child
			child.frame:SetParent(self.rightFrame)
			child.frame:SetAllPoints(self.rightFrame)
			if child.SetLayout then
				child:SetLayout("Fill")
			end
		end
		
		function widget:OnWidthSet(width)
			self:UpdateLayout()
		end
		
		function widget:OnHeightSet(height)
			-- Height is managed by anchors
		end
		
		function widget:SetMinWidths(minLeft, minRight)
			self.minLeftWidth = minLeft or 100
			self.minRightWidth = minRight or 100
		end
		
		return AceGUI:RegisterAsWidget(widget)
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

