local addonName, ns = ...

-- Wow APIs
local C_CurrencyInfo = C_CurrencyInfo -- luacheck: globals C_CurrencyInfo
local CreateColorFromHexString = CreateColorFromHexString -- luacheck: globals CreateColorFromHexString
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local strlenutf8 = strlenutf8 -- luacheck: globals strlenutf8

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub

-- Local/session variables
local data = ns.data
local util = ns.util
local childrenFrames = {}
local startColor = CreateColorFromHexString("ffff4d96")
local endColor = CreateColorFromHexString("fffcb6ff")
local noLimitColor = CreateColorFromHexString("ffaeff69")
local maxColor = CreateColorFromHexString("ffff0058")

local function EuivinCrestsHandler()
    local cache = _G.Euivin.crests.cache

    for i = 1, #data.Crests, 1 do
        local labelText, valueText, width
        local r = nil
        local g = nil
        local b = nil

        local fullName = cache[i].name
        local current = cache[i].current
        local maxQuantity = cache[i].max

        if maxQuantity == 0 then
            width = 0
            r, g, b = noLimitColor:GetRGB()
            labelText = fullName
            valueText = current
        else
            width = math.floor((current / maxQuantity) * 176)
            if strlenutf8(fullName) > 8 then
                labelText = util.WA_Utf8Sub(fullName, 8) .. "..."
            else
                labelText = fullName
            end
            valueText = current .. "/" .. maxQuantity
        end

        if width == 0 then
            childrenFrames[i].bar:Hide()
        else
            childrenFrames[i].bar:SetWidth(width)
            if current == maxQuantity then
                r, g, b = maxColor:GetRGB()
            end
        end

        childrenFrames[i].label:SetText(labelText)
        childrenFrames[i].value:SetText(valueText)

        if r ~= nil and g ~= nil and b ~= nil then
            childrenFrames[i].value:SetTextColor(r, g, b)
        end
    end
end

local function EuivinInitCrests()
    if _G.Euivin.crests == nil then
        _G.Euivin.crests = {}
    end
    local addon = _G.Euivin.crests

    if addon.cache == nil or next(addon.cache) == nil then
        addon.cache = {
            ["init"] = false,
        }
        for i = 1, #data.Crests, 1 do
            addon.cache[i] = {
                ["name"] = "",
                ["current"] = 0,
                ["max"] = 0,
            }
        end
    end

    if addon.callbacks == nil then
        addon.callbacks = LibStub("CallbackHandler-1.0"):New(addon)
    end

    addon:RegisterCallback("EUIVIN_CRESTS", EuivinCrestsHandler)
end

local function EuivinGetCrests()
    local addon = _G.Euivin.crests
    local cache = addon.cache

    local updated = false

    for i, c in ipairs(data.Crests) do
        local info = C_CurrencyInfo.GetCurrencyInfo(c)

        if cache[i].name ~= info.name then
            cache[i].name = info.name
            updated = true
        end

        local maxQuantity
        local quantity = info.quantity
        if cache[i].current ~= quantity then
            cache[i].current = quantity
            updated = true
        end
        if info.useTotalEarnedForMaxQty then
            maxQuantity = math.max(0, quantity + (info.maxQuantity - info.totalEarned))
        else
            maxQuantity = info.maxQuantity
        end
        if cache[i].max ~= maxQuantity then
            cache[i].max = maxQuantity
            updated = true
        end
    end

    if updated or not cache.init then
        cache.init = true
        addon.callbacks:Fire("EUIVIN_CRESTS")
    end
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hiddenFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- XXX: There may be a better way to check whether the weekly reset is done.
hiddenFrame:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
hiddenFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == addonName then
                EuivinInitCrests()
            end
            return
        end
        if event == "CURRENCY_DISPLAY_UPDATE" then
            local currencyType = ...
            local isCrests = false
            for _, c in ipairs(data.Crests) do
                if currencyType == c then
                    isCrests = true
                    break
                end
            end
            if not isCrests then
                return
            end
        end
        -- event == all others incl. valid `CURRENCY_DISPLAY_UPDATE'.
        EuivinGetCrests()
    end)

-- XXX: Is it better to move these to a separated XML file?
-- TODO: Localize strings
local crestsFrame = util.CreateCategoryFrame("아이템 강화", "EuivinCrestsFrame", "EuivinDelveFrame")
for i = 1, #data.Crests, 1 do
    childrenFrames[i] = util.ProgressBar(crestsFrame, startColor, endColor)
    childrenFrames[i]:SetPointsOffset(0, -15 * i)
    childrenFrames[i]:Show()
end
util.ExpandFrame(crestsFrame)
