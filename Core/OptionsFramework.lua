local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local OptionsFramework = {}
TSM.OptionsFramework = OptionsFramework
TSMAPI.OptionsFramework = OptionsFramework

local TreeContext = {}
TreeContext.__index = TreeContext

function OptionsFramework.CreateTree(parent, config)
	assert(type(config) == "table", "OptionsFramework requires a config table.")
	assert(type(config.nodes) == "table" and #config.nodes > 0, "OptionsFramework requires at least one node.")

	local context = setmetatable({
		config = config,
		valueMap = {},
	}, TreeContext)

	local treeGroup = AceGUI:Create("TSMTreeGroup")
	treeGroup:SetLayout("Fill")
	treeGroup:SetStatusTable(config.statusTable)
	treeGroup:SetCallback("OnGroupSelected", function(_, _, selection)
		context:_OnSelect(selection)
	end)
	parent:AddChild(treeGroup)

	context.treeGroup = treeGroup

	context:RefreshTree()

	if config.initialSelection then
		context:SelectPath(unpack(config.initialSelection))
	elseif config.nodes[1] then
		context:SelectPath(config.nodes[1].value)
	end

	return context
end

function TreeContext:RefreshTree()
	local treeData = {}
	wipe(self.valueMap)

	for _, node in ipairs(self.config.nodes) do
		self.valueMap[tostring(node.value)] = node
		if node.type == "operations" then
			local children = {}
			local getChildren = node.getChildren
			if type(getChildren) == "function" then
				local names = getChildren()
				if type(names) == "table" then
					sort(names)
					for _, name in ipairs(names) do
						tinsert(children, { value = name, text = name })
					end
				end
			end
			tinsert(treeData, { value = node.value, text = node.text, children = children })
		else
			tinsert(treeData, { value = node.value, text = node.text })
		end
	end

	self.treeGroup:SetTree(treeData)
end

function TreeContext:SelectPath(...)
	if select("#", ...) == 0 then return end
	self.treeGroup:SelectByPath(...)
end

function TreeContext:_OnSelect(selection)
	if not selection then return end

	self.treeGroup:ReleaseChildren()

	local major, minor = ("\001"):split(selection)
	local node = self.valueMap[major]
	if not node then return end

	if node.type == "operations" then
		if minor then
			if node.drawOperation then
				node.drawOperation(self.treeGroup, minor)
			end
		elseif node.drawNew then
			node.drawNew(self.treeGroup)
		end
	else
		if node.draw then
			node.draw(self.treeGroup)
		end
	end
end

