-- Spiral Staircase Helper Addon
-- Helps calculate positions for building spiral staircases in WoW housing

local addonName, addon = ...

-- Saved variables defaults
local defaults = {
    radius = 3.0,           -- Distance from center to each stair
    heightPerStep = 0.5,    -- Height increase per step
    anglePerStep = 30,      -- Degrees to rotate per step
    numSteps = 12,          -- Total number of stairs
    clockwise = true,       -- Direction of spiral
    centerX = 0,            -- Center X coordinate
    centerY = 0,            -- Center Y coordinate
    centerZ = 0,            -- Center Z (height) coordinate
}

-- Addon namespace
SpiralStairs = {}
local SS = SpiralStairs

-- Local references
local math_sin = math.sin
local math_cos = math.cos
local math_rad = math.rad
local math_floor = math.floor
local string_format = string.format

-- Calculated stair positions
SS.stairs = {}

-- ============================================================================
-- Core Calculation Functions
-- ============================================================================

--- Calculate all stair positions based on current settings
function SS:CalculateStairs()
    self.stairs = {}
    local db = SpiralStairsDB or defaults

    local direction = db.clockwise and 1 or -1

    for i = 1, db.numSteps do
        local stepIndex = i - 1
        local angle = math_rad(stepIndex * db.anglePerStep * direction)

        local stair = {
            step = i,
            x = db.centerX + (db.radius * math_cos(angle)),
            y = db.centerY + (db.radius * math_sin(angle)),
            z = db.centerZ + (stepIndex * db.heightPerStep),
            rotation = (stepIndex * db.anglePerStep * direction) % 360,
        }

        table.insert(self.stairs, stair)
    end

    return self.stairs
end

--- Get the position for a specific stair step
function SS:GetStairPosition(stepNum)
    if stepNum < 1 or stepNum > #self.stairs then
        return nil
    end
    return self.stairs[stepNum]
end

--- Print all stair positions to chat
function SS:PrintStairPositions()
    if #self.stairs == 0 then
        self:CalculateStairs()
    end

    local db = SpiralStairsDB or defaults
    print("|cff00ff00=== Spiral Staircase Positions ===|r")
    print(string_format("Center: (%.2f, %.2f, %.2f)", db.centerX, db.centerY, db.centerZ))
    print(string_format("Radius: %.2f | Height/Step: %.2f | Angle/Step: %d°",
        db.radius, db.heightPerStep, db.anglePerStep))
    print(string_format("Direction: %s | Steps: %d",
        db.clockwise and "Clockwise" or "Counter-clockwise", db.numSteps))
    print("|cff00ff00---------------------------------|r")

    for _, stair in ipairs(self.stairs) do
        print(string_format("|cffffcc00Step %2d:|r X: %7.2f  Y: %7.2f  Z: %7.2f  Rot: %3d°",
            stair.step, stair.x, stair.y, stair.z, stair.rotation))
    end

    print("|cff00ff00=================================|r")
end

--- Print position for a single step
function SS:PrintSingleStep(stepNum)
    local stair = self:GetStairPosition(stepNum)
    if stair then
        print(string_format("|cff00ff00Step %d:|r X: %.2f  Y: %.2f  Z: %.2f  Rotation: %d°",
            stair.step, stair.x, stair.y, stair.z, stair.rotation))
    else
        print("|cffff0000Invalid step number.|r")
    end
end

-- ============================================================================
-- Configuration UI (Built without templates for compatibility)
-- ============================================================================

local function CreateBackdrop(frame)
    -- Try modern backdrop API first, fall back to old method
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
    end
end

local function CreateSlider(parent, name, minVal, maxVal, step)
    local slider = CreateFrame("Slider", name, parent, "BackdropTemplate")
    slider:SetSize(140, 17)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Background
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })

    -- Thumb texture
    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetSize(32, 32)
    slider:SetThumbTexture(thumb)

    return slider
end

local function CreateEditBox(parent, name, width)
    local editBox = CreateFrame("EditBox", name, parent, "BackdropTemplate")
    editBox:SetSize(width or 60, 20)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")

    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    return editBox
end

local function CreateButton(parent, name, text, width, height)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 100, height or 22)
    button:SetText(text)
    return button
end

