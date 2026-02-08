local addonName = ...

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
local GetVersatilityBonus = GetVersatilityBonus -- luacheck: globals GetVersatilityBonus
local PlayerFrame = PlayerFrame -- luacheck: globals PlayerFrame
local UnitStat = UnitStat -- luacheck: globals UnitStat

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

-- Local/session variables
-- TODO: Localize strings
local statAttrName = {
  [1] = "Str.",
  [2] = "Agi.",
  [3] = "Sta.",
  [4] = "Int.",
  ["crit"] = "Crit.",
  ["haste"] = "Haste",
  ["mastery"] = "Mast.",
  ["versatility"] = "Vers.",
}
local mainStatBarColor = CreateColorFromHexString("ff999999")
local critBarColor = CreateColorFromHexString("ffea4b4b")
local hasteBarColor = CreateColorFromHexString("ff43e023")
local masteryBarColor = CreateColorFromHexString("ffb622c6")
local versatilityBarColor = CreateColorFromHexString("ff23abe0")

-- `EuivinConfig' is from SavedVariables
-- luacheck: globals EuivinConfig

_G.Euivin.stats = CreateFrame("Frame")
local addon = _G.Euivin.stats

addon.updateStatBar = function(self, f, label, value, maxValue)
  local cache = self.cache

  f.label:SetText(statAttrName[label])

  local valueText
  local percentageSuffix = {
    ["crit"] = true,
    ["haste"] = true,
    ["mastery"] = true,
    ["versatility"] = true,
  }
  if percentageSuffix[label] then
    value = cache[label]
    valueText = value .. "%"
  else
    valueText = value
  end
  f.value:SetText(valueText)

  local width
  if maxValue == nil then
    maxValue = 100
  end
  width = math.min(80, math.floor((value / maxValue) * 80))
  if width == 0 then
    f.bar:Hide()
  else
    f.bar:Show()
    f.bar:SetWidth(width)
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

addon.Init = function(self)
  if self.cache == nil or next(self.cache) == nil then
    self.cache = {
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
  local cache = self.cache

  if self.callbacks == nil then
    self.callbacks = LibStub("CallbackHandler-1.0"):New(self)
  end
  self.cbStatUpdated = function()
    local stats = {
      {
        ["frame"] = self.mainStatFrame,
        ["label"] = cache.mainStat.attr,
        ["value"] = cache.mainStat.stat,
        ["maxValue"] = cache.mainStat.max,
      },
      {
        ["frame"] = self.critFrame,
        ["label"] = "crit",
      },
      {
        ["frame"] = self.hasteFrame,
        ["label"] = "haste",
      },
      {
        ["frame"] = self.masteryFrame,
        ["label"] = "mastery",
      },
      {
        ["frame"] = self.versatilityFrame,
        ["label"] = "versatility",
      },
    }
    for _, s in ipairs(stats) do
      self:updateStatBar(s.frame, s.label, s.value, s.maxValue)
    end
  end
  self:RegisterCallback("EUIVIN_STAT_UPDATED", self.cbStatUpdated)
end

addon.UpdateStats = function(self, event, ...)
  local cache = self.cache

  local unitID
  if event == "PLAYER_ENTERING_WORLD" then
    unitID = "player"
  else -- event == "UNIT_STATS" or event == "UNIT_AURA" or event == "UNIT_DAMAGE" or event == "UNIT_RANGEDDAMAGE"
    unitID = ...
  end
  if unitID ~= "player" then
    return
  end

  local updated = false

  -- The name of main stat
  local mainStatType = select(6, GetSpecializationInfo(GetSpecialization()))
  if cache.mainStat.attr ~= mainStatType then
    cache.mainStat.attr = mainStatType
    updated = true
  end

  -- Stat value of the basic attribute
  local _, mainStat, buffedStat, debuffedStat = UnitStat(unitID, cache.mainStat.attr)
  local maxStat = (mainStat - buffedStat + debuffedStat) * 10 -- TODO: Replace `10` with a predefined constant.
  if cache.mainStat.max ~= maxStat or cache.mainStat.stat ~= mainStat then
    cache.mainStat.max = maxStat
    cache.mainStat.stat = mainStat
    updated = true
  end

  -- Critical hit chance
  local crit = math.floor(GetCritChance() * 100) / 100
  if cache.crit ~= crit then
    cache.crit = crit
    updated = true
  end

  -- Haste percentage
  local haste = math.floor(GetHaste() * 100) / 100
  if cache.haste ~= haste then
    cache.haste = haste
    updated = true
  end

  -- Effective mastery percentage
  local mastery = math.floor(GetMasteryEffect() * 100) / 100
  if cache.mastery ~= mastery then
    cache.mastery = mastery
    updated = true
  end

  -- Versatility bonus percentage
  local versatility = math.floor(
    (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) +
     GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)) * 100
  ) / 100
  if cache.versatility ~= versatility then
    cache.versatility = versatility
    updated = true
  end

  if updated then
    self.callbacks:Fire("EUIVIN_STAT_UPDATED")
  end
end

addon.Start = function(self)
  if EuivinConfig.Stats then
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_STATS")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_DAMAGE")
    self:RegisterEvent("UNIT_RANGEDDAMAGE")

    if self.topLevelFrame ~= nil then
      self.topLevelFrame:Show()
    else
      self.topLevelFrame = CreateFrame("Frame", nil, PlayerFrame)
      self.topLevelFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 12, -5)
      self.topLevelFrame:SetSize(80, 65)
      self.topLevelFrame:SetFrameStrata("BACKGROUND")
      self.topLevelFrame:SetAlpha(0.65)

      self.mainStatFrame = CreateFrame("Frame", nil, self.topLevelFrame)
      self.critFrame = CreateFrame("Frame", nil, self.topLevelFrame)
      self.hasteFrame = CreateFrame("Frame", nil, self.topLevelFrame)
      self.masteryFrame = CreateFrame("Frame", nil, self.topLevelFrame)
      self.versatilityFrame = CreateFrame("Frame", nil, self.topLevelFrame)

      local frames = {
        {
          ["frame"] = self.mainStatFrame,
          ["color"] = mainStatBarColor,
        },
        {
          ["frame"] = self.critFrame,
          ["color"] = critBarColor,
        },
        {
          ["frame"] = self.hasteFrame,
          ["color"] = hasteBarColor,
        },
        {
          ["frame"] = self.masteryFrame,
          ["color"] = masteryBarColor,
        },
        {
          ["frame"] = self.versatilityFrame,
          ["color"] = versatilityBarColor,
        },
      }
      for i, f in ipairs(frames) do
        initStatFrame(f.frame, self.topLevelFrame, i - 1, f.color)
      end
    end
  end
end

addon.Stop = function(self)
  self.topLevelFrame:Hide()

  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  self:UnregisterEvent("UNIT_STATS")
  self:UnregisterEvent("UNIT_AURA")
  self:UnregisterEvent("UNIT_DAMAGE")
  self:UnregisterEvent("UNIT_RANGEDDAMAGE")
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript(
  "OnEvent",
  function(self, event, ...)
    if event == "ADDON_LOADED" then
      local loadedAddon = ...
      if loadedAddon == addonName then
        self:Init()
        self:Start()
        self:UnregisterEvent("ADDON_LOADED")
      end
      return
    end
    -- event == all others
    self:UpdateStats(event, ...)
end)
