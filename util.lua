local _, ns = ...

-- Wow APIs
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local Settings = Settings -- luacheck: globals Settings
local UIParent = UIParent -- luacheck: globals UIParent
local strsplittable = strsplittable -- luacheck: globals strsplittable

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

-- Local/session variables
local data = ns.data

if ns.util == nil then
  ns.util = {}
end

-- Borrowed from WeakAuras
-- WeakAuras is licensed under GPLv2
ns.util.WA_Utf8Sub = function(input, size)
  local output = ""
  input = tostring(input)
  if type(input) ~= "string" then
    return output
  end
  local i = 1
  while (size > 0) do
    local byte = input:byte(i)
    if not byte then
      return output
    end
    if byte < 128 then
      -- ASCII byte
      output = output .. input:sub(i, i)
      size = size - 1
    elseif byte < 192 then
      -- Continuation bytes
      output = output .. input:sub(i, i)
    elseif byte < 244 then
      -- Start bytes
      output = output .. input:sub(i, i)
      size = size - 1
    end
    i = i + 1
  end

  -- Add any bytes that are part of the sequence
  while (true) do
    local byte = input:byte(i)
    if byte and byte >= 128 and byte < 192 then
      output = output .. input:sub(i, i)
    else
      break
    end
    i = i + 1
  end

  return output
end

ns.util.CreateCategoryFrame = function(title, name, upper)
  if upper == nil then
    upper = UIParent
  end
  local relativePoint, offsetX, offsetY
  if upper ~= UIParent then
    relativePoint = "BOTTOMLEFT"
    offsetX = 0
    offsetY = -16
  else
    relativePoint = "TOPLEFT"
    offsetX = 3
    offsetY = -3
  end

  local f = CreateFrame("Frame", name, UIParent)
  f:SetPoint("TOPLEFT", upper, relativePoint, offsetX, offsetY)
  f:SetSize(176, 0)
  f:SetFrameStrata("BACKGROUND")

  local titleFrame = CreateFrame("Frame", nil, f)
  titleFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  titleFrame.text = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleFrame.text:SetPoint("LEFT")
  titleFrame.text:SetFontHeight(12)
  titleFrame.text:SetText(title)
  titleFrame:SetSize(math.ceil(titleFrame.text:GetWidth()), 14)

  return f
end

ns.util.ExpandFrame = function(f)
  local children = { f:GetChildren() }

  local shown = 0
  for _, child in ipairs(children) do
    if child:IsShown() then
      shown = shown + 1
    end
  end

  f:SetHeight((14 * shown) + (shown - 1))
end

ns.util.ProgressBar = function(parent, startColor, endColor)
  if endColor == nil then
    endColor = startColor
  end

  local f = CreateFrame("Frame", nil, parent)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -15)
  f:SetSize(176, 14)

  f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.label:SetPoint("LEFT")
  f.label:SetPointsOffset(3, 0)
  f.label:SetFontHeight(12)
  f.label:SetTextColor(1, 1, 1)

  f.value = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.value:SetPoint("RIGHT")
  f.value:SetPointsOffset(-3, 0)
  f.value:SetFontHeight(12)
  f.value:SetTextColor(1, 1, 1)

  local background = f:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetSize(176, 14)
  background:SetColorTexture(0, 0, 0, 0.12)

  f.bar = f:CreateTexture(nil, "ARTWORK")
  f.bar:SetPoint("LEFT")
  f.bar:SetSize(176, 14)
  f.bar:SetTexture(LibSharedMedia:Fetch("statusbar", "Skyline"))
  f.bar:SetGradient("HORIZONTAL", startColor, endColor)

  f:Hide()

  return f
end

ns.util.ParseKeystoneItemLink = function(itemLink)
  local challengeMapID, level

  if itemLink == nil then
    return
  end

  local itemLinkSplit = strsplittable("|", itemLink)
  local payload = strsplittable(":", itemLinkSplit[3])
  if payload[2] ~= data.MythicPlusKeystoneItemID then
    return
  end

  local skip = 0
  if payload[14] ~= "" then
    skip = tonumber(payload[14])
  end

  local numModifiers = payload[15 + skip]
  for i = (15 + skip + 1), (15 + skip + (2 * numModifiers) - 1), 2 do
    if payload[i] == "17" then
      challengeMapID = tonumber(payload[i + 1])
    elseif payload[i] == "18" then
      level = tonumber(payload[i + 1])
    end
  end

  return challengeMapID, level
end

-- luacheck: push no max line length
-- Borrowed from the official Blizzard code
-- WARN: There are no mentions about the license.
-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingControls.lua
ns.util.CreateSettingsCheckboxSliderInitializer = function(cbSetting, cbLabel, cbTooltip, sliderSetting, sliderOptions, sliderLabel, sliderTooltip, newTagID)
  local initializerData =
    {
      name = cbLabel,
      tooltip = cbTooltip,
      cbSetting = cbSetting,
      cbLabel = cbLabel,
      cbTooltip = cbTooltip,
      sliderSetting = sliderSetting,
      sliderOptions = sliderOptions,
      sliderLabel = sliderLabel,
      sliderTooltip = sliderTooltip,
      newTagID = newTagID,
    };
  local initializer = Settings.CreateSettingInitializer("SettingsCheckboxSliderControlTemplate", initializerData);
  initializer:AddSearchTags(cbLabel, sliderLabel);
  return initializer;
end

ns.util.CreateSettingsListSectionHeaderInitializer = function(name, tooltip, newTagID)
  local initializerData = {name = name, tooltip = tooltip, newTagID = newTagID};
  return Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", initializerData);
end
-- luacheck: pop
