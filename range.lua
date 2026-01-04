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
local targetRangeFrame, focusRangeFrame
local outOfRangeColor = CreateColorFromHexString("ffff0004")
local under40Color = CreateColorFromHexString("fff8ff00")
local under30Color = CreateColorFromHexString("ff00b1ff")
local under10Color = CreateColorFromHexString("ff00ff26")

local function EuivinRangeHandler(event)
    local target, frame
    if event == "EUIVIN_RANGE_UPDATED_TARGET" then
        target = "target"
        frame = targetRangeFrame
    else -- event == "EUIVIN_RANGE_UPDATED_FOCUS"
        target = "focus"
        frame = focusRangeFrame
    end

    local minRange, maxRange = LibRangeCheck:GetRange(target)
    if maxRange == nil then
        maxRange = 999
    end
    if minRange == nil then
        minRange = maxRange
    end

    local rangeText
    if minRange > 40 or maxRange >= 999 then
        -- TODO: Localize strings
        rangeText = minRange .. "m 이상"
    else
        rangeText = minRange .. " - " .. maxRange
    end
    frame.text:SetText(rangeText)
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

local function EuivinInitRange()
    if _G.Euivin.range == nil then
        _G.Euivin.range = {}
    end
    local addon = _G.Euivin.range

    if addon.callbacks == nil then
        addon.callbacks = LibStub("CallbackHandler-1.0"):New(addon)
    end

    addon.targetTimer = nil
    addon.focusTimer = nil

    local events = {
        "EUIVIN_RANGE_UPDATED_TARGET",
        "EUIVIN_RANGE_UPDATED_FOCUS",
    }
    for _, e in ipairs(events) do
        addon:RegisterCallback(e, EuivinRangeHandler, e)
    end
end

local function EuivinUpdateRange(event)
    local addon = _G.Euivin.range

    local target, timer, targetEvent
    if event == "PLAYER_TARGET_CHANGED" then
        target = "target"
        targetEvent = "EUIVIN_RANGE_UPDATED_TARGET"
    else -- event == "PLAYER_FOCUS_CHANGED"
        target = "focus"
        targetEvent = "EUIVIN_RANGE_UPDATED_FOCUS"
    end
    timer = target .. "Timer"

    if addon[timer] ~= nil then
        addon[timer]:Cancel()
        addon[timer] = nil
    end

    if not UnitExists(target) then
        return
    end

    addon.callbacks:Fire(targetEvent)
    addon[timer] = C_Timer.NewTicker(
        1,
        function(self)
            if not UnitExists(target) then
                self:Cancel()
                return
            end
            addon.callbacks:Fire(targetEvent)
        end)
end

local function initRangeFrame(f, parent)
    f:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 22, -23)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.text:SetPoint("LEFT")
    f.text:SetFontHeight(11)
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:RegisterEvent("ADDON_LOADED")
hiddenFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
hiddenFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
hiddenFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...
            if loadedAddon == addonName then
                EuivinInitRange()
            end
            return
        end
        EuivinUpdateRange(event)
    end)

targetRangeFrame = CreateFrame("Frame", nil, TargetFrame)
initRangeFrame(targetRangeFrame, TargetFrame)
focusRangeFrame = CreateFrame("Frame", nil, FocusFrame)
initRangeFrame(focusRangeFrame, FocusFrame)
