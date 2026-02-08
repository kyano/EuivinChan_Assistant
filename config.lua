local addonName, ns = ...

-- Wow APIs
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local MinimalSliderWithSteppersMixin = MinimalSliderWithSteppersMixin -- luacheck: globals MinimalSliderWithSteppersMixin, no max line length
local Settings = Settings -- luacheck: globals Settings

-- Local/session variables
local util = ns.util

-- `EuivinConfig' is from SavedVariables
-- luacheck: globals EuivinConfig

local function EuivinInitConfig()
  if EuivinConfig == nil then
    EuivinConfig = {}
  end
  if EuivinConfig.UIScale == nil or next(EuivinConfig.UIScale) == nil then
    EuivinConfig.UIScale = {
      ["enable"] = false,
      ["factor"] = 0.5,
    }
  end
  if EuivinConfig.Stats == nil then
    EuivinConfig.Stats = false
  end
  if EuivinConfig.Range == nil then
    EuivinConfig.Range = false
  end
  if EuivinConfig.Mythic == nil or next(EuivinConfig.Mythic) == nil then
    EuivinConfig.Mythic = {
      ["enable"] = true,
      ["goal"] = 10,
    }
  end
  if EuivinConfig.Delve == nil then
    EuivinConfig.Delve = true
  end
  if EuivinConfig.Crests == nil then
    EuivinConfig.Crests = true
  end
  if EuivinConfig.Profession == nil then
    EuivinConfig.Profession = true
  end

  local category, layout = Settings.RegisterVerticalLayoutCategory("EuivinChan Assistant")

  local mythicCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_MYTHIC_ENABLED",
    "enable",
    EuivinConfig.Mythic,
    Settings.VarType.Boolean,
    "Enable Mythic+ tracker",
    true
  )
  Settings.CreateCheckbox(
    category,
    mythicCheckboxSetting,
    "Toggle whether to show the Mythic+ tracker."
  )

  local mythicSliderOption = Settings.CreateSliderOptions(2, 30, 1)
  local mythicSliderSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_MYTHIC_GOAL",
    "goal",
    EuivinConfig.Mythic,
    Settings.VarType.Number,
    "Mythic+ Keystone Goal Level",
    10
  )
  mythicSliderOption:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
  Settings.CreateSlider(
    category,
    mythicSliderSetting,
    mythicSliderOption,
    "The goal level of the Mythic+ keystone for the Great Vault."
  )

  local delveCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_DELVE_ENABLED",
    "Delve",
    EuivinConfig,
    Settings.VarType.Boolean,
    "Enable Delves tracker",
    true
  )
  Settings.CreateCheckbox(
    category,
    delveCheckboxSetting,
    "Toggle whether to show the Delves/World activities tracker."
  )

  local crestsCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_CRESTS_ENABLED",
    "Crests",
    EuivinConfig,
    Settings.VarType.Boolean,
    "Enable Item Upgrade tracker",
    true
  )
  Settings.CreateCheckbox(
    category,
    crestsCheckboxSetting,
    "Toggle whether to show the currency tracker for the gear item level upgrade."
  )

  local professionCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_PROFESSION_ENABLED",
    "Profession",
    EuivinConfig,
    Settings.VarType.Boolean,
    "Enable Profession tracker",
    true
  )
  Settings.CreateCheckbox(
    category,
    professionCheckboxSetting,
    "Toggle whether to show the concentration and sparks tracker."
  )

  -- local nameplateTitleInitializer = ns.util.CreateSettingsListSectionHeaderInitializer("Nameplates")
  -- layout:AddInitializer(nameplateTitleInitializer);

  local extraTitleInitializer = ns.util.CreateSettingsListSectionHeaderInitializer("Extra modules")
  layout:AddInitializer(extraTitleInitializer);

  local uiScaleCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_UISCALE_ENABLED",
    "enable",
    EuivinConfig.UIScale,
    Settings.VarType.Boolean,
    "Enable UI Scale",
    false
  )
  local uiScaleSliderOption = Settings.CreateSliderOptions(35, 64, 1)
  local uiScaleSliderSetting = Settings.RegisterProxySetting(
    category,
    "EUIVIN_UISCALE_FACTOR",
    Settings.VarType.Number,
    "UI Scale factor",
    64,
    function()
      return EuivinConfig.UIScale.factor * 100
    end,
    function(value)
      EuivinConfig.UIScale.factor = value / 100
    end
  )
  uiScaleSliderSetting:SetCommitFlags(
    Settings.CommitFlag.KioskProtected,
    Settings.CommitFlag.Apply,
    Settings.CommitFlag.Revertable
  )
  uiScaleSliderSetting:SetValueChangedCallback(function()
      if _G.Euivin.uiscale ~= nil then
        _G.Euivin.uiscale:ApplyScaleFactor()
      end
  end)
  uiScaleSliderOption:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Right,
    function(value)
      return tostring(value) .. "%"
    end
  )
  local uiScaleInitializer = util.CreateSettingsCheckboxSliderInitializer(
    uiScaleCheckboxSetting,
    "UI Scale",
    "Enable UI Scaling." ..
    "\n\n|cffff0000" ..
    "You must reload the UI after changing this." ..
    "|r",
    uiScaleSliderSetting,
    uiScaleSliderOption,
    "UI Scale factor",
    "UI Scale factor in percentage."
  )
  layout:AddInitializer(uiScaleInitializer)

  local statsCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_STATS_ENABLED",
    "Stats",
    EuivinConfig,
    Settings.VarType.Boolean,
    "Stats graph",
    false
  )
  statsCheckboxSetting:SetValueChangedCallback(function(_, value)
      if _G.Euivin.stats ~= nil then
        if value then
          _G.Euivin.stats:Start()
          _G.Euivin.stats:UpdateStats("PLAYER_ENTERING_WORLD")
        else
          _G.Euivin.stats:Stop()
        end
      end
  end)
  Settings.CreateCheckbox(
    category,
    statsCheckboxSetting,
    "Display Stats graphs beneath the player's portrait."
  )

  local rangeCheckboxSetting = Settings.RegisterAddOnSetting(
    category,
    "EUIVIN_RANGE_ENABLED",
    "Range",
    EuivinConfig,
    Settings.VarType.Boolean,
    "Enable Range display",
    false
  )
  Settings.CreateCheckbox(
    category,
    rangeCheckboxSetting,
    "Toggle whether to show Ranges to the Target unit and the Focus unit." ..
    "\n\n|cffff0000" ..
    "You must reload the UI after changing this." ..
    "|r"
  )

  Settings.RegisterAddOnCategory(category)
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:SetScript(
  "OnEvent",
  function(_, _, loadedAddon)
    if loadedAddon == addonName then
      EuivinInitConfig()
      hiddenFrame:UnregisterEvent("ADDON_LOADED")
    end
end)
