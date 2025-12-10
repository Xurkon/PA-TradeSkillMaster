local MAJOR, MINOR = "LibGraph-2.0", 4
local LibStub = LibStub
assert(LibStub, MAJOR .. " requires LibStub")

local LibGraph, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not LibGraph then return end

local GraphMixin = {}
GraphMixin.__index = GraphMixin

local function AcquireTexture(self)
	local tex = tremove(self._linePool)
	if tex then
		return tex
	end

	tex = self._frame:CreateTexture(nil, "ARTWORK")
	return tex
end

local function ReleaseAllTextures(self)
	for _, tex in ipairs(self._lines) do
		tex:Hide()
		tex:ClearAllPoints()
		tinsert(self._linePool, tex)
	end
	wipe(self._lines)
end

local function Clamp01(value)
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

local function FormatMoney(value)
	if value >= 1e6 or value <= -1e6 then
		return string.format("%.1fm", value / 1e6)
	elseif value >= 1e3 or value <= -1e3 then
		return string.format("%.1fk", value / 1e3)
	end
	return string.format("%.0f", value)
end

-----------------------------------------------------------------------
-- Graph mixin
-----------------------------------------------------------------------

function GraphMixin:SetGridColor(color)
	color = color or { 0.3, 0.3, 0.3, 0.3 }
	self._gridColor = color
	for _, line in ipairs(self._gridLines) do
		line:SetColorTexture(color[1], color[2], color[3], color[4] or 0.3)
	end
end

function GraphMixin:SetYLabels(enabled)
	self._showYLabels = not not enabled
	for _, fontString in ipairs(self._yLabels) do
		fontString:SetShown(self._showYLabels)
	end
end

function GraphMixin:SetParent(parent)
	self._frame:SetParent(parent)
end

function GraphMixin:Show()
	self._frame:Show()
end

function GraphMixin:Hide()
	self._frame:Hide()
end

function GraphMixin:SetPoint(...)
	self._frame:SetPoint(...)
end

function GraphMixin:ClearAllPoints()
	self._frame:ClearAllPoints()
end

function GraphMixin:SetAllPoints(...)
	self._frame:SetAllPoints(...)
end

function GraphMixin:SetWidth(width)
	self._frame:SetWidth(width)
	self:RefreshGraph()
end

function GraphMixin:SetHeight(height)
	self._frame:SetHeight(height)
	self:RefreshGraph()
end

function GraphMixin:SetGridSpacing(xSpacing, ySpacing)
	self._gridSpacingX = xSpacing
	self._gridSpacingY = ySpacing
end

function GraphMixin:SetCanvasColor(r, g, b, a)
	self._background:SetColorTexture(r or 0.05, g or 0.05, b or 0.05, a or 0.9)
end

function GraphMixin:SetXAxis(minValue, maxValue)
	self._minX = minValue or 0
	self._maxX = maxValue or 1
end

function GraphMixin:SetYAxis(minValue, maxValue)
	self._minY = minValue or 0
	self._maxY = maxValue or 1
end

function GraphMixin:ResetData()
	wipe(self._series)
	self._minX, self._maxX = nil, nil
	self._minY, self._maxY = nil, nil
end

function GraphMixin:AddDataSeries(data, color)
	if type(data) ~= "table" or #data == 0 then
		return
	end

	color = color or { 0, 0.7, 1, 1 }
	local series = {
		data = data,
		color = color,
	}
	tinsert(self._series, series)

	for _, point in ipairs(data) do
		local x, y = point[1] or point.x, point[2] or point.y
		if x and y then
			if not self._minX or x < self._minX then
				self._minX = x
			end
			if not self._maxX or x > self._maxX then
				self._maxX = x
			end
			if not self._minY or y < self._minY then
				self._minY = y
			end
			if not self._maxY or y > self._maxY then
				self._maxY = y
			end
		end
	end
end

local function NormalizeRange(minValue, maxValue)
	if not minValue or not maxValue or minValue == maxValue then
		minValue = minValue or 0
		maxValue = maxValue or (minValue + 1)
		if minValue == maxValue then
			maxValue = minValue + 1
		end
	end
	return minValue, maxValue
end

