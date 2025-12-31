local _, ns = ...

-- Local shortcuts for global functions
local _G = _G
local floor = math.floor
local ipairs = ipairs
local min = math.min
local next = next

-- Wow APIs
local C_MythicPlus = C_MythicPlus -- luacheck: globals C_MythicPlus
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local GetRealZoneText = GetRealZoneText -- luacheck: globals GetRealZoneText
local strlenutf8 = strlenutf8 -- luacheck: globals strlenutf8
local C_WeeklyRewards = C_WeeklyRewards -- luacheck: globals C_WeeklyRewards

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- Local/session variables
local util = ns.util
local data = ns.data
local mythicFrame, keystoneFrame, rewardsFrame
local startColor = CreateColorFromHexString("ff00ff16")
local endColor = CreateColorFromHexString("ff7bacff")

local function EuivinMythicHandler(event)
    if event == "EUIVIN_MYTHIC_KEYSTONE" then
        local name = _G.EuivinMythicCache.keystone.name
        local level = _G.EuivinMythicCache.keystone.level
        if name == "" or level == 0 then
            keystoneFrame:Hide()
            rewardsFrame:SetPointsOffset(0, -15)
        else
            keystoneFrame.label:SetText(name)
            keystoneFrame.value:SetText("+" .. level)

            local width
            width = floor((min(level, 12) / 12) * 176)
            keystoneFrame.bar:SetWidth(width)

            keystoneFrame:Show()
            rewardsFrame:SetPointsOffset(0, -30)
        end
        util.ExpandFrame(mythicFrame)
        return
    end

    -- event == "EUIVIN_MYTHIC_REWARDS"
    local runs = _G.EuivinMythicCache.runs
    -- TODO: Localize strings
    rewardsFrame.label:SetFormattedText("주차 [%d/8]", runs)

    local width
    width = floor((runs / 8) * 176)
    if width == 0 then
        rewardsFrame.bar:Hide()
    else
        rewardsFrame.bar:Show()
        rewardsFrame.bar:SetWidth(width)
    end

    local rewardsText = ""
    for i, ilvl in ipairs(_G.EuivinMythicCache.rewards) do
        if ilvl == 0 then
            break
        end
        if i == 1 then
            rewardsText = ilvl
        else
            rewardsText = rewardsText .. " || " .. ilvl
        end
    end
    rewardsFrame.value:SetText(rewardsText)
end

local function EuivinInitMythic()
    if _G.EuivinMythicCache == nil or next(_G.EuivinMythicCache) == nil then
        -- XXX: Wrong indentation by `lua-ts-mode`
        _G.EuivinMythicCache = {
            ["keystone"] = {
                               ["name"] = "",
                               ["level"] = 0,
            },
            ["rewards" ] = { 0, 0, 0 },
            ["runs"] = 0,
            ["init"] = false,
        }
    end

    if _G.EuivinMythic == nil then
        _G.EuivinMythic = {}
    end
    if _G.EuivinMythic.callbacks == nil then
        _G.EuivinMythic.callbacks = LibStub("CallbackHandler-1.0"):New(_G.EuivinMythic)
    end

    local events = {
        "EUIVIN_MYTHIC_KEYSTONE",
        "EUIVIN_MYTHIC_REWARDS",
    }
    for _, e in ipairs(events) do
        _G.EuivinMythic:RegisterCallback(e, EuivinMythicHandler, e)
    end
end

local function EuivinGetKeystone()
    local updated = false

    -- When the keystone is not found
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if mapID == nil then
        _G.EuivinMythicCache.keystone = { ["name"] = "", ["level"] = 0 }
        _G.EuivinMythic.callbacks:Fire("EUIVIN_MYTHIC_KEYSTONE")
        return
    end

    local name
    local dungeonName = GetRealZoneText(mapID)
    if strlenutf8(dungeonName) > 10 then
        name = util.WA_Utf8Sub(dungeonName, 10) .. "..."
    else
        name = dungeonName
    end
    if _G.EuivinMythicCache.keystone.name ~= name then
        _G.EuivinMythicCache.keystone.name = name
        updated = true
    end

    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if _G.EuivinMythicCache.keystone.level ~= level then
        _G.EuivinMythicCache.keystone.level = level
        updated = true
    end

    if updated then
        _G.EuivinMythic.callbacks:Fire("EUIVIN_MYTHIC_KEYSTONE")
    end
