
local ADDON_NAME = ...

local CRUSADER_SPELL_ID = 20007

local WALK_ON_AIR_SPELL_ID = 1259416

local WALK_ON_AIR_SOUND =
    "Interface\\AddOns\\FlyOnWings\\walkonair.mp3"

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
    -- Forever can restrict aura access during combat.
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local ok, shouldBeSecret = pcall(
            C_Secrets.ShouldAurasBeSecret
        )

        if not ok or shouldBeSecret then
            return nil -- Aura state is currently unknown
        end
    end

    for index = 1, 40 do
        local ok, aura = pcall(
            C_UnitAuras.GetAuraDataByIndex,
            "player",
            index,
            "HELPFUL"
        )

        if not ok then
            return nil
        end

        if not aura then
            break
        end

        if issecretvalue and issecretvalue(aura.spellId) then
            return nil
        end

        if aura.spellId == CRUSADER_SPELL_ID then
            return true
        end
    end

    return false
end

--------------------------------------------------
-- Crusader detection
--------------------------------------------------

local function UpdateCrusaderState(playSound)
    local found = HasCrusaderBuff()

    -- Trigger only when the buff changes from absent to present.
    if found ~= nil then
        if found and not crusaderActive then

            if playSound and CrusaderProcAlertDB.crusaderEnabled then
                PlayAlertSound(CRUSADER_SOUND)
            end

        end
        
    end
    crusaderActive = found
end

--------------------------------------------------
-- Flight detection
--------------------------------------------------

-- local function HandleFlightTakeoff()
--     if not CrusaderProcAlertDB.flightEnabled then
--         return
--     end

--     if UnitOnTaxi("player") and not flightAlertPlayed then

--         flightAlertPlayed = true

--         PlayAlertSound(FLIGHT_SOUND)
--     end
-- end

local wasOnTaxi = false

local flightFrame = CreateFrame("Frame")

flightFrame:SetScript("OnUpdate", function(self, elapsed)

    self.elapsed = (self.elapsed or 0) + elapsed

    if self.elapsed < 0.2 then
        return
    end

    self.elapsed = 0

    local onTaxi = UnitOnTaxi("player")

    -- Detect takeoff
    if onTaxi and not wasOnTaxi then

        if CrusaderProcAlertDB.flightEnabled then
            PlayAlertSound(FLIGHT_SOUND)
            print("|cff00ff00CPA: Flight started!|r")
        end

    end

    -- Remember current state
    wasOnTaxi = onTaxi

end)

--------------------------------------------------
-- Event handling
--------------------------------------------------

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")


frame:SetScript("OnEvent", function(self, event, ...)

    if event == "ADDON_LOADED" then

        local loadedAddon = ...

        if loadedAddon ~= ADDON_NAME then
            return
        end
        -- Initialize without playing a sound if the buff
        -- is already active when the addon loads.
        UpdateCrusaderState(false)
        print("|cff00ff00Fly on wings loaded.|r")
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

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellID = ...

        if unit == "player" and spellID == WALK_ON_AIR_SPELL_ID then
            PlayAlertSound(WALK_ON_AIR_SOUND)
        end
    end

end)

--------------------------------------------------
-- GUI Settings
--------------------------------------------------

local panel = CreateFrame("Frame")
panel.name = "Fly on wings"

local title = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormalLarge"
)

title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Fly on wings")

local description = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontHighlight"
)

description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
description:SetText("Fly on wings.")

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
    "Fly on wings"
)

Settings.RegisterAddOnCategory(category)

--------------------------------------------------
-- Slash commands
--------------------------------------------------

SLASH_CRUSADERPROC1 = "/fow"

SlashCmdList["CRUSADERPROC"] = function(msg)

    msg = string.lower(msg or "")

    if msg == "crusader" then

        PlayAlertSound(CRUSADER_SOUND)

    elseif msg == "flight" then

        PlayAlertSound(FLIGHT_SOUND)

    elseif msg == "on" then

        CrusaderProcAlertDB.crusaderEnabled = true
        CrusaderProcAlertDB.flightEnabled = true

        print("Event sounds: all alerts enabled.")

    elseif msg == "off" then

        CrusaderProcAlertDB.crusaderEnabled = false
        CrusaderProcAlertDB.flightEnabled = false

        print("Fly on wings: all alerts disabled.")

    else

        print("/fow crusader - Test Crusader sound")
        print("/fow flight - Test flight sound")
        print("/fow on - Enable alerts")
        print("/fow off - Disable alerts")

    end

end
