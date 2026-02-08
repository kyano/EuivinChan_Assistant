local addonName = ...

-- Wow APIs
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local UIParent = UIParent -- luacheck: globals UIParent

-- `EuivinConfig' is from SavedVariables
-- luacheck: globals EuivinConfig

_G.Euivin.uiscale = CreateFrame("Frame")
local addon = _G.Euivin.uiscale

addon.Start = function(self)
  if EuivinConfig.UIScale.enable then
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UI_SCALE_CHANGED")
    self:RegisterEvent("GX_RESTARTED")
  end
end

addon.Stop = function(self)
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  self:UnregisterEvent("UI_SCALE_CHANGED")
  self:UnregisterEvent("GX_RESTARTED")
end

addon.ApplyScaleFactor = function(self)
  if not EuivinConfig.UIScale.enable then
    self:Stop()
    return
  end

  UIParent:SetScale(EuivinConfig.UIScale.factor)
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript(
  "OnEvent",
  function(self, event, ...)
    if event == "ADDON_LOADED" then
      local loadedAddon = ...
      if loadedAddon == addonName then
        self:Start()
        self:UnregisterEvent("ADDON_LOADED")
      end
      return
    end
    -- event == all others
    self:ApplyScaleFactor()
end)
