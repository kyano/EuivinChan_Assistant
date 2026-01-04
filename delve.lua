local addonName, ns = ...

-- Wow APIs
local C_MythicPlus = C_MythicPlus -- luacheck: globals C_MythicPlus
local C_WeeklyRewards = C_WeeklyRewards -- luacheck: globals C_WeeklyRewards
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- Local/session variables
local data = ns.data
local util = ns.util
local rewardsFrame
local startColor = CreateColorFromHexString("ff5433ff")
local endColor = CreateColorFromHexString("ffb3a7ff")

local function EuivinDelveHandler()
    local cache = _G.Euivin.delve.cache

    local runs = cache.runs
    rewardsFrame.label:SetFormattedText("보상 [%d/3]", runs)

    local width
    width = math.floor((runs / 3) * 176)
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

local function EuivinInitDelve()
    if _G.Euivin.delve == nil then
        _G.Euivin.delve = {}
    end
    local addon = _G.Euivin.delve

    if addon.cache == nil or next(addon.cache) == nil then
        addon.cache = {
            ["rewards"] = { 0, 0, 0 },
            ["runs"] = 0,
            ["init"] = false,
        }
    end

    if addon.callbacks == nil then
        addon.callbacks = LibStub("CallbackHandler-1.0"):New(addon)
    end

    addon:RegisterCallback("EUIVIN_DELVE_REWARDS", EuivinDelveHandler)
end

local function EuivinGetDelveRewards()
    local addon = _G.Euivin.delve
    local cache = addon.cache

    local updated = false

    C_MythicPlus.RequestRewards()

    local rewards = C_WeeklyRewards.GetActivities(6)
    if rewards == nil then
        cache.rewards = { 0, 0, 0 }
        addon.callbacks:Fire("EUIVIN_DELVE_REWARDS")
        return
    end

    for i, r in ipairs(rewards) do
        if r.threshold > r.progress then
            break
        end

        if r.level > 8 then
            if cache.rewards[i] ~= data.DelveRewards[8] then
                cache.rewards[i] = data.DelveRewards[8]
                updated = true
            end
        else
            if cache.rewards[i] ~= data.DelveRewards[r.level] then
                cache.rewards[i] = data.DelveRewards[r.level]
                updated = true
            end
        end
    end

    local runs = 0
    for _, r in ipairs(cache.rewards) do
        if r == data.DelveRewards[#data.DelveRewards] then
            runs = runs + 1
        end
    end
    if cache.runs ~= runs then
        cache.runs = runs
        updated = true
    end

    if updated or not cache.init then
        cache.init = true
        addon.callbacks:Fire("EUIVIN_DELVE_REWARDS")
    end
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hiddenFrame:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
hiddenFrame:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
hiddenFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
hiddenFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == addonName then
                EuivinInitDelve()
            end
            return
        end
        -- event == all others...
        EuivinGetDelveRewards()
    end)

-- XXX: Is it better to move these to a separated XML file?
-- TODO: Localize strings
local delveFrame = util.CreateCategoryFrame("구렁", "EuivinDelveFrame", "EuivinMythicFrame")
rewardsFrame = util.ProgressBar(delveFrame, startColor, endColor)
rewardsFrame:Show()
util.ExpandFrame(delveFrame)
