local addonName = ...

-- Wow APIs
local C_CVar = C_CVar -- luacheck: globals C_CVar
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- `EuivinConfig' is from SavedVariables
-- luacheck: globals EuivinConfig

_G.Euivin.cvar = CreateFrame("Frame")
local addon = _G.Euivin.cvar

addon.Init = function(self)
  if self.callbacks == nil then
    self.callbacks = LibStub("CallbackHandler-1.0"):New(self)
  end

  -- Only `EUIVIN_CVAR_CHANGED' is assigned
  self.cbCVarChanged = function(_, c_var, value)
    local success = C_CVar.SetCVar(c_var, value)
    if not success then
      print(
        "|cff3fc7eb" ..
        "EuivinChan" ..
        "|r: " ..
        "Failed to set CVar: " ..
        c_var
      )
    end
  end

  self:RegisterCallback("EUIVIN_CVAR_CHANGED", self.cbCVarChanged)
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript(
  "OnEvent",
  -- Only `ADDON_LOADED' is assigned
  function(self, _, ...)
    local loadedAddon = ...
    if loadedAddon == addonName then
      self:Init()
      self.callbacks:Fire(
        "EUIVIN_CVAR_CHANGED",
        "screenshotFormat",
        EuivinConfig.CVar.Screenshot.format
      )
      self.callbacks:Fire(
        "EUIVIN_CVAR_CHANGED",
        "screenshotQuality",
        EuivinConfig.CVar.Screenshot.quality
      )
      self.callbacks:Fire(
        "EUIVIN_CVAR_CHANGED",
        "xpBarText",
        EuivinConfig.CVar.xpbartext
      )
      self.callbacks:Fire(
        "EUIVIN_CVAR_CHANGED",
        "PreventOsIdleSleep",
        EuivinConfig.CVar.preventosidlesleep
      )
      self.callbacks:Fire(
        "EUIVIN_CVAR_CHANGED",
        "reflectionDownscale",
        EuivinConfig.CVar.reflectiondownscale
      )
      self:UnregisterEvent("ADDON_LOADED")
    end
end)
