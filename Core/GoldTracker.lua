-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster: Modern                           --
--          https://github.com/XiusTV/Modern-TSM-335                            --
--               All Rights Reserved - Backport to 3.3.5                        --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...) or _G.TSM
if not TSM then error("TSM not found!") return end

-- GoldTracker: Tracks player and guild gold over time
-- Based on retail TSM's GoldTracker service

local GoldTracker = {}
local private = {
	characterLog = {}, -- {characterKey => GoldLog}
	characterLastUpdate = {}, -- {characterKey => timestamp}
	guildLog = {}, -- {guildName => GoldLog}
	guildLastUpdate = {}, -- {guildName => timestamp}
	currentCharacterKey = nil,
	isInitialized = false,
}

local SECONDS_PER_MIN = 60
local SECONDS_PER_DAY = SECONDS_PER_MIN * 60 * 24

-- ============================================================================
-- Initialization
-- ============================================================================

function GoldTracker.Initialize()
	if private.isInitialized then
		return
	end
	
	-- Generate current character key: "CharName-RealmName"
	private.currentCharacterKey = UnitName("player") .. "-" .. GetRealmName()
	
	-- Load saved data from SavedVariables
	if not _G.AscensionTSMDB then
		_G.AscensionTSMDB = {}
	end
	if not _G.AscensionTSMDB.goldTracking then
		_G.AscensionTSMDB.goldTracking = {
			characters = {},
			guilds = {},
		}
	end
	
	local savedData = _G.AscensionTSMDB.goldTracking
	
	-- Load character gold logs
	for charKey, data in pairs(savedData.characters or {}) do
		local log = _G.TSM.GoldLog.Load(data.log)
		if log then
			private.characterLog[charKey] = log
			private.characterLastUpdate[charKey] = data.lastUpdate or 0
		end
	end
	
	-- Load guild gold logs
	for guildName, data in pairs(savedData.guilds or {}) do
		local log = _G.TSM.GoldLog.Load(data.log)
		if log then
			private.guildLog[guildName] = log
			private.guildLastUpdate[guildName] = data.lastUpdate or 0
		end
	end
	
	-- Ensure current character has a log
	if not private.characterLog[private.currentCharacterKey] then
		private.characterLog[private.currentCharacterKey] = _G.TSM.GoldLog.New()
	end
	
	-- Register events
	TSM:RegisterEvent("PLAYER_MONEY", function()
		private.PlayerLogGold()
	end)
	
	TSM:RegisterEvent("GUILDBANKFRAME_OPENED", function()
		private.GuildLogGold()
	end)
	
	TSM:RegisterEvent("PLAYER_LOGOUT", function()
		GoldTracker.SaveData()
	end)
	
	private.isInitialized = true
	
	-- Log initial gold
	private.PlayerLogGold()
end

-- ============================================================================
-- Gold Logging Functions
-- ============================================================================

function private.PlayerLogGold()
	local money = GetMoney()
	if not money or money == 0 then
		return -- Skip if GetMoney() returns 0 (happens on login sometimes)
	end
	
	local currentMinute = math.floor(time() / SECONDS_PER_MIN)
	private.characterLog[private.currentCharacterKey]:Append(currentMinute, private.RoundCopperValue(money))
	private.characterLastUpdate[private.currentCharacterKey] = time()
end

function private.GuildLogGold()
	local guildName = GetGuildInfo("player")
	if not guildName then
		return
	end
	
	-- Check if player is guild leader (only guild leaders can see bank gold accurately)
	local _, _, rank = GetGuildInfo("player")
	if rank ~= 0 then
		return -- Not guild leader
	end
	
	-- Get guild bank money (if available)
	-- Note: This requires the guild bank to be open
	local money = GetGuildBankMoney and GetGuildBankMoney()
	if not money or money == 0 then
		return
	end
	
	if not private.guildLog[guildName] then
		private.guildLog[guildName] = _G.TSM.GoldLog.New()
	end
	
	local currentMinute = math.floor(time() / SECONDS_PER_MIN)
	private.guildLog[guildName]:Append(currentMinute, private.RoundCopperValue(money))
	private.guildLastUpdate[guildName] = time()
end

function private.RoundCopperValue(copper)
	-- Round to nearest gold for storage efficiency
	return math.floor((copper + 5000) / 10000) * 10000
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Get list of all tracked characters and guilds
-- @param resultTbl table Table to populate with character/guild names
function GoldTracker.GetCharacterGuilds(resultTbl)
	for charKey in pairs(private.characterLog) do
		table.insert(resultTbl, charKey)
	end
	for guildName in pairs(private.guildLog) do
		table.insert(resultTbl, guildName)
	end
end

--- Get gold amount at a specific timestamp
-- @param timestamp number Unix timestamp
-- @param ignoredCharactersGuilds table Characters/guilds to ignore
-- @return number Total gold in copper
function GoldTracker.GetGoldAtTime(timestamp, ignoredCharactersGuilds)
	ignoredCharactersGuilds = ignoredCharactersGuilds or {}
	local value = 0
	local timestampMinute = math.floor(timestamp / SECONDS_PER_MIN)
	
	for key, log in pairs(private.characterLog) do
		if not ignoredCharactersGuilds[key] then
			value = value + log:GetValue(timestampMinute)
		end
	end
	
	for key, log in pairs(private.guildLog) do
		if not ignoredCharactersGuilds[key] then
			value = value + log:GetValue(timestampMinute)
		end
	end
	
	return value
end

--- Get the time range for the graph
-- @param ignoredCharactersGuilds table Characters/guilds to ignore
-- @return number minTime, number maxTime, number step
function GoldTracker.GetGraphTimeRange(ignoredCharactersGuilds)
	ignoredCharactersGuilds = ignoredCharactersGuilds or {}
	local minTime = math.floor(time() / SECONDS_PER_MIN) * SECONDS_PER_MIN
	local maxTime = minTime
	
	for key, log in pairs(private.characterLog) do
		if not ignoredCharactersGuilds[key] then
			local startMinute = log:GetStartMinute()
			if startMinute then
				minTime = math.min(minTime, startMinute * SECONDS_PER_MIN)
			end
		end
	end
	
	for key, log in pairs(private.guildLog) do
		if not ignoredCharactersGuilds[key] then
			local startMinute = log:GetStartMinute()
			if startMinute then
				minTime = math.min(minTime, startMinute * SECONDS_PER_MIN)
			end
		end
	end
	
	return minTime, maxTime, SECONDS_PER_MIN
end

--- Save all gold tracking data
function GoldTracker.SaveData()
	if not _G.AscensionTSMDB or not _G.AscensionTSMDB.goldTracking then
		return
	end
	
	local savedData = _G.AscensionTSMDB.goldTracking
	
	-- Save character logs
	for charKey, log in pairs(private.characterLog) do
		savedData.characters[charKey] = {
			log = log:Serialize(),
			lastUpdate = private.characterLastUpdate[charKey] or 0,
		}
	end
	
	-- Save guild logs
	for guildName, log in pairs(private.guildLog) do
		savedData.guilds[guildName] = {
			log = log:Serialize(),
			lastUpdate = private.guildLastUpdate[guildName] or 0,
		}
	end
end

-- ============================================================================
-- Module Registration
-- ============================================================================

TSM.GoldTracker = GoldTracker

