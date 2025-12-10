-- Settings Helper - Enhanced settings management
-- Provides validation, defaults, and migrations

local TSM = select(2, ...)
local SettingsHelper = {}
TSM.SettingsHelper = SettingsHelper

local private = {
	schemas = {},
	validators = {},
}

-- ============================================================================
-- Module Functions
-- ============================================================================

--- Register a settings schema
-- @param schemaName string Name of the schema
-- @param schema table Schema definition
function SettingsHelper.RegisterSchema(schemaName, schema)
	assert(type(schemaName) == "string", "schemaName must be a string")
	assert(type(schema) == "table", "schema must be a table")
	
	private.schemas[schemaName] = schema
end

--- Get default value for a setting
-- @param schemaName string Schema name
-- @param key string Setting key
-- @return any Default value
function SettingsHelper.GetDefault(schemaName, key)
	local schema = private.schemas[schemaName]
	if not schema or not schema[key] then
		return nil
	end
	
	return schema[key].default
end

--- Validate a setting value
-- @param schemaName string Schema name
-- @param key string Setting key
-- @param value any Value to validate
-- @return boolean, string Valid, error message
function SettingsHelper.Validate(schemaName, key, value)
	local schema = private.schemas[schemaName]
	if not schema or not schema[key] then
		return false, "Unknown setting: " .. tostring(key)
	end
	
	local setting = schema[key]
	
	-- Type validation
	if setting.type and type(value) ~= setting.type then
		return false, "Expected " .. setting.type .. ", got " .. type(value)
	end
	
	-- Range validation for numbers
	if setting.type == "number" then
		if setting.min and value < setting.min then
			return false, "Value below minimum: " .. setting.min
		end
		if setting.max and value > setting.max then
			return false, "Value above maximum: " .. setting.max
		end
	end
	
	-- Custom validator
	if setting.validator then
		return setting.validator(value)
	end
	
	return true
end

--- Apply defaults to settings table
-- @param schemaName string Schema name
-- @param settings table Settings table
function SettingsHelper.ApplyDefaults(schemaName, settings)
	local schema = private.schemas[schemaName]
	if not schema then return end
	
	for key, setting in pairs(schema) do
		if settings[key] == nil then
			settings[key] = setting.default
		end
	end
end

-- ============================================================================
-- Example Schema
-- ============================================================================

--[[
local exampleSchema = {
	fontSize = {
		type = "number",
		default = 14,
		min = 10,
		max = 20,
		description = "Font size for UI elements"
	},
	theme = {
		type = "string",
		default = "moderndark",
		validator = function(value)
			local validThemes = {"moderndark", "classic", "goblineer"}
			if not tContains(validThemes, value) then
				return false, "Invalid theme"
			end
			return true
		end,
		description = "UI theme"
	},
}

SettingsHelper.RegisterSchema("appearance", exampleSchema)
]]

