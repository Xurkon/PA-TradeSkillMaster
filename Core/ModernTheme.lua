-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                                Modern Dark Theme                                --
--                                                                                --
--             Inspired by TSM Retail - Sleek, Modern Dark Interface              --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)

-- Modern Dark Theme (Retail-Inspired)
TSM.modernDarkTheme = {
	name = "Modern Dark",
	frameColors = {
		-- Main frame background (darker, more modern)
		frameBG = { 
			backdrop = { 15, 15, 15, 0.95 },  -- Deep dark background
			border = { 40, 40, 40, 1 }         -- Subtle border
		},
		-- Secondary frames
		frame = { 
			backdrop = { 20, 20, 20, 1 },      -- Slightly lighter dark
			border = { 60, 60, 60, 0.4 }        -- More visible border
		},
		-- Content areas (like the item lists)
		content = { 
			backdrop = { 28, 28, 28, 1 },      -- Content background
			border = { 50, 50, 50, 0.3 }        -- Subtle separation
		},
		-- Highlighted/selected items (gold/yellow highlight like retail)
		highlight = {
			backdrop = { 60, 50, 10, 0.3 },    -- Golden highlight
			border = { 255, 200, 0, 0.8 }      -- Bright gold border
		},
		-- Hover state (subtle blue glow)
		hover = {
			backdrop = { 40, 45, 55, 0.3 },
			border = { 100, 150, 255, 0.5 }
		},
	},
	textColors = {
		-- Icons and item quality indicators
		iconRegion = { 
			enabled = { 255, 255, 255, 1 } 
		},
		-- Main text (bright white for readability)
		text = { 
			enabled = { 255, 255, 255, 1 },    -- Pure white
			disabled = { 130, 130, 130, 1 }    -- Gray when disabled
		},
		-- Labels and secondary text
		label = { 
			enabled = { 200, 200, 200, 1 },    -- Light gray
			disabled = { 110, 110, 110, 1 }    -- Darker gray when disabled
		},
		-- Titles and headers (gold accent like retail)
		title = { 
			enabled = { 255, 209, 0, 1 }       -- Bright gold (retail-style)
		},
		-- Links and clickable elements
		link = { 
			enabled = { 100, 180, 255, 1 }     -- Bright blue
		},
		-- Success/positive text
		success = {
			enabled = { 0, 255, 100, 1 }       -- Bright green
		},
		-- Warning/caution text
		warning = {
			enabled = { 255, 180, 0, 1 }       -- Orange
		},
		-- Error/negative text
		error = {
			enabled = { 255, 50, 50, 1 }       -- Red
		},
	},
	inlineColors = {
		-- Hyperlinks
		link = { 100, 180, 255, 255 },         -- Bright blue
		link2 = { 150, 200, 255, 255 },        -- Lighter blue
		-- Categories and groups
		category = { 255, 209, 0, 255 },       -- Gold (matches title)
		category2 = { 255, 180, 50, 255 },     -- Lighter gold
		-- Tooltips
		tooltip = { 150, 200, 255, 255 },      -- Light blue
		-- Advanced/warning items
		advanced = { 255, 100, 100, 255 },     -- Light red
		-- Success indicators
		positive = { 100, 255, 150, 255 },     -- Green
		-- Currency/gold
		gold = { 255, 220, 100, 255 },         -- Golden yellow
	},
	edgeSize = 1,  -- Thin borders for modern look
	fonts = {
		content = "Arial Narrow",
		bold = "TSM Droid Sans Bold",
	},
	fontSizes = {
		normal = 14,    -- Slightly smaller for modern look
		medium = 12,
		small = 11,
		large = 16,
		title = 18,
	},
}