local function CreateCheckbox(parent, name, label)
    local check = CreateFrame("CheckButton", name, parent)
    check:SetSize(26, 26)

    local normalTex = check:CreateTexture(nil, "ARTWORK")
    normalTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
    normalTex:SetAllPoints()
    check:SetNormalTexture(normalTex)

    local pushedTex = check:CreateTexture(nil, "ARTWORK")
    pushedTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Down")
    pushedTex:SetAllPoints()
    check:SetPushedTexture(pushedTex)

    local highlightTex = check:CreateTexture(nil, "HIGHLIGHT")
    highlightTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    highlightTex:SetAllPoints()
    highlightTex:SetBlendMode("ADD")
    check:SetHighlightTexture(highlightTex)

    local checkedTex = check:CreateTexture(nil, "OVERLAY")
    checkedTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkedTex:SetAllPoints()
    check:SetCheckedTexture(checkedTex)

    local labelText = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", check, "RIGHT", 2, 0)
    labelText:SetText(label)
    check.label = labelText

    return check
end

local function CreateConfigFrame()
    -- Main frame
    local frame = CreateFrame("Frame", "SpiralStairsConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(320, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Spiral Staircase Helper")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    local yOffset = -45
    local db = SpiralStairsDB or defaults

    -- Helper to create a labeled slider row
    local function CreateSliderRow(label, dbKey, minVal, maxVal, step, isInteger)
        local rowY = yOffset

        local labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("TOPLEFT", 20, rowY)
        labelText:SetText(label)
        labelText:SetWidth(100)
        labelText:SetJustifyH("LEFT")

        local slider = CreateSlider(frame, nil, minVal, maxVal, step)
        slider:SetPoint("TOPLEFT", 125, rowY)

        local valueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
        valueText:SetWidth(40)

        slider:SetScript("OnValueChanged", function(self, value)
            if isInteger then
                value = math_floor(value + 0.5)
            end
            SpiralStairsDB[dbKey] = value
            if isInteger then
                valueText:SetText(string_format("%d", value))
            else
                valueText:SetText(string_format("%.1f", value))
            end
            SS:CalculateStairs()
        end)

        yOffset = yOffset - 35

        return { slider = slider, valueText = valueText, dbKey = dbKey, isInteger = isInteger }
    end

    -- Helper to create a labeled edit box row
    local function CreateEditRow(label, dbKey)
        local rowY = yOffset

        local labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("TOPLEFT", 20, rowY)
        labelText:SetText(label)
        labelText:SetWidth(100)
        labelText:SetJustifyH("LEFT")

        local editBox = CreateEditBox(frame, nil, 80)
        editBox:SetPoint("TOPLEFT", 125, rowY + 3)

        editBox:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText()) or 0
            SpiralStairsDB[dbKey] = value
            SS:CalculateStairs()
            self:ClearFocus()
        end)

        editBox:SetScript("OnEscapePressed", function(self)
            self:SetText(string_format("%.2f", SpiralStairsDB[dbKey]))
            self:ClearFocus()
        end)

        yOffset = yOffset - 30

        return { editBox = editBox, dbKey = dbKey }
    end

    -- Create sliders
    frame.radiusRow = CreateSliderRow("Radius:", "radius", 0.5, 10, 0.5, false)
    frame.heightRow = CreateSliderRow("Height/Step:", "heightPerStep", 0.1, 2.0, 0.1, false)
    frame.angleRow = CreateSliderRow("Angle/Step:", "anglePerStep", 5, 90, 5, true)
    frame.stepsRow = CreateSliderRow("Num Steps:", "numSteps", 2, 36, 1, true)

    -- Center coordinates label
    yOffset = yOffset - 10
    local coordLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    coordLabel:SetPoint("TOPLEFT", 20, yOffset)
    coordLabel:SetText("|cff00ff00Center Coordinates:|r")
    yOffset = yOffset - 25

    -- Center coordinate inputs
    frame.centerXRow = CreateEditRow("Center X:", "centerX")
    frame.centerYRow = CreateEditRow("Center Y:", "centerY")
    frame.centerZRow = CreateEditRow("Center Z:", "centerZ")

    -- Direction checkbox
    yOffset = yOffset - 5
    local dirCheck = CreateCheckbox(frame, nil, "Clockwise Direction")
    dirCheck:SetPoint("TOPLEFT", 20, yOffset)
    dirCheck:SetScript("OnClick", function(self)
        SpiralStairsDB.clockwise = self:GetChecked()
        SS:CalculateStairs()
    end)
    frame.directionCheck = dirCheck
    yOffset = yOffset - 35

    -- Buttons
    local printBtn = CreateButton(frame, nil, "Print Positions", 130, 24)
    printBtn:SetPoint("TOPLEFT", 20, yOffset)
    printBtn:SetScript("OnClick", function()
        SS:PrintStairPositions()
    end)

    local playerBtn = CreateButton(frame, nil, "Use Player Pos", 130, 24)
    playerBtn:SetPoint("TOPLEFT", 160, yOffset)
    playerBtn:SetScript("OnClick", function()
        local px, py, pz = SS:GetPlayerPosition()
        if px then
            SpiralStairsDB.centerX = px
            SpiralStairsDB.centerY = py
            SpiralStairsDB.centerZ = pz
            SS:RefreshConfigUI()
            SS:CalculateStairs()
            print("|cff00ff00Center set to player position.|r")
        else
            print("|cffff0000Could not get player position.|r")
        end
    end)

    yOffset = yOffset - 30

    local previewBtn = CreateButton(frame, nil, "Preview Info", 130, 24)
    previewBtn:SetPoint("TOPLEFT", 20, yOffset)
    previewBtn:SetScript("OnClick", function()
        SS:ShowPreview()
    end)

    local resetBtn = CreateButton(frame, nil, "Reset Defaults", 130, 24)
    resetBtn:SetPoint("TOPLEFT", 160, yOffset)
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(defaults) do
            SpiralStairsDB[k] = v
        end
        SS:RefreshConfigUI()
        SS:CalculateStairs()
        print("|cff00ff00Settings reset to defaults.|r")
    end)

    frame:Hide()
    SS.configFrame = frame
    return frame
