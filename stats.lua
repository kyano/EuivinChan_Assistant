-- Local shortcuts for global functions
local _G = _G
local floor = math.floor
local ipairs = ipairs
local max = math.max
local min = math.min
local next = next
local select = select

-- Wow APIs
local CR_VERSATILITY_DAMAGE_DONE = CR_VERSATILITY_DAMAGE_DONE -- luacheck: globals CR_VERSATILITY_DAMAGE_DONE
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local GetCombatRatingBonus = GetCombatRatingBonus -- luacheck: globals GetCombatRatingBonus
local GetCritChance = GetCritChance -- luacheck: globals GetCritChance
local GetHaste = GetHaste -- luacheck: globals GetHaste
local GetMasteryEffect = GetMasteryEffect -- luacheck: globals GetMasteryEffect
local GetSpecialization = GetSpecialization -- luacheck: globals GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo -- luacheck: globals GetSpecializationInfo
local PlayerFrame = PlayerFrame -- luacheck: globals PlayerFrame
local UnitStat = UnitStat -- luacheck: globals UnitStat

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

-- Local/session variables
-- TODO: Localize strings
local statAttrName = {
    -- Strength, Agility, Stamina, Intellect
    [1] = "힘",
    [2] = "민첩",
    [3] = "체력",
    [4] = "지능",
    ["crit"] = "치명",
    ["haste"] = "가속",
    ["mastery"] = "특화",
    ["versatility"] = "유연",
}
local mainStatFrame, critFrame, hasteFrame, masteryFrame, versatilityFrame
local mainStatBarColor = CreateColorFromHexString("ff999999")
local critBarColor = CreateColorFromHexString("ffea4b4b")
local hasteBarColor = CreateColorFromHexString("ff43e023")
local masteryBarColor = CreateColorFromHexString("ffb622c6")
local versatilityBarColor = CreateColorFromHexString("ff23abe0")

local function updateStatBar(f, label, value, maxValue)
    f.label:SetText(statAttrName[label])

    local valueText
    local percentageSuffix = {
        ["crit"] = true,
        ["haste"] = true,
        ["mastery"] = true,
        ["versatility"] = true,
    }
    if percentageSuffix[label] then
        value = _G.EuivinStatCache[label]
        valueText = value .. "%"
    else
        valueText = value
    end
    f.value:SetText(valueText)

    local width
    if maxValue == nil then
        maxValue = 100
    end
    width = min(80, floor((value / maxValue) * 80))
    if width == 0 then
        f.bar:Hide()
    else
        f.bar:Show()
        f.bar:SetWidth(width)
    end
end

local function EuivinInitStats()
    if _G.EuivinStatCache == nil or next(_G.EuivinStatCache) == nil then
        -- XXX: Wrong indentation by `lua-ts-mode`
        _G.EuivinStatCache = {
            ["mainStat"] = {
                               ["attr"] = 0,
                               ["stat"] = 0,
                               ["max"] = 0,
            },
            ["crit"] = 0,
            ["haste"] = 0,
            ["mastery"] = 0,
            ["versatility"] = 0,
        }
    end

    if _G.EuivinStat == nil then
        _G.EuivinStat = {}
    end
    if _G.EuivinStat.callbacks == nil then
        _G.EuivinStat.callbacks = LibStub("CallbackHandler-1.0"):New(_G.EuivinStat)
    end

    _G.EuivinStat:RegisterCallback(
        "EUIVIN_STAT_UPDATED",
        function()
            local stats = {
                {
                    ["frame"] = mainStatFrame,
                    ["label"] = _G.EuivinStatCache.mainStat.attr,
                    ["value"] = _G.EuivinStatCache.mainStat.stat,
                    ["maxValue"] = _G.EuivinStatCache.mainStat.max,
                },
                {
                    ["frame"] = critFrame,
                    ["label"] = "crit",
                },
                {
                    ["frame"] = hasteFrame,
                    ["label"] = "haste",
                },
                {
                    ["frame"] = masteryFrame,
                    ["label"] = "mastery",
                },
                {
                    ["frame"] = versatilityFrame,
                    ["label"] = "versatility",
                },
            }
            for _, s in ipairs(stats) do
                updateStatBar(s.frame, s.label, s.value, s.maxValue)
            end
        end)
end

