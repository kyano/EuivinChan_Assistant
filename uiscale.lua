local addonName = ...

-- Wow APIs
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local UIParent = UIParent -- luacheck: globals UIParent

-- `EuivinConfig' is from SavedVariables
-- luacheck: globals EuivinConfig

_G.Euivin.uiscale = CreateFrame("Frame")

_G.Euivin.uiscale.Start = function(self)
  if EuivinConfig.UIScale.enable then
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UI_SCALE_CHANGED")
    self:RegisterEvent("GX_RESTARTED")
  end
end

_G.Euivin.uiscale.Stop = function(self)
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  self:UnregisterEvent("UI_SCALE_CHANGED")
  self:UnregisterEvent("GX_RESTARTED")
end

_G.Euivin.uiscale.ApplyScaleFactor = function(self)
  if not EuivinConfig.UIScale.enable then
    self:Stop()
    return
  end

  UIParent:SetScale(EuivinConfig.UIScale.factor)
end

_G.Euivin.uiscale:RegisterEvent("ADDON_LOADED")
_G.Euivin.uiscale:SetScript(
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
