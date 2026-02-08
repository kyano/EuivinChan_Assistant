local addonName = ...

-- Wow APIs
local C_Timer = C_Timer -- luacheck: globals C_Timer
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local FocusFrame = FocusFrame -- luacheck: globals FocusFrame
local TargetFrame = TargetFrame -- luacheck: globals TargetFrame
local UnitExists = UnitExists -- luacheck: globals UnitExists

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub
local LibRangeCheck = LibStub("LibRangeCheck-3.0")

-- Local/session variables
local outOfRangeColor = CreateColorFromHexString("ffff0004")
local under40Color = CreateColorFromHexString("fff8ff00")
local under30Color = CreateColorFromHexString("ff00b1ff")
local under10Color = CreateColorFromHexString("ff00ff26")

-- `EuivinConfig' is from SavedVariables
-- luacheck: globals EuivinConfig

_G.Euivin.range = CreateFrame("Frame")
local addon = _G.Euivin.range

local function initRangeFrame(f, parent)
  f:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 22, -23)
  f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.text:SetPoint("LEFT")
  f.text:SetFontHeight(11)
end

addon.Init = function(self)
  if self.callbacks == nil then
    self.callbacks = LibStub("CallbackHandler-1.0"):New(self)
  end

  self.targetTimer = nil
  self.focusTimer = nil

  self.cbRangeUpdated = function(event)
    local target, frame
    if event == "EUIVIN_RANGE_UPDATED_TARGET" then
      target = "target"
      frame = self.targetRangeFrame
    else -- event == "EUIVIN_RANGE_UPDATED_FOCUS"
      target = "focus"
      frame = self.focusRangeFrame
    end

    local minRange, maxRange = LibRangeCheck:GetRange(target)
    if maxRange == nil then
      maxRange = 999
    end
    if minRange == nil then
      minRange = maxRange
    end

    if minRange > 40 or maxRange >= 999 then
      -- TODO: Localize strings
      frame.text:SetFormattedText("over %d yds", minRange)
    else
      frame.text:SetText(minRange .. " - " .. maxRange)
    end
    frame:SetSize(math.ceil(frame.text:GetWidth()), math.ceil(frame.text:GetFontHeight()))

    local r, g, b
    if maxRange <= 10 then
      r, g, b = under10Color:GetRGB()
    elseif maxRange <= 30 then
      r, g, b = under30Color:GetRGB()
    elseif maxRange <= 40 then
      r, g, b = under40Color:GetRGB()
    else
      r, g, b = outOfRangeColor:GetRGB()
    end
    frame.text:SetTextColor(r, g, b)
  end

  local events = {
    "EUIVIN_RANGE_UPDATED_TARGET",
    "EUIVIN_RANGE_UPDATED_FOCUS",
  }
  for _, e in ipairs(events) do
    self:RegisterCallback(e, self.cbRangeUpdated, e)
  end
end

addon.UpdateRange = function(self, event)
  local target, timer, targetEvent
  if event == "PLAYER_TARGET_CHANGED" then
    target = "target"
    targetEvent = "EUIVIN_RANGE_UPDATED_TARGET"
  else -- event == "PLAYER_FOCUS_CHANGED"
    target = "focus"
    targetEvent = "EUIVIN_RANGE_UPDATED_FOCUS"
  end
  timer = target .. "Timer"

  if self[timer] ~= nil then
    self[timer]:Cancel()
    self[timer] = nil
  end

  if not UnitExists(target) or not EuivinConfig.Range then
    return
  end

  self.callbacks:Fire(targetEvent)
  self[timer] = C_Timer.NewTicker(
    0.5,
    function(tickerSelf)
      if not UnitExists(target) or not EuivinConfig.Range then
        tickerSelf:Cancel()
        return
      end
      self.callbacks:Fire(targetEvent)
  end)
end

addon.Start = function(self)
  if EuivinConfig.Range then
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")

    if self.targetRangeFrame ~= nil then
      self.targetRangeFrame:Show()
    else
      self.targetRangeFrame = CreateFrame("Frame", nil, TargetFrame)
      initRangeFrame(self.targetRangeFrame, TargetFrame)
    end
    if self.focusRangeFrame ~= nil then
      self.focusRangeFrame:Show()
    else
      self.focusRangeFrame = CreateFrame("Frame", nil, FocusFrame)
      initRangeFrame(self.focusRangeFrame, FocusFrame)
    end
  end
end

addon.Stop = function(self)
  self.targetRangeFrame:Hide()
  self.focusRangeFrame:Hide()

  self:UnregisterEvent("PLAYER_TARGET_CHANGED")
  self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
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
    -- event == PLAYER_TARGET_CHANGED or event == PLAYER_FOCUS_CHANGED
    self:UpdateRange(event)
end)