end

local function EuivinGetRewards()
    local updated = false

    -- Rewards
    C_MythicPlus.RequestRewards()

    local rewards = C_WeeklyRewards.GetActivities(1)
    if rewards == nil then
        _G.EuivinMythicCache.runs = 0
        _G.EuivinMythicCache.rewards = { 0, 0, 0 }
        _G.EuivinMythic.callbacks:Fire("EUIVIN_MYTHIC_REWARDS")
        return
    end

    for _, r in ipairs(rewards) do
        if r == nil then
            _G.EuivinMythicCache.runs = 0
            _G.EuivinMythicCache.rewards = { 0, 0, 0 }
            _G.EuivinMythic.callbacks:Fire("EUIVIN_MYTHIC_REWARDS")
            return
        end
    end

    for i, r in ipairs(rewards) do
        if r.threshold > r.progress then
            break
        end

        local difficultyID = C_WeeklyRewards.GetDifficultyIDForActivityTier(r.activityTierID)
        if difficultyID == 2 or difficultyID == 24 then
            if _G.EuivinMythicCache.rewards[i] ~= data.MythicRewards[1] then
                _G.EuivinMythicCache.rewards[i] = data.MythicRewards[1]
                updated = true
            end
        else
            if r.level > 10 then
                if _G.EuivinMythicCache.rewards[i] ~= data.MythicRewards[11] then
                    _G.EuivinMythicCache.rewards[i] = data.MythicRewards[11]
                    updated = true
                end
            elseif r.level == 0 then
                if _G.EuivinMythicCache.rewards[i] ~= data.MythicRewards[2] then
                    _G.EuivinMythicCache.rewards[i] = data.MythicRewards[2]
                    updated = true
                end
            else
                if _G.EuivinMythicCache.rewards[i] ~= data.MythicRewards[r.level + 1] then
                    _G.EuivinMythicCache.rewards[i] = data.MythicRewards[r.level + 1]
                    updated = true
                end
            end
        end
    end

    -- Runs
    C_MythicPlus.RequestMapInfo()

    local runs = 0
    local history = C_MythicPlus.GetRunHistory(false, true)
    for _, r in ipairs(history) do
        if r.level >= 10 then -- Replace `10' wioth a predefined constant.
            runs = runs + 1
        end
        if runs >= 8 then
            break
        end
    end
    if _G.EuivinMythicCache.runs ~= runs then
        _G.EuivinMythicCache.runs = runs
        updated = true
    end

    if updated or not _G.EuivinMythicCache.init then
        _G.EuivinMythicCache.init = true
        _G.EuivinMythic.callbacks:Fire("EUIVIN_MYTHIC_REWARDS")
    end
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hiddenFrame:RegisterEvent("BAG_UPDATE_DELAYED")
hiddenFrame:RegisterEvent("ITEM_CHANGED")
hiddenFrame:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
hiddenFrame:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
hiddenFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
hiddenFrame:SetScript(
    "OnEvent",
    function(_, event)
        if event == "ADDON_LOADED" then
            EuivinInitMythic()
            return
        end
        if event == "BAG_UPDATE_DELAYED" or event == "ITEM_CHANGED" then
            EuivinGetKeystone()
            return
        end
        -- event == all others...
        EuivinGetRewards()
    end)

-- XXX: Is it better to move these to a separated XML file?
-- TODO: Localize strings
mythicFrame = util.CreateCategoryFrame("쐐기")
keystoneFrame = util.ProgressBar(mythicFrame, startColor, endColor)
rewardsFrame = util.ProgressBar(mythicFrame, startColor, endColor)
rewardsFrame:Show()
