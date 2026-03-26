local addonName, ns = ...

-- Wow APIs
local C_CurrencyInfo = C_CurrencyInfo -- luacheck: globals C_CurrencyInfo
local C_MythicPlus = C_MythicPlus -- luacheck: globals C_MythicPlus
local C_WeeklyRewards = C_WeeklyRewards -- luacheck: globals C_WeeklyRewards
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- Local/session variables
local data = ns.data
local util = ns.util
local rewardsFrame, keysFrame
local startColor = CreateColorFromHexString("ff5433ff")
local endColor = CreateColorFromHexString("ffb3a7ff")
local maxColor = CreateColorFromHexString("ffff0058")

local function EuivinDelveHandler(event)
  local cache = _G.Euivin.delve.cache

  if event == "EUIVIN_DELVE_REWARDS" then
    local runs = cache.runs
    rewardsFrame.label:SetFormattedText("보상 [%d/3]", runs)

    local width
    width = math.floor((runs / 3) * 176)
    if width == 0 then
      rewardsFrame.bar:Hide()
    else
      rewardsFrame.bar:Show()
      rewardsFrame.bar:SetWidth(width)
    end

    local rewardsText = ""
    if C_WeeklyRewards.CanClaimRewards() then
      rewardsFrame.value:SetText(rewardsText)
    end
    for i, ilvl in ipairs(cache.rewards) do
      if ilvl == 0 then
        break
      end
      if i == 1 then
        rewardsText = ilvl
      else
        rewardsText = rewardsText .. " || " .. ilvl
      end
    end
    rewardsFrame.value:SetText(rewardsText)

    return
  end

  -- event == "EUIVIN_COFFER_KEYS"
  local quantity = cache.currentKeys / 100
  local maxQuantity = cache.maxKeys / 100
  local width = math.floor((quantity / maxQuantity) * 176)

  if width == 0 then
    keysFrame.bar:Hide()
  else
    if not keysFrame.bar:IsShown() then
      keysFrame.bar:Show()
    end
    keysFrame.bar:SetWidth(width)
  end

  keysFrame.label:SetText(cache.keyName)
  keysFrame.value:SetText(quantity .. "/" .. maxQuantity)
  if quantity == maxQuantity then
    local r, g, b = maxColor:GetRGB()
    keysFrame.value:SetTextColor(r, g, b)
  end
end

local function EuivinInitDelve()
  if _G.Euivin.delve == nil then
    _G.Euivin.delve = {}
  end
  local addon = _G.Euivin.delve

  if addon.cache == nil or next(addon.cache) == nil then
    addon.cache = {
      ["rewards"] = { 0, 0, 0 },
      ["runs"] = 0,
      ["currentKeys"] = 0,
      ["maxKeys"] = 0,
      ["keyName"] = "",
      ["rewardsInit"] = false,
      ["keysInit"] = false,
    }
  end

  if addon.callbacks == nil then
    addon.callbacks = LibStub("CallbackHandler-1.0"):New(addon)
  end

  local events = {
    "EUIVIN_DELVE_REWARDS",
    "EUIVIN_COFFER_KEYS",
  }
  for _, e in ipairs(events) do
    addon:RegisterCallback(e, EuivinDelveHandler, e)
  end
end

local function EuivinGetDelveRewards()
  local addon = _G.Euivin.delve
  local cache = addon.cache

  local updated = false

  C_MythicPlus.RequestRewards()

  local rewards = C_WeeklyRewards.GetActivities(6)
  if rewards == nil then
    cache.rewards = { 0, 0, 0 }
    addon.callbacks:Fire("EUIVIN_DELVE_REWARDS")
    return
  end

  for i, r in ipairs(rewards) do
    if r.threshold > r.progress then
      break
    end

    if r.level > 8 then
      if cache.rewards[i] ~= data.DelveRewards[8] then
        cache.rewards[i] = data.DelveRewards[8]
        updated = true
      end
    else
      if cache.rewards[i] ~= data.DelveRewards[r.level] then
        cache.rewards[i] = data.DelveRewards[r.level]
        updated = true
      end
    end
  end

  local runs = 0
  for _, r in ipairs(cache.rewards) do
    if r == data.DelveRewards[#data.DelveRewards] then
      runs = runs + 1
    end
  end
  if cache.runs ~= runs then
    cache.runs = runs
    updated = true
  end

  if updated or not cache.rewardsInit then
    cache.rewardsInit = true
    addon.callbacks:Fire("EUIVIN_DELVE_REWARDS")
  end
end

local function EuivinGetCofferKeys()
  local addon = _G.Euivin.delve
  local cache = addon.cache

  local updated = false

  local keysInfo = C_CurrencyInfo.GetCurrencyInfo(data.CofferKeys.key)
  local shardsInfo = C_CurrencyInfo.GetCurrencyInfo(data.CofferKeys.shards)

  if cache.keyName ~= keysInfo.name then
    cache.keyName = keysInfo.name
    updated = true
  end

  local quantity = keysInfo.quantity * 100 + shardsInfo.quantity
  if cache.currentKeys ~= quantity then
    cache.currentKeys = quantity
    updated = true
  end
  local maxQuantity = math.max(0, quantity + (shardsInfo.maxWeeklyQuantity - shardsInfo.quantityEarnedThisWeek))
  if cache.maxKeys ~= maxQuantity then
    cache.maxKeys = maxQuantity
    updated = true
  end

  if updated or not cache.keysInit then
    cache.keysInit = true
    addon.callbacks:Fire("EUIVIN_COFFER_KEYS")
  end
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hiddenFrame:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
hiddenFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
hiddenFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- XXX: There may be a better way to check whether the weekly reset is done.
hiddenFrame:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
hiddenFrame:SetScript(
  "OnEvent",
  function(_, event, ...)
    if event == "ADDON_LOADED" then
      local loadedAddon = ...
      if loadedAddon == addonName then
        EuivinInitDelve()
      end
      return
    end
    if event == "CURRENCY_DISPLAY_UPDATE" then
      local currencyType = ...
      if currencyType ~= data.CofferKeys.key and currencyType ~= data.CofferKeys.shards then
        return
      end
      EuivinGetCofferKeys()
      return
    end
    -- event == all others...
    EuivinGetDelveRewards()
    EuivinGetCofferKeys()
end)

-- XXX: Is it better to move these to a separated XML file?
-- TODO: Localize strings
local delveFrame = util.CreateCategoryFrame("구렁", "EuivinDelveFrame", "EuivinMythicFrame")
rewardsFrame = util.ProgressBar(delveFrame, startColor, endColor)
rewardsFrame:Show()
keysFrame = util.ProgressBar(delveFrame, startColor, endColor)
keysFrame:SetPointsOffset(0, -30)
keysFrame:Show()
util.ExpandFrame(delveFrame)
