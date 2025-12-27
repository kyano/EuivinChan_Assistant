-- Local shortcuts for global functions
local floor = math.floor
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
LibSharedMedia:Register("statusbar", "Clean", "Interface\\AddOns\\Euivin_Assistant\\Textures\\Statusbar_Clean.blp")

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

local function EuivinInitStats()
    if _G.EuivinStatCache == nil or next(_G.EuivinStatCache) == nil then
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

    -- XXX: Wrong indentation by `lua-ts-mode`
    _G.EuivinStat.RegisterCallback(
    _G.EuivinStat, "EUIVIN_STAT_UPDATED",
    function()
        mainStatFrame.label:SetText(statAttrName[_G.EuivinStatCache.mainStat.attr])
        mainStatFrame.value:SetText(_G.EuivinStatCache.mainStat.stat)
        mainStatFrame.bar:SetWidth(
            min(80,
                max(0,
                    floor((_G.EuivinStatCache.mainStat.stat / _G.EuivinStatCache.mainStat.max) * 80))))

        critFrame.label:SetText(statAttrName["crit"])
        critFrame.value:SetText(_G.EuivinStatCache.crit .. "%")
        critFrame.bar:SetWidth(
            min(80,
                max(0,
                    floor((_G.EuivinStatCache.crit / 100) * 80))))

        hasteFrame.label:SetText(statAttrName["haste"])
        hasteFrame.value:SetText(_G.EuivinStatCache.haste .. "%")
        hasteFrame.bar:SetWidth(
            min(80,
                max(0,
                    floor((_G.EuivinStatCache.haste / 100) * 80))))

        masteryFrame.label:SetText(statAttrName["mastery"])
        masteryFrame.value:SetText(_G.EuivinStatCache.mastery .. "%")
        masteryFrame.bar:SetWidth(
            min(80,
                max(0,
                    floor((_G.EuivinStatCache.mastery / 100) * 80))))

        versatilityFrame.label:SetText(statAttrName["versatility"])
        versatilityFrame.value:SetText(_G.EuivinStatCache.versatility .. "%")
        versatilityFrame.bar:SetWidth(
            min(80,
                max(0,
                    floor((_G.EuivinStatCache.versatility / 100) * 80))))
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
statFrame:SetAlpha(0.5)
mainStatFrame = CreateFrame("Frame", nil, statFrame)
mainStatFrame:SetPoint("TOPLEFT", statFrame, "TOPLEFT", 0, 0)
mainStatFrame:SetSize(80, 13)
mainStatFrame.label = mainStatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainStatFrame.label:SetPoint("LEFT")
mainStatFrame.label:SetFontHeight(10)
mainStatFrame.label:SetTextColor(1, 1, 1)
mainStatFrame.value = mainStatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainStatFrame.value:SetPoint("RIGHT")
mainStatFrame.value:SetFontHeight(10)
mainStatFrame.value:SetTextColor(1, 1, 1)
mainStatFrame.bar = mainStatFrame:CreateTexture(nil, "BACKGROUND")
mainStatFrame.bar:SetPoint("RIGHT")
mainStatFrame.bar:SetSize(40, 13)
mainStatFrame.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Clean"))
mainStatFrame.bar:SetGradient("HORIZONTAL", mainStatBarColor, mainStatBarColor)
critFrame = CreateFrame("Frame", nil, statFrame)
critFrame:SetPoint("TOPLEFT", statFrame, "TOPLEFT", 0, -13)
critFrame:SetSize(80, 13)
critFrame.label = critFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
critFrame.label:SetPoint("LEFT")
critFrame.label:SetFontHeight(10)
critFrame.label:SetTextColor(1, 1, 1)
critFrame.value = critFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
critFrame.value:SetPoint("RIGHT")
critFrame.value:SetFontHeight(10)
critFrame.value:SetTextColor(1, 1, 1)
critFrame.bar = critFrame:CreateTexture(nil, "BACKGROUND")
critFrame.bar:SetPoint("RIGHT")
critFrame.bar:SetSize(40, 13)
critFrame.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Clean"))
critFrame.bar:SetGradient("HORIZONTAL", critBarColor, critBarColor)
hasteFrame = CreateFrame("Frame", nil, statFrame)
hasteFrame:SetPoint("TOPLEFT", statFrame, "TOPLEFT", 0, -26)
hasteFrame:SetSize(80, 13)
hasteFrame.label = hasteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hasteFrame.label:SetPoint("LEFT")
hasteFrame.label:SetFontHeight(10)
hasteFrame.label:SetTextColor(1, 1, 1)
hasteFrame.value = hasteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hasteFrame.value:SetPoint("RIGHT")
hasteFrame.value:SetFontHeight(10)
hasteFrame.value:SetTextColor(1, 1, 1)
hasteFrame.bar = hasteFrame:CreateTexture(nil, "BACKGROUND")
hasteFrame.bar:SetPoint("RIGHT")
hasteFrame.bar:SetSize(40, 13)
hasteFrame.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Clean"))
hasteFrame.bar:SetGradient("HORIZONTAL", hasteBarColor, hasteBarColor)
masteryFrame = CreateFrame("Frame", nil, statFrame)
masteryFrame:SetPoint("TOPLEFT", statFrame, "TOPLEFT", 0, -39)
masteryFrame:SetSize(80, 13)
masteryFrame.label = masteryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
masteryFrame.label:SetPoint("LEFT")
masteryFrame.label:SetFontHeight(10)
masteryFrame.label:SetTextColor(1, 1, 1)
masteryFrame.value = masteryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
masteryFrame.value:SetPoint("RIGHT")
masteryFrame.value:SetFontHeight(10)
masteryFrame.value:SetTextColor(1, 1, 1)
masteryFrame.bar = masteryFrame:CreateTexture(nil, "BACKGROUND")
masteryFrame.bar:SetPoint("RIGHT")
masteryFrame.bar:SetSize(40, 13)
masteryFrame.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Clean"))
masteryFrame.bar:SetGradient("HORIZONTAL", masteryBarColor, masteryBarColor)
versatilityFrame = CreateFrame("Frame", nil, statFrame)
versatilityFrame:SetPoint("TOPLEFT", statFrame, "TOPLEFT", 0, -52)
versatilityFrame:SetSize(80, 13)
versatilityFrame.label = versatilityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
versatilityFrame.label:SetPoint("LEFT")
versatilityFrame.label:SetFontHeight(10)
versatilityFrame.label:SetTextColor(1, 1, 1)
versatilityFrame.value = versatilityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
versatilityFrame.value:SetPoint("RIGHT")
versatilityFrame.value:SetFontHeight(10)
versatilityFrame.value:SetTextColor(1, 1, 1)
versatilityFrame.bar = versatilityFrame:CreateTexture(nil, "BACKGROUND")
versatilityFrame.bar:SetPoint("RIGHT")
versatilityFrame.bar:SetSize(40, 13)
versatilityFrame.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Clean"))
versatilityFrame.bar:SetGradient("HORIZONTAL", versatilityBarColor, versatilityBarColor)