local function EuivinUpdateStats(event, ...)
    local unitID
    if event == "PLAYER_ENTERING_WORLD" then
        unitID = "player"
    else -- event == "UNIT_STATS" or event == "UNIT_AURA"
        unitID = ...
    end
    if unitID ~= "player" then
        return
    end

    local updated = false
    if event == "PLAYER_ENTERING_WORLD" then
        local mainStatType = select(6, GetSpecializationInfo(GetSpecialization()))
        if _G.EuivinStatCache.mainStat.attr ~= mainStatType then
            _G.EuivinStatCache.mainStat.attr = mainStatType
            updated = true
        end
    end

    -- Stat value of the basic attribute
    local _, mainStat, buffedStat, debuffedStat = UnitStat(unitID, _G.EuivinStatCache.mainStat.attr)
    local maxStat = (mainStat - buffedStat + debuffedStat) * 10 -- Replace `10` with a predefined constant.
    if _G.EuivinStatCache.mainStat.max ~= maxStat or _G.EuivinStatCache.mainStat.stat ~= mainStat then
        _G.EuivinStatCache.mainStat.max = maxStat
        _G.EuivinStatCache.mainStat.stat = mainStat
        updated = true
    end

    -- Critical hit chance
    local crit = floor(GetCritChance() * 100) / 100
    if _G.EuivinStatCache.crit ~= crit then
        _G.EuivinStatCache.crit = crit
        updated = true
    end

    -- Haste percentage
    local haste = floor(GetHaste() * 100) / 100
    if _G.EuivinStatCache.haste ~= haste then
        _G.EuivinStatCache.haste = haste
        updated = true
    end

    -- Effective mastery percentage
    local mastery = floor(GetMasteryEffect() * 100) / 100
    if _G.EuivinStatCache.mastery ~= mastery then
        _G.EuivinStatCache.mastery = mastery
        updated = true
    end

    -- Versatility bonus percentage
    local versatility = floor((GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)) * 100) / 100
    if _G.EuivinStatCache.versatility ~= versatility then
        _G.EuivinStatCache.versatility = versatility
        updated = true
    end

    if updated then
        _G.EuivinStat.callbacks:Fire("EUIVIN_STAT_UPDATED")
    end
end

local function initStatFrame(f, parent, idx, color)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0 - idx * 13)
    f:SetSize(80, 13)

    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.label:SetPoint("LEFT")
    f.label:SetFontHeight(10)
    f.label:SetTextColor(1, 1, 1)

    f.value = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.value:SetPoint("RIGHT")
    f.value:SetFontHeight(10)
    f.value:SetTextColor(1, 1, 1)

    f.bar = f:CreateTexture(nil, "BACKGROUND")
    f.bar:SetPoint("RIGHT")
    f.bar:SetSize(40, 13)
    f.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Clean"))
    f.bar:SetGradient("HORIZONTAL", color, color)
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hiddenFrame:RegisterEvent("UNIT_STATS")
hiddenFrame:RegisterEvent("UNIT_AURA")
hiddenFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            EuivinInitStats()
            return
        end
        EuivinUpdateStats(event, ...)
    end)

-- XXX: Is it better to move these to a separated XML file?
local statFrame = CreateFrame("Frame", nil, PlayerFrame)
statFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 12, -5)
statFrame:SetSize(80, 65)
statFrame:SetFrameStrata("BACKGROUND")
statFrame:SetAlpha(0.65)

mainStatFrame = CreateFrame("Frame", nil, statFrame)
critFrame = CreateFrame("Frame", nil, statFrame)
hasteFrame = CreateFrame("Frame", nil, statFrame)
masteryFrame = CreateFrame("Frame", nil, statFrame)
versatilityFrame = CreateFrame("Frame", nil, statFrame)

local frames = {
    {
        ["frame"] = mainStatFrame,
        ["color"] = mainStatBarColor,
    },
    {
        ["frame"] = critFrame,
        ["color"] = critBarColor,
    },
    {
        ["frame"] = hasteFrame,
        ["color"] = hasteBarColor,
    },
    {
        ["frame"] = masteryFrame,
        ["color"] = masteryBarColor,
    },
    {
        ["frame"] = versatilityFrame,
        ["color"] = versatilityBarColor,
    },
}
for i, f in ipairs(frames) do
    initStatFrame(f.frame, statFrame, i - 1, f.color)
end