end

--- Refresh the config UI with current values
function SS:RefreshConfigUI()
    local frame = self.configFrame
    if not frame then return end

    local db = SpiralStairsDB or defaults

    frame.radiusRow.slider:SetValue(db.radius)
    frame.heightRow.slider:SetValue(db.heightPerStep)
    frame.angleRow.slider:SetValue(db.anglePerStep)
    frame.stepsRow.slider:SetValue(db.numSteps)

    frame.centerXRow.editBox:SetText(string_format("%.2f", db.centerX))
    frame.centerYRow.editBox:SetText(string_format("%.2f", db.centerY))
    frame.centerZRow.editBox:SetText(string_format("%.2f", db.centerZ))

    frame.directionCheck:SetChecked(db.clockwise)
end

--- Toggle the config frame visibility
function SS:ToggleConfig()
    if not self.configFrame then
        local success, err = pcall(CreateConfigFrame)
        if not success then
            print("|cffff0000Error creating config frame: " .. tostring(err) .. "|r")
            return
        end
    end

    if self.configFrame:IsShown() then
        self.configFrame:Hide()
    else
        self:RefreshConfigUI()
        self.configFrame:Show()
    end
end

-- ============================================================================
-- Position Helpers
-- ============================================================================

--- Get player's current position
function SS:GetPlayerPosition()
    -- Try UnitPosition first (works in instances/housing)
    local y, x, z, instanceID = UnitPosition("player")
    if x and y then
        return x, y, z or 0
    end

    -- Fallback to map coordinates
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local px, py = pos:GetXY()
            return px * 100, py * 100, 0
        end
    end

    return nil
end