function GraphMixin:RefreshGraph()
	local width = self._frame:GetWidth()
	local height = self._frame:GetHeight()
	if width == 0 or height == 0 then
		return
	end

	ReleaseAllTextures(self)

	local minX, maxX = NormalizeRange(self._minX, self._maxX)
	local minY, maxY = NormalizeRange(self._minY, self._maxY)
	local rangeX = maxX - minX
	local rangeY = maxY - minY

	-- Update Y labels
	if self._showYLabels then
		for index, label in ipairs(self._yLabels) do
			local pct = (index - 1) / (#self._yLabels - 1)
			local value = minY + (rangeY * pct)
			label:SetText(FormatMoney(value))
		end
	end

	-- Position grid lines
	for i, line in ipairs(self._gridLines) do
		local pct = i / (#self._gridLines + 1)
		local offset = height * pct
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", self._frame, "TOPLEFT", 0, -offset)
		line:SetPoint("TOPRIGHT", self._frame, "TOPRIGHT", 0, -offset)
	end

	for _, series in ipairs(self._series) do
		if #series.data >= 2 then
			for index = 1, #series.data - 1 do
				local pointA = series.data[index]
				local pointB = series.data[index + 1]
				local x1 = ( (pointA[1] or pointA.x) - minX ) / rangeX
				local y1 = ( (pointA[2] or pointA.y) - minY ) / rangeY
				local x2 = ( (pointB[1] or pointB.x) - minX ) / rangeX
				local y2 = ( (pointB[2] or pointB.y) - minY ) / rangeY

				x1 = Clamp01(x1) * width
				y1 = Clamp01(y1) * height
				x2 = Clamp01(x2) * width
				y2 = Clamp01(y2) * height

				local dx = x2 - x1
				local dy = y2 - y1
				local distance = math.sqrt(dx * dx + dy * dy)
				if distance > 0 then
					local segments = math.max(1, math.floor(distance / 2))
					for seg = 0, segments - 1 do
						local t = seg / segments
						local x = x1 + (dx * t)
						local y = y1 + (dy * t)

						local tex = AcquireTexture(self)
						tex:SetColorTexture(series.color[1], series.color[2], series.color[3], series.color[4] or 1)
						tex:SetSize(2, 2)
						tex:ClearAllPoints()
						tex:SetPoint("BOTTOMLEFT", self._frame, "BOTTOMLEFT", x, y)
						tex:Show()
						tinsert(self._lines, tex)
					end
				end
			end
		end
	end
end

-----------------------------------------------------------------------
-- Constructor
-----------------------------------------------------------------------

local function CreateBaseFrame(name, parent, point, relativeTo, relativePoint, ofsx, ofsy, width, height)
	local frame = CreateFrame("Frame", name, parent)
	frame:SetSize(width or 300, height or 150)
	if point then
		frame:SetPoint(point, relativeTo, relativePoint, ofsx or 0, ofsy or 0)
	end

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)

	local gridLines = {}
	for _ = 1, 4 do
		local line = frame:CreateTexture(nil, "BORDER")
		line:SetHeight(1)
		line:SetColorTexture(0.3, 0.3, 0.3, 0.3)
		tinsert(gridLines, line)
	end

	local yLabels = {}
	for _ = 1, 3 do
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("RIGHT", frame, "LEFT", -4, 0)
		label:SetJustifyH("RIGHT")
		label:Hide()
		tinsert(yLabels, label)
	end

	return frame, bg, gridLines, yLabels
end

function LibGraph:CreateGraphLine(name, parent, point, relativeTo, relativePoint, ofsx, width, height)
	local frame, bg, gridLines, yLabels = CreateBaseFrame(name, parent, point, relativeTo or parent, relativePoint or point, ofsx, 0, width, height)

	local graph = setmetatable({
		_frame = frame,
		_background = bg,
		_gridLines = gridLines,
		_yLabels = yLabels,
		_lines = {},
		_linePool = {},
		_series = {},
		_minX = nil,
		_maxX = nil,
		_minY = nil,
		_maxY = nil,
		_gridColor = { 0.3, 0.3, 0.3, 0.3 },
		_showYLabels = false,
	}, GraphMixin)

	graph:SetGridColor(graph._gridColor)
	return graph
end

-----------------------------------------------------------------------
-- Backwards compatibility helpers
-----------------------------------------------------------------------

LibGraph.CreateGraph = LibGraph.CreateGraphLine

