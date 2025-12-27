-- Wow APIs
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local UIParent = UIParent -- luacheck: globals UIParent

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UI_SCALE_CHANGED")
f:RegisterEvent("GX_RESTARTED")
f:SetScript(
    "OnEvent",
    function()
        UIParent:SetScale(0.5)
    end)
