-- Wow APIs
local CreateFrame = CreateFrame -- luacheck: globals CreateFrame
local UIParent = UIParent -- luacheck: globals UIParent

-- Libraries
local LibStub = LibStub -- luacheck: globals LibStub
local LibSharedMedia = LibStub("LibSharedMedia-3.0")
LibSharedMedia:Register("statusbar", "Clean", "Interface\\AddOns\\Euivin_Assistant\\Textures\\Statusbar_Clean.blp")
LibSharedMedia:Register("statusbar", "Skyline", "Interface\\AddOns\\Euivin_Assistant\\Textures\\bar_skyline.tga")

if _G.Euivin == nil then
    _G.Euivin = {}
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UI_SCALE_CHANGED")
f:RegisterEvent("GX_RESTARTED")
f:SetScript(
    "OnEvent",
    function()
        UIParent:SetScale(0.5)
    end)
