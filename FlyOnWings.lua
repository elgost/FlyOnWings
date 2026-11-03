
local ADDON_NAME = ...

local CRUSADER_SPELL_ID = 20007

local CRUSADER_SOUND =
    "Interface\\AddOns\\FlyOnWings\\crusader.mp3"

local FLIGHT_SOUND =
    "Interface\\AddOns\\FlyOnWings\\flyonwings.mp3"

--------------------------------------------------
-- Saved settings
--------------------------------------------------

CrusaderProcAlertDB = CrusaderProcAlertDB or {}

if CrusaderProcAlertDB.crusaderEnabled == nil then
    CrusaderProcAlertDB.crusaderEnabled = true
end

if CrusaderProcAlertDB.flightEnabled == nil then
    CrusaderProcAlertDB.flightEnabled = true
end

--------------------------------------------------
-- State
--------------------------------------------------

local crusaderActive = false
local flightAlertPlayed = false

local frame = CreateFrame("Frame")

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function PlayAlertSound(soundFile)
    PlaySoundFile(soundFile, "Master")
end

local function HasCrusaderBuff()
    if not C_UnitAuras then
        return false
    end

    local index = 1

    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(
            "player",
            index,
            "HELPFUL"
        )

        if not aura then
            break
        end

        if aura.spellId == CRUSADER_SPELL_ID then
            return true
        end

        index = index + 1
    end

    return false
end

--------------------------------------------------
-- Crusader detection
--------------------------------------------------

local function UpdateCrusaderState(playSound)
    local found = HasCrusaderBuff()

    -- Trigger only when the buff changes from absent to present.
    if found and not crusaderActive then

        if playSound and CrusaderProcAlertDB.crusaderEnabled then
            PlayAlertSound(CRUSADER_SOUND)
        end

    end

    crusaderActive = found
end

--------------------------------------------------
-- Flight detection
--------------------------------------------------

local function HandleFlightTakeoff()
    if not CrusaderProcAlertDB.flightEnabled then
        return
    end

    if UnitOnTaxi("player") and not flightAlertPlayed then

        flightAlertPlayed = true

        PlayAlertSound(FLIGHT_SOUND)
    end
end

--------------------------------------------------
-- Event handling
--------------------------------------------------

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_CONTROL_LOST")
frame:RegisterEvent("PLAYER_CONTROL_GAINED")

frame:SetScript("OnEvent", function(self, event, ...)

    if event == "ADDON_LOADED" then

        local loadedAddon = ...

        if loadedAddon ~= ADDON_NAME then
            return
        end

        -- Initialize without playing a sound if the buff
        -- is already active when the addon loads.
        UpdateCrusaderState(false)

        print("|cff00ff00Crusader Proc Alert loaded.|r")

    elseif event == "UNIT_AURA" then

        local unit = ...

        if unit == "player" then
            UpdateCrusaderState(true)
        end

    elseif event == "PLAYER_CONTROL_LOST" then

        HandleFlightTakeoff()

    elseif event == "PLAYER_CONTROL_GAINED" then

        -- Reset the flight alert after landing.
        flightAlertPlayed = false

    end

end)

--------------------------------------------------
-- GUI Settings
--------------------------------------------------

local panel = CreateFrame("Frame")
panel.name = "Crusader Proc Alert"

local title = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormalLarge"
)

title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Crusader Proc Alert")

local description = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontHighlight"
)

description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
description:SetText("Configure your sound alerts.")

--------------------------------------------------
-- Checkbox helper
--------------------------------------------------

local function CreateCheckbox(label, setting, yOffset)

    local checkbox = CreateFrame("CheckButton", nil, panel)

    checkbox:SetSize(24, 24)
    checkbox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)

    checkbox:SetNormalTexture(
        "Interface\\Buttons\\UI-CheckBox-Up"
    )

    checkbox:SetPushedTexture(
        "Interface\\Buttons\\UI-CheckBox-Down"
    )

    checkbox:SetHighlightTexture(
        "Interface\\Buttons\\UI-CheckBox-Highlight"
    )

    checkbox:SetCheckedTexture(
        "Interface\\Buttons\\UI-CheckBox-Check"
    )

    local text = checkbox:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontNormal"
    )

    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText(label)

    checkbox:SetScript("OnShow", function(self)
        self:SetChecked(CrusaderProcAlertDB[setting])
    end)

    checkbox:SetScript("OnClick", function(self)

        CrusaderProcAlertDB[setting] = self:GetChecked()

    end)

    return checkbox
end

CreateCheckbox(
    "Enable Crusader proc sound",
    "crusaderEnabled",
    -10
)

CreateCheckbox(
    "Enable flight master takeoff sound",
    "flightEnabled",
    -45
)

--------------------------------------------------
-- Register settings category
--------------------------------------------------

local category = Settings.RegisterCanvasLayoutCategory(
    panel,
    "Crusader Proc Alert"
)

Settings.RegisterAddOnCategory(category)

--------------------------------------------------
-- Slash commands
--------------------------------------------------

SLASH_CRUSADERPROC1 = "/cpa"

SlashCmdList["CRUSADERPROC"] = function(msg)

    msg = string.lower(msg or "")

    if msg == "crusader" then

        PlayAlertSound(CRUSADER_SOUND)

    elseif msg == "flight" then

        PlayAlertSound(FLIGHT_SOUND)

    elseif msg == "on" then

        CrusaderProcAlertDB.crusaderEnabled = true
        CrusaderProcAlertDB.flightEnabled = true

        print("Crusader Proc Alert: all alerts enabled.")

    elseif msg == "off" then

        CrusaderProcAlertDB.crusaderEnabled = false
        CrusaderProcAlertDB.flightEnabled = false

        print("Crusader Proc Alert: all alerts disabled.")

    else

        print("/cpa crusader - Test Crusader sound")
        print("/cpa flight - Test flight sound")
        print("/cpa on - Enable alerts")
        print("/cpa off - Disable alerts")

    end

end
