-- TSMGraph - Simple line graph for data visualization
-- Simplified version for gold tracking and price history

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

do
	local Type = "TSMGraph"
	local Version = 1
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:SetSize(400, 200)
		-- Note: SetClipsChildren doesn't exist in 3.3.5, rely on proper positioning
		
		local widget = {
			frame = frame,
			type = Type,
			dataPoints = {},
			dataSeries = {}, -- Support for multiple series
			minValue = 0,
			maxValue = 100,
			lines = {},
			linePool = {},
			multiSeriesMode = false,
		}
		
		-- Background
		local bg = frame:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
		widget.bg = bg
		
		-- Grid lines (horizontal)
		local gridLines = {}
		for i = 1, 5 do
			local line = frame:CreateTexture(nil, "ARTWORK")
			line:SetColorTexture(0.3, 0.3, 0.3, 0.3)
			line:SetHeight(1)
			tinsert(gridLines, line)
		end
		widget.gridLines = gridLines
		
		-- Methods
		function widget:OnAcquire()
			wipe(self.dataPoints)
			self:UpdateGraph()
		end
		
		function widget:OnRelease()
			-- Clean up lines
			for _, line in ipairs(self.lines) do
				line:Hide()
				line:ClearAllPoints()
			end
			wipe(self.lines)
			wipe(self.dataPoints)
			wipe(self.dataSeries)
			wipe(self.linePool)
			self.multiSeriesMode = false
		end
		
		function widget:SetData(dataPoints)
			-- Support two formats:
			-- 1. Simple: { {x=timestamp, y=value}, ... }
			-- 2. Multi-series: { {name="Gold", color={r,g,b,a}, data={{x,y},...}}, ... }
			
			wipe(self.dataPoints)
			wipe(self.dataSeries)
			self.multiSeriesMode = false
			
			-- Detect format
			if dataPoints and #dataPoints > 0 and dataPoints[1].data then
				-- Multi-series format
				self.multiSeriesMode = true
				for _, series in ipairs(dataPoints) do
					local newSeries = {
						name = series.name or "Series",
						color = series.color or {0, 1, 0, 1}, -- Default green
						data = {},
					}
					for _, point in ipairs(series.data) do
						tinsert(newSeries.data, {x = point.x, y = point.y})
					end
					tinsert(self.dataSeries, newSeries)
				end
			else
				-- Simple format - single series
				for _, point in ipairs(dataPoints) do
					tinsert(self.dataPoints, {x = point.x, y = point.y})
				end
			end
			
			-- Calculate min/max across all series
			self.minValue = math.huge
			self.maxValue = -math.huge
			
			if self.multiSeriesMode then
				for _, series in ipairs(self.dataSeries) do
					for _, point in ipairs(series.data) do
						self.minValue = math.min(self.minValue, point.y)
						self.maxValue = math.max(self.maxValue, point.y)
					end
				end
			else
				if #self.dataPoints > 0 then
					for _, point in ipairs(self.dataPoints) do
						self.minValue = math.min(self.minValue, point.y)
						self.maxValue = math.max(self.maxValue, point.y)
					end
				end
			end
			
			-- Handle edge cases
			if self.minValue == math.huge then
				self.minValue = 0
				self.maxValue = 100
			else
				-- Add 10% padding
				local range = self.maxValue - self.minValue
				if range > 0 then
					self.minValue = self.minValue - range * 0.1
					self.maxValue = self.maxValue + range * 0.1
				else
					-- Flat line, add arbitrary range
					self.minValue = self.minValue - 10
					self.maxValue = self.maxValue + 10
				end
			end
			
			self:UpdateGraph()
		end
		
		function widget:UpdateGraph()
			-- Clear old lines (hide and return to pool)
			for _, line in ipairs(self.lines) do
				line:Hide()
				line:ClearAllPoints()
				tinsert(self.linePool, line)
			end
			wipe(self.lines)
			
			local width = self.frame:GetWidth()
			local height = self.frame:GetHeight()
			
			-- Ensure valid dimensions
			if width <= 0 or height <= 0 then
				return
			end
			
			-- Update grid lines
			for i, line in ipairs(self.gridLines) do
				local y = (height / 6) * i
				line:ClearAllPoints()
				line:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -y)
				line:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -y)
			end
			
			if self.multiSeriesMode then
				-- Draw multiple series
				self:DrawMultiSeries(width, height)
			else
				-- Draw single series (backwards compatible)
				self:DrawSingleSeries(width, height)
			end
		end
		
		function widget:DrawSingleSeries(width, height)
			if #self.dataPoints < 2 then
				return
			end
			
			-- Draw data line using points
			local minX = self.dataPoints[1].x
			local maxX = self.dataPoints[#self.dataPoints].x
			local rangeX = maxX - minX
			local rangeY = self.maxValue - self.minValue
			
			-- Prevent division by zero
			if rangeX == 0 then rangeX = 1 end
			if rangeY == 0 then rangeY = 1 end
			
			-- Draw line by creating small segments between points
			for i = 1, #self.dataPoints - 1 do
				local p1 = self.dataPoints[i]
				local p2 = self.dataPoints[i + 1]
				
				-- Calculate normalized positions (0-1)
				local normX1 = (p1.x - minX) / rangeX
				local normY1 = (p1.y - self.minValue) / rangeY
				local normX2 = (p2.x - minX) / rangeX
				local normY2 = (p2.y - self.minValue) / rangeY
				
				-- Clamp to valid range
				normX1 = math.max(0, math.min(1, normX1))
				normY1 = math.max(0, math.min(1, normY1))
				normX2 = math.max(0, math.min(1, normX2))
				normY2 = math.max(0, math.min(1, normY2))
				
				-- Convert to pixel positions
				local x1 = normX1 * width
				local y1 = normY1 * height
				local x2 = normX2 * width
				local y2 = normY2 * height
				
				-- Draw line using multiple small segments for smooth appearance
				local dx = x2 - x1
				local dy = y2 - y1
				local distance = math.sqrt(dx * dx + dy * dy)
				
				if distance > 0 and distance < 10000 then
					-- Number of segments based on distance (more segments = smoother line)
					local segments = math.max(1, math.floor(distance / 2))
					
					for seg = 0, segments - 1 do
						local t = seg / segments
						local x = x1 + dx * t
						local y = y1 + dy * t
						
						-- Get or create dot from pool
						local dot = tremove(self.linePool)
						if not dot then
							dot = self.frame:CreateTexture(nil, "OVERLAY")
						end
						dot:SetColorTexture(0, 1, 0, 1)  -- Green line
						dot:SetSize(2, 2)
						dot:ClearAllPoints()
						dot:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", x, y)
						dot:Show()
						tinsert(self.lines, dot)
					end
				end
			end
		end
		
		function widget:DrawMultiSeries(width, height)
			if #self.dataSeries == 0 then
				return
			end
			
			-- Find overall min/max X for all series
			local minX, maxX = math.huge, -math.huge
			for _, series in ipairs(self.dataSeries) do
				if #series.data > 0 then
					minX = math.min(minX, series.data[1].x)
					maxX = math.max(maxX, series.data[#series.data].x)
				end
			end
			
			if minX == math.huge then return end
			
			local rangeX = maxX - minX
			local rangeY = self.maxValue - self.minValue
			
			-- Prevent division by zero
			if rangeX == 0 then rangeX = 1 end
			if rangeY == 0 then rangeY = 1 end
			
			-- Draw each series
			for _, series in ipairs(self.dataSeries) do
				if #series.data >= 2 then
					local color = series.color
					
					for i = 1, #series.data - 1 do
						local p1 = series.data[i]
						local p2 = series.data[i + 1]
						
						-- Calculate normalized positions (0-1)
						local normX1 = (p1.x - minX) / rangeX
						local normY1 = (p1.y - self.minValue) / rangeY
						local normX2 = (p2.x - minX) / rangeX
						local normY2 = (p2.y - self.minValue) / rangeY
						
						-- Clamp to valid range
						normX1 = math.max(0, math.min(1, normX1))
						normY1 = math.max(0, math.min(1, normY1))
						normX2 = math.max(0, math.min(1, normX2))
						normY2 = math.max(0, math.min(1, normY2))
						
						-- Convert to pixel positions
						local x1 = normX1 * width
						local y1 = normY1 * height
						local x2 = normX2 * width
						local y2 = normY2 * height
						
						-- Draw line using multiple small segments for smooth appearance
						local dx = x2 - x1
						local dy = y2 - y1
						local distance = math.sqrt(dx * dx + dy * dy)
						
						if distance > 0 and distance < 10000 then
							-- Number of segments based on distance (more segments = smoother line)
							local segments = math.max(1, math.floor(distance / 2))
							
							for seg = 0, segments - 1 do
								local t = seg / segments
								local x = x1 + dx * t
								local y = y1 + dy * t
								
								-- Get or create dot from pool
								local dot = tremove(self.linePool)
								if not dot then
									dot = self.frame:CreateTexture(nil, "OVERLAY")
								end
								dot:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
								dot:SetSize(2, 2)
								dot:ClearAllPoints()
								dot:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", x, y)
								dot:Show()
								tinsert(self.lines, dot)
							end
						end
					end
				end
			end
		end
		
		function widget:OnWidthSet(width)
			self:UpdateGraph()
		end
		
		function widget:OnHeightSet(height)
			self:UpdateGraph()
		end
		
		return AceGUI:RegisterAsWidget(widget)
	end
	
	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

