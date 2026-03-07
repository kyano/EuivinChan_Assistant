local addonName, ns = ...

-- Wow APIs
local C_CurrencyInfo = C_CurrencyInfo -- luacheck: globals C_CurrencyInfo
local C_Item = C_Item -- luacheck: globals C_Item
local C_Timer = C_Timer -- luacheck: globals C_Timer
local C_TradeSkillUI = C_TradeSkillUI -- luacheck: globals C_TradeSkillUI
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local GetProfessionInfo = GetProfessionInfo -- luacheck: globals GetProfessionInfo
local GetProfessions = GetProfessions -- luacheck: globals GetProfessions

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- Local/session variables
local data = ns.data
local util = ns.util
local professionFrame, sparkFrame
local concentrationFrame = { [1] = nil, [2] = nil }
local moxieFrame = { [1] = nil, [2] = nil }
local startColor = CreateColorFromHexString("ffd950ff")
local endColor = CreateColorFromHexString("ffd3a7ff")

local function EuivinProfessionHandler(event)
  local addon = _G.Euivin.profession
  local cache = addon.cache

  if event == "EUIVIN_CONCENTRATION_UPDATED" then
    for i, c in ipairs(cache.concentration) do
      local info = C_CurrencyInfo.GetCurrencyInfo(c)
      local quantity = info.quantity
      local maxQuantity = info.maxQuantity

      concentrationFrame[i].label:SetText(info.name)
      concentrationFrame[i].value:SetText(quantity .. "/" .. maxQuantity)

      local width = math.floor((quantity / maxQuantity) * 176)
      if width == 0 then
        concentrationFrame[i].bar:Hide()
      else
        concentrationFrame[i].bar:Show()
        concentrationFrame[i].bar:SetWidth(width)
      end

      concentrationFrame[i]:SetPointsOffset(0, -15 * i)
      concentrationFrame[i]:Show()
    end
    for i = #cache.concentration + 1, 2, 1 do
      if concentrationFrame[i]:IsShown() then
        concentrationFrame[i]:Hide()
      end
    end

    moxieFrame[1]:SetPointsOffset(0, -15 * (#cache.concentration + 1))
    util.ExpandFrame(professionFrame)
    return
  end

  -- event == "EUIVIN_MOXIE_UPDATED"
  if event == "EUIVIN_MOXIE_UPDATED" then
    for i, c in ipairs(cache.moxie) do
      local info = C_CurrencyInfo.GetCurrencyInfo(c)
      local quantity = info.quantity

      moxieFrame[i].label:SetText(info.name)
      moxieFrame[i].value:SetText(quantity)

      local width = math.min(math.floor((quantity / 150) * 176), 176)
      if width == 0 then
        moxieFrame[i].bar:Hide()
      else
        moxieFrame[i].bar:Show()
        moxieFrame[i].bar:SetWidth(width)
      end

      moxieFrame[i]:SetPointsOffset(0, -15 * (#cache.concentration + i))
      moxieFrame[i]:Show()
    end
    for i = #cache.moxie + 1, 2, 1 do
      if moxieFrame[i]:IsShown() then
        moxieFrame[i]:Hide()
      end
    end

    sparkFrame:SetPointsOffset(0, -15 * (#cache.concentration + #cache.moxie + 1))
    util.ExpandFrame(professionFrame)
    return
  end

  -- event == "EUIVIN_SPARKS_UPDATED"
  local maxQuantity = cache.spark.max
  local availableQuantity = cache.spark.available
  sparkFrame.value:SetText((availableQuantity / 10) .. "/" .. (maxQuantity / 10))

  local sparkName = C_Item.GetItemInfo(data.Sparks.spark)
  -- XXX: If the item data is not loaded yet, do nothing.
  if sparkName == nil then
    C_Timer.After(
      0,
      function()
        addon.callbacks:Fire("EUIVIN_SPARKS_UPDATED")
    end)
    return
  end
  sparkFrame.label:SetText(sparkName)

  local width = math.floor((availableQuantity / maxQuantity) * 176)
  if width == 0 then
    sparkFrame.bar:Hide()
  else
    sparkFrame.bar:Show()
    sparkFrame.bar:SetWidth(width)
  end
end

local function EuivinInitProfession()
  if _G.Euivin.profession == nil then
    _G.Euivin.profession = {}
  end
  local addon = _G.Euivin.profession

  if addon.cache == nil or next(addon.cache) == nil then
    addon.cache = {
      ["concentration"] = {},
      ["moxie"] = {},
      ["spark"] = {
        ["available"] = 0,
        ["max"] = 0,
      },
      ["init"] = false,
    }
  end

  if addon.callbacks == nil then
    addon.callbacks = LibStub("CallbackHandler-1.0"):New(addon)
  end

  addon.timer = nil

  local events = {
    "EUIVIN_CONCENTRATION_UPDATED",
    "EUIVIN_SPARKS_UPDATED",
    "EUIVIN_MOXIE_UPDATED",
  }
  for _, e in ipairs(events) do
    addon:RegisterCallback(e, EuivinProfessionHandler, e)
  end
end

local function EuivinGetProfessions()
  local addon = _G.Euivin.profession
  local cache = addon.cache

  if addon.timer ~= nil then
    addon.timer:Cancel()
    addon.timer = nil
  end

  local profs = {}
  local prof1, prof2 = GetProfessions()
  if prof1 ~= nil then
    table.insert(profs, prof1)
    if prof2 ~= nil then
      table.insert(profs, prof2)
      table.sort(profs)
    end
  end

  local concentrationCurrenciesID = {}
  local moxieCurrenciesID = {}
  for _, prof in ipairs(profs) do
    local skillLine = select(7, GetProfessionInfo(prof))
    local concentrationCurrencyID
      = C_TradeSkillUI.GetConcentrationCurrencyID(data.ProfessionSkillLineIDs[skillLine])
    if concentrationCurrencyID ~= 0 then
      table.insert(concentrationCurrenciesID, concentrationCurrencyID)
    end
    table.insert(moxieCurrenciesID, data.ProfessionMoxieIDs[skillLine])
  end
  cache.concentration = {}
  cache.moxie = {}
  for i, c in ipairs(concentrationCurrenciesID) do
    cache.concentration[i] = c
  end
  for i, c in ipairs(moxieCurrenciesID) do
    cache.moxie[i] = c
  end

  addon.callbacks:Fire("EUIVIN_CONCENTRATION_UPDATED")
  if #cache.concentration ~= 0 then
    addon.timer = C_Timer.NewTicker(
      360,
      function(self)
        if self ~= addon.timer then
          self:Cancel()
          return
        end
        addon.callbacks:Fire("EUIVIN_CONCENTRATION_UPDATED")
    end)
  end
  addon.callbacks:Fire("EUIVIN_MOXIE_UPDATED")
end

local function EuivinGetSparks()
  local addon = _G.Euivin.profession
  local cache = addon.cache

  local updated = false

  local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(data.Sparks.dust)
  local getFurtherCount = (currencyInfo.maxQuantity - currencyInfo.quantity) * 5
  local availableQuantity = (C_Item.GetItemCount(data.Sparks.spark, true, true, true, true) * 5)
  local maxQuantity = availableQuantity + getFurtherCount

  if cache.spark.available ~= availableQuantity then
    cache.spark.available = availableQuantity
    updated = true
  end
  if cache.spark.max ~= maxQuantity then
    cache.spark.max = maxQuantity
    updated = true
  end

  if updated or not cache.init then
    cache.init = true
    addon.callbacks:Fire("EUIVIN_SPARKS_UPDATED")
  end
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hiddenFrame:RegisterEvent("SKILL_LINES_CHANGED")
hiddenFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
hiddenFrame:RegisterEvent("BAG_UPDATE_DELAYED")
hiddenFrame:RegisterEvent("ITEM_COUNT_CHANGED")
hiddenFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
hiddenFrame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
hiddenFrame:SetScript(
  "OnEvent",
  function(_, event, ...)
    local addon = _G.Euivin.profession
    local cache
    if addon ~= nil then
      cache = addon.cache
    end

    if event == "ADDON_LOADED" then
      local loadedAddon = ...
      if loadedAddon == addonName then
        EuivinInitProfession()
      end
      return
    end
    if event == "PLAYER_ENTERING_WORLD" then
      EuivinGetProfessions()
      EuivinGetSparks()
      return
    end
    if event == "SKILL_LINES_CHANGED" then
      EuivinGetProfessions()
      return
    end
    if event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
      if addon ~= nil and addon.callbacks ~= nil then
        addon.callbacks:Fire("EUIVIN_CONCENTRATION_UPDATED")
      end
      return
    end
    if event == "CURRENCY_DISPLAY_UPDATE" then
      local currencyType = ...
      -- for moxie
      local moxieUpdated = false
      if cache ~= nil then
        for _, c in ipairs(cache.moxie) do
          if currencyType == c then
            moxieUpdated = true
          end
        end
      end
      if moxieUpdated then
        addon.callbacks:Fire("EUIVIN_MOXIE_UPDATED")
      end
      if currencyType ~= data.Sparks.dust then
        return
      end
    end
    if event == "ITEM_DATA_LOAD_RESULT" then
      local itemID, success = ...
      if itemID ~= data.Sparks.spark or not success then
        return
      end
    end
    if event == "ITEM_COUNT_CHANGED" then
      local itemID = ...
      if itemID ~= data.Sparks.fractured and itemID ~= data.Sparks.spark then
        return
      end
    end
    -- event == all others for sparks
    EuivinGetSparks()
end)

-- XXX: Is it better to move these to a separated XML file?
-- TODO: Localize strings
professionFrame = util.CreateCategoryFrame("전문기술/제작", "EuivinProfessionFrame", "EuivinCrestsFrame")
for i = 1, 2, 1 do
  concentrationFrame[i] = util.ProgressBar(professionFrame, startColor, endColor)
  moxieFrame[i] = util.ProgressBar(professionFrame, startColor, endColor)
end
sparkFrame = util.ProgressBar(professionFrame, startColor, endColor)
sparkFrame:Show()
util.ExpandFrame(professionFrame)
