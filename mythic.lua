local addonName, ns = ...

-- Wow APIs
local C_ChallengeMode = C_ChallengeMode -- luacheck: globals C_ChallengeMode
local C_MythicPlus = C_MythicPlus -- luacheck: globals C_MythicPlus
local C_WeeklyRewards = C_WeeklyRewards -- luacheck: globals C_WeeklyRewards
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local strlenutf8 = strlenutf8 -- luacheck: globals strlenutf8

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- Local/session variables
local data = ns.data
local util = ns.util
local mythicFrame, keystoneFrame, rewardsFrame
local startColor = CreateColorFromHexString("ff00ff16")
local endColor = CreateColorFromHexString("ff7bacff")

local function EuivinMythicHandler(event)
    local cache = _G.Euivin.mythic.cache

    if event == "EUIVIN_MYTHIC_KEYSTONE" then
        local name = cache.keystone.name
        local level = cache.keystone.level
        if name == "" or level == 0 then
            keystoneFrame:Hide()
            rewardsFrame:SetPointsOffset(0, -15)
        else
            keystoneFrame.label:SetText(name)
            keystoneFrame.value:SetText("+" .. level)

            local width
            width = math.floor((math.min(level, 18) / 18) * 176)
            keystoneFrame.bar:SetWidth(width)

            keystoneFrame:Show()
            rewardsFrame:SetPointsOffset(0, -30)
        end
        util.ExpandFrame(mythicFrame)
        return
    end

    -- event == "EUIVIN_MYTHIC_REWARDS"
    local runs = cache.runs
    -- TODO: Localize strings
    rewardsFrame.label:SetFormattedText("주차 [%d/8]", runs)

    local width = math.floor((runs / 8) * 176)
    if width == 0 then
        rewardsFrame.bar:Hide()
    else
        rewardsFrame.bar:Show()
        rewardsFrame.bar:SetWidth(width)
    end

    local rewardsText = ""
    if C_WeeklyRewards.CanClaimRewards() then
        rewardsFrame.value:SetText(rewardsText)
    end
    for i, ilvl in ipairs(cache.rewards) do
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
    if _G.Euivin.mythic == nil then
        _G.Euivin.mythic = {}
    end
    local addon = _G.Euivin.mythic

    if addon.cache == nil or next(addon.cache) == nil then
        -- XXX: Wrong indentation by `lua-ts-mode`
        addon.cache = {
            ["keystone"] = {
                               ["name"] = "",
                               ["level"] = 0,
            },
            ["rewards" ] = { 0, 0, 0 },
            ["runs"] = 0,
            ["init"] = false,
        }
    end

    if addon.callbacks == nil then
        addon.callbacks = LibStub("CallbackHandler-1.0"):New(addon)
    end

    local events = {
        "EUIVIN_MYTHIC_KEYSTONE",
        "EUIVIN_MYTHIC_REWARDS",
    }
    for _, e in ipairs(events) do
        addon:RegisterCallback(e, EuivinMythicHandler, e)
    end
end

local function EuivinGetKeystone(mapID, level)
    local addon = _G.Euivin.mythic
    local cache = addon.cache

    local updated = false

    -- When the keystone is not found
    if mapID == nil then
        mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    end
    if mapID == nil then
        cache.keystone = { ["name"] = "", ["level"] = 0 }
        addon.callbacks:Fire("EUIVIN_MYTHIC_KEYSTONE")
        return
    end

    local name
    local dungeonName = C_ChallengeMode.GetMapUIInfo(mapID)
    if strlenutf8(dungeonName) > 10 then
        name = util.WA_Utf8Sub(dungeonName, 10) .. "..."
    else
        name = dungeonName
    end
    if cache.keystone.name ~= name then
        cache.keystone.name = name
        updated = true
    end

    if level == nil then
        level = C_MythicPlus.GetOwnedKeystoneLevel()
    end
    if cache.keystone.level ~= level then
        cache.keystone.level = level
        updated = true
    end

    if updated then
        addon.callbacks:Fire("EUIVIN_MYTHIC_KEYSTONE")
    end
end

local function EuivinGetMythicRewards()
    local addon = _G.Euivin.mythic
    local cache = addon.cache

    local updated = false

    -- Rewards
    C_MythicPlus.RequestRewards()

    local rewards = C_WeeklyRewards.GetActivities(1)
    if rewards == nil then
        cache.runs = 0
        cache.rewards = { 0, 0, 0 }
        addon.callbacks:Fire("EUIVIN_MYTHIC_REWARDS")
        return
    end

    for _, r in ipairs(rewards) do
        if r == nil then
            cache.runs = 0
            cache.rewards = { 0, 0, 0 }
            addon.callbacks:Fire("EUIVIN_MYTHIC_REWARDS")
            return
        end
    end

    for i, r in ipairs(rewards) do
        if r.threshold > r.progress then
            break
        end

        local difficultyID = C_WeeklyRewards.GetDifficultyIDForActivityTier(r.activityTierID)
        if difficultyID == 2 or difficultyID == 24 then
            if cache.rewards[i] ~= data.MythicRewards[1] then
                cache.rewards[i] = data.MythicRewards[1]
                updated = true
            end
        else
            if r.level > 10 then
                if cache.rewards[i] ~= data.MythicRewards[11] then
                    cache.rewards[i] = data.MythicRewards[11]
                    updated = true
                end
            elseif r.level == 0 then
                if cache.rewards[i] ~= data.MythicRewards[2] then
                    cache.rewards[i] = data.MythicRewards[2]
                    updated = true
                end
            else
                if cache.rewards[i] ~= data.MythicRewards[r.level + 1] then
                    cache.rewards[i] = data.MythicRewards[r.level + 1]
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
        if r.level >= 10 then -- Replace `10' with a predefined constant.
            runs = runs + 1
        end
        if runs >= 8 then
            break
        end
    end
    if cache.runs ~= runs then
        cache.runs = runs
        updated = true
    end

    if updated or not cache.init then
        cache.init = true
        addon.callbacks:Fire("EUIVIN_MYTHIC_REWARDS")
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
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == addonName then
                EuivinInitMythic()
            end
            return
        end
        if event == "BAG_UPDATE_DELAYED" then
            EuivinGetKeystone()
            return
        elseif event == "ITEM_CHANGED" then
            local _, newHyperlink = ...
            local challengeMapID, level = util.ParseKeystoneItemLink(newHyperlink)
            EuivinGetKeystone(challengeMapID, level)
            return
        end
        -- event == all others...
        EuivinGetMythicRewards()
    end)

-- XXX: Is it better to move these to a separated XML file?
-- TODO: Localize strings
mythicFrame = util.CreateCategoryFrame("쐐기", "EuivinMythicFrame")
keystoneFrame = util.ProgressBar(mythicFrame, startColor, endColor)
rewardsFrame = util.ProgressBar(mythicFrame, startColor, endColor)
rewardsFrame:Show()