--- Create a simple preview indicator
function SS:ShowPreview()
    if #self.stairs == 0 then
        self:CalculateStairs()
    end

    print("|cff00ff00Spiral Staircase Preview:|r")
    print("The staircase will span from:")

    local firstStair = self.stairs[1]
    local lastStair = self.stairs[#self.stairs]
    local db = SpiralStairsDB or defaults

    if firstStair and lastStair then
        print(string_format("  Start: (%.2f, %.2f, %.2f)", firstStair.x, firstStair.y, firstStair.z))
        print(string_format("  End:   (%.2f, %.2f, %.2f)", lastStair.x, lastStair.y, lastStair.z))
        print(string_format("  Total Height: %.2f", lastStair.z - firstStair.z))
        print(string_format("  Total Rotation: %d°", (db.numSteps - 1) * db.anglePerStep))
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_SPIRALSTAIRS1 = "/stairs"
SLASH_SPIRALSTAIRS2 = "/spiral"
SLASH_SPIRALSTAIRS3 = "/ss"

SlashCmdList["SPIRALSTAIRS"] = function(msg)
    msg = msg or ""
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        SS:ToggleConfig()
    elseif cmd == "print" or cmd == "list" then
        SS:CalculateStairs()
        SS:PrintStairPositions()
    elseif cmd == "step" and arg ~= "" then
        local stepNum = tonumber(arg)
        if stepNum then
            SS:CalculateStairs()
            SS:PrintSingleStep(stepNum)
        else
            print("|cffff0000Usage: /stairs step <number>|r")
        end
    elseif cmd == "preview" then
        SS:CalculateStairs()
        SS:ShowPreview()
    elseif cmd == "setcenter" then
        local px, py, pz = SS:GetPlayerPosition()
        if px then
            SpiralStairsDB.centerX = px
            SpiralStairsDB.centerY = py
            SpiralStairsDB.centerZ = pz
            SS:CalculateStairs()
            print(string_format("|cff00ff00Center set to: (%.2f, %.2f, %.2f)|r", px, py, pz))
        else
            print("|cffff0000Could not get player position.|r")
        end
    elseif cmd == "radius" and arg ~= "" then
        local value = tonumber(arg)
        if value and value > 0 then
            SpiralStairsDB.radius = value
            SS:CalculateStairs()
            print(string_format("|cff00ff00Radius set to: %.2f|r", value))
        end
    elseif cmd == "height" and arg ~= "" then
        local value = tonumber(arg)
        if value and value > 0 then
            SpiralStairsDB.heightPerStep = value
            SS:CalculateStairs()
            print(string_format("|cff00ff00Height per step set to: %.2f|r", value))
        end
    elseif cmd == "angle" and arg ~= "" then
        local value = tonumber(arg)
        if value and value > 0 and value <= 180 then
            SpiralStairsDB.anglePerStep = value
            SS:CalculateStairs()
            print(string_format("|cff00ff00Angle per step set to: %d°|r", value))
        end
    elseif cmd == "steps" and arg ~= "" then
        local value = tonumber(arg)
        if value and value >= 2 and value <= 100 then
            SpiralStairsDB.numSteps = math_floor(value)
            SS:CalculateStairs()
            print(string_format("|cff00ff00Number of steps set to: %d|r", value))
        end
    elseif cmd == "cw" or cmd == "clockwise" then
        SpiralStairsDB.clockwise = true
        SS:CalculateStairs()
        print("|cff00ff00Direction set to clockwise.|r")
    elseif cmd == "ccw" or cmd == "counterclockwise" then
        SpiralStairsDB.clockwise = false
        SS:CalculateStairs()
        print("|cff00ff00Direction set to counter-clockwise.|r")
    elseif cmd == "help" then
        print("|cff00ff00=== Spiral Staircase Helper ===|r")
        print("|cffffcc00/stairs|r - Open config window")
        print("|cffffcc00/stairs print|r - Print all positions")
        print("|cffffcc00/stairs step <n>|r - Print step N position")
        print("|cffffcc00/stairs preview|r - Show preview info")
        print("|cffffcc00/stairs setcenter|r - Use player position")
        print("|cffffcc00/stairs radius <n>|r - Set radius")
        print("|cffffcc00/stairs height <n>|r - Set height/step")
        print("|cffffcc00/stairs angle <n>|r - Set angle/step")
        print("|cffffcc00/stairs steps <n>|r - Set num steps")
        print("|cffffcc00/stairs cw|ccw|r - Set direction")
    elseif cmd == "debug" then
        print("|cff00ff00Debug info:|r")
        print("SpiralStairsDB exists: " .. tostring(SpiralStairsDB ~= nil))
        print("Config frame exists: " .. tostring(SS.configFrame ~= nil))
        if SpiralStairsDB then
            print("Radius: " .. tostring(SpiralStairsDB.radius))
            print("Steps: " .. tostring(SpiralStairsDB.numSteps))
        end
    else
        print("|cffff0000Unknown command. Type /stairs help|r")
    end
end

-- ============================================================================
-- Addon Initialization
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize saved variables
        if not SpiralStairsDB then
            SpiralStairsDB = {}
        end

        -- Apply defaults for any missing values
        for k, v in pairs(defaults) do
            if SpiralStairsDB[k] == nil then
                SpiralStairsDB[k] = v
            end
        end

        -- Calculate initial stairs
        SS:CalculateStairs()

    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00Spiral Staircase Helper|r loaded. Type |cffffcc00/stairs|r for options.")
    end
end)