-- Classic Theme (Original TSM Look)
TSM.classicTheme = {
	name = "Classic",
	frameColors = {
		frameBG = { backdrop = { 24, 24, 24, .93 }, border = { 30, 30, 30, 1 } },
		frame = { backdrop = { 24, 24, 24, 1 }, border = { 255, 255, 255, 0.03 } },
		content = { backdrop = { 42, 42, 42, 1 }, border = { 0, 0, 0, 0 } },
	},
	textColors = {
		iconRegion = { enabled = { 249, 255, 247, 1 } },
		text = { enabled = { 255, 254, 250, 1 }, disabled = { 147, 151, 139, 1 } },
		label = { enabled = { 216, 225, 211, 1 }, disabled = { 150, 148, 140, 1 } },
		title = { enabled = { 132, 219, 9, 1 } },
		link = { enabled = { 49, 56, 133, 1 } },
	},
	inlineColors = {
		link = { 153, 255, 255, 1 },
		link2 = { 153, 255, 255, 1 },
		category = { 36, 106, 36, 1 },
		category2 = { 85, 180, 8, 1 },
		tooltip = { 130, 130, 250, 1 },
		advanced = { 255, 30, 0, 1 },
	},
	edgeSize = 1.5,
	fonts = {
		content = "Arial Narrow",
		bold = "TSM Droid Sans Bold",
	},
	fontSizes = {
		normal = 15,
		medium = 13,
		small = 12,
	},
}

-- High Contrast Theme (for visibility)
TSM.highContrastTheme = {
	name = "High Contrast",
	frameColors = {
		frameBG = { backdrop = { 0, 0, 0, 0.98 }, border = { 255, 255, 255, 1 } },
		frame = { backdrop = { 10, 10, 10, 1 }, border = { 200, 200, 200, 0.8 } },
		content = { backdrop = { 20, 20, 20, 1 }, border = { 150, 150, 150, 0.6 } },
	},
	textColors = {
		iconRegion = { enabled = { 255, 255, 255, 1 } },
		text = { enabled = { 255, 255, 255, 1 }, disabled = { 100, 100, 100, 1 } },
		label = { enabled = { 240, 240, 240, 1 }, disabled = { 90, 90, 90, 1 } },
		title = { enabled = { 255, 255, 0, 1 } },
		link = { enabled = { 100, 200, 255, 1 } },
	},
	inlineColors = {
		link = { 100, 200, 255, 255 },
		link2 = { 150, 220, 255, 255 },
		category = { 255, 255, 0, 255 },
		category2 = { 255, 220, 100, 255 },
		tooltip = { 200, 200, 255, 255 },
		advanced = { 255, 100, 100, 255 },
	},
	edgeSize = 2,
	fonts = {
		content = "Arial Narrow",
		bold = "TSM Droid Sans Bold",
	},
	fontSizes = {
		normal = 15,
		medium = 13,
		small = 12,
	},
}

-- Theme management functions
function TSM:GetAvailableThemes()
	return {
		{ key = "modern", name = TSM.modernDarkTheme.name, theme = TSM.modernDarkTheme },
		{ key = "classic", name = TSM.classicTheme.name, theme = TSM.classicTheme },
		{ key = "highcontrast", name = TSM.highContrastTheme.name, theme = TSM.highContrastTheme },
	}
end

function TSM:ApplyTheme(themeKey)
	local themes = {
		modern = TSM.modernDarkTheme,
		classic = TSM.classicTheme,
		highcontrast = TSM.highContrastTheme,
	}
	
	local theme = themes[themeKey]
	if not theme then
		TSM:Print("Unknown theme: " .. tostring(themeKey))
		return
	end
	
	-- Apply theme to current design
	TSM.db.profile.design = CopyTable(theme)
	TSM.db.profile.currentTheme = themeKey
	
	-- Update all UI elements
	TSMAPI:UpdateDesign()
	
	TSM:Print("Applied theme: " .. theme.name)
	TSM:Print("Reload UI (/reload) for best results.")
end

function TSM:GetCurrentTheme()
	return TSM.db.profile.currentTheme or "classic"
end

-- Slash command to change themes
TSMAPI_SLASH_COMMANDS = TSMAPI_SLASH_COMMANDS or {}
TSMAPI_SLASH_COMMANDS.theme = function(themeKey)
	if not themeKey or themeKey == "" then
		TSM:Print("Available themes:")
		for _, info in ipairs(TSM:GetAvailableThemes()) do
			local current = (info.key == TSM:GetCurrentTheme()) and " (current)" or ""
			TSM:Print("  /tsm theme " .. info.key .. " - " .. info.name .. current)
		end
		return
	end
	
	TSM:ApplyTheme(themeKey)
end

