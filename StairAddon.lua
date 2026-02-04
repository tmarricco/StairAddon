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
    showMarkers = true,     -- Show visual markers
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
    local db = SpiralStairsDB

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
---@param stepNum number The step number (1-based)
---@return table|nil stair The stair position data or nil if invalid
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

    print("|cff00ff00=== Spiral Staircase Positions ===|r")
    print(string_format("Center: (%.2f, %.2f, %.2f)",
        SpiralStairsDB.centerX, SpiralStairsDB.centerY, SpiralStairsDB.centerZ))
    print(string_format("Radius: %.2f | Height/Step: %.2f | Angle/Step: %d°",
        SpiralStairsDB.radius, SpiralStairsDB.heightPerStep, SpiralStairsDB.anglePerStep))
    print(string_format("Direction: %s | Steps: %d",
        SpiralStairsDB.clockwise and "Clockwise" or "Counter-clockwise", SpiralStairsDB.numSteps))
    print("|cff00ff00---------------------------------|r")

    for _, stair in ipairs(self.stairs) do
        print(string_format("|cffffcc00Step %2d:|r X: %7.2f  Y: %7.2f  Z: %7.2f  Rot: %3d°",
            stair.step, stair.x, stair.y, stair.z, stair.rotation))
    end

    print("|cff00ff00=================================|r")
end

--- Print position for a single step
---@param stepNum number The step number to print
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
-- Configuration UI
-- ============================================================================

local function CreateConfigFrame()
    local frame = CreateFrame("Frame", "SpiralStairsConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(350, 420)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.TitleText:SetText("Spiral Staircase Helper")

    local yOffset = -35
    local labelWidth = 120
    local inputWidth = 80

    -- Helper function to create a slider
    local function CreateSliderRow(parent, label, minVal, maxVal, step, dbKey, yPos)
        local rowFrame = CreateFrame("Frame", nil, parent)
        rowFrame:SetSize(320, 40)
        rowFrame:SetPoint("TOPLEFT", 15, yPos)

        local text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        text:SetText(label)
        text:SetWidth(labelWidth)
        text:SetJustifyH("LEFT")

        local slider = CreateFrame("Slider", nil, rowFrame, "OptionsSliderTemplate")
        slider:SetPoint("LEFT", labelWidth + 10, 0)
        slider:SetWidth(120)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)

        slider.Low:SetText(tostring(minVal))
        slider.High:SetText(tostring(maxVal))

        local valueText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
        valueText:SetWidth(50)

        slider:SetScript("OnValueChanged", function(self, value)
            SpiralStairsDB[dbKey] = value
            if step >= 1 then
                valueText:SetText(string_format("%d", value))
            else
                valueText:SetText(string_format("%.1f", value))
            end
            SS:CalculateStairs()
        end)

        rowFrame.slider = slider
        rowFrame.valueText = valueText
        rowFrame.dbKey = dbKey

        return rowFrame
    end

    -- Helper function to create an input row
    local function CreateInputRow(parent, label, dbKey, yPos)
        local rowFrame = CreateFrame("Frame", nil, parent)
        rowFrame:SetSize(320, 30)
        rowFrame:SetPoint("TOPLEFT", 15, yPos)

        local text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        text:SetText(label)
        text:SetWidth(labelWidth)
        text:SetJustifyH("LEFT")

        local editBox = CreateFrame("EditBox", nil, rowFrame, "InputBoxTemplate")
        editBox:SetPoint("LEFT", labelWidth + 10, 0)
        editBox:SetSize(inputWidth, 20)
        editBox:SetAutoFocus(false)
        editBox:SetNumeric(false)

        editBox:SetScript("OnEnterPressed", function(self)
            local value = tonumber(self:GetText()) or 0
            SpiralStairsDB[dbKey] = value
            SS:CalculateStairs()
            self:ClearFocus()
        end)

        editBox:SetScript("OnEscapePressed", function(self)
            self:SetText(tostring(SpiralStairsDB[dbKey]))
            self:ClearFocus()
        end)

        rowFrame.editBox = editBox
        rowFrame.dbKey = dbKey

        return rowFrame
    end

    -- Create parameter controls
    frame.radiusSlider = CreateSliderRow(frame, "Radius:", 0.5, 10, 0.5, "radius", yOffset)
    yOffset = yOffset - 45

    frame.heightSlider = CreateSliderRow(frame, "Height/Step:", 0.1, 2.0, 0.1, "heightPerStep", yOffset)
    yOffset = yOffset - 45

    frame.angleSlider = CreateSliderRow(frame, "Angle/Step:", 5, 90, 5, "anglePerStep", yOffset)
    yOffset = yOffset - 45

    frame.stepsSlider = CreateSliderRow(frame, "Number of Steps:", 2, 36, 1, "numSteps", yOffset)
    yOffset = yOffset - 50

    -- Center coordinates
    local coordLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    coordLabel:SetPoint("TOPLEFT", 15, yOffset)
    coordLabel:SetText("|cff00ff00Center Coordinates:|r")
    yOffset = yOffset - 25

    frame.centerX = CreateInputRow(frame, "Center X:", "centerX", yOffset)
    yOffset = yOffset - 30

    frame.centerY = CreateInputRow(frame, "Center Y:", "centerY", yOffset)
    yOffset = yOffset - 30

    frame.centerZ = CreateInputRow(frame, "Center Z:", "centerZ", yOffset)
    yOffset = yOffset - 35

    -- Direction checkbox
    local directionCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    directionCheck:SetPoint("TOPLEFT", 15, yOffset)
    directionCheck.text:SetText("Clockwise Direction")
    directionCheck:SetScript("OnClick", function(self)
        SpiralStairsDB.clockwise = self:GetChecked()
        SS:CalculateStairs()
    end)
    frame.directionCheck = directionCheck
    yOffset = yOffset - 35

    -- Buttons
    local printButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    printButton:SetSize(140, 25)
    printButton:SetPoint("TOPLEFT", 15, yOffset)
    printButton:SetText("Print Positions")
    printButton:SetScript("OnClick", function()
        SS:PrintStairPositions()
    end)

    local usePlayerBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    usePlayerBtn:SetSize(140, 25)
    usePlayerBtn:SetPoint("TOPLEFT", 165, yOffset)
    usePlayerBtn:SetText("Use Player Position")
    usePlayerBtn:SetScript("OnClick", function()
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

    local copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyButton:SetSize(140, 25)
    copyButton:SetPoint("TOPLEFT", 15, yOffset)
    copyButton:SetText("Copy to Clipboard")
    copyButton:SetScript("OnClick", function()
        SS:CopyPositionsToClipboard()
    end)

    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(140, 25)
    resetButton:SetPoint("TOPLEFT", 165, yOffset)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function()
        for k, v in pairs(defaults) do
            SpiralStairsDB[k] = v
        end
        SS:RefreshConfigUI()
        SS:CalculateStairs()
        print("|cff00ff00Settings reset to defaults.|r")
    end)

    SS.configFrame = frame
    return frame
end

--- Refresh the config UI with current values
function SS:RefreshConfigUI()
    local frame = self.configFrame
    if not frame then return end

    local db = SpiralStairsDB

    frame.radiusSlider.slider:SetValue(db.radius)
    frame.heightSlider.slider:SetValue(db.heightPerStep)
    frame.angleSlider.slider:SetValue(db.anglePerStep)
    frame.stepsSlider.slider:SetValue(db.numSteps)

    frame.centerX.editBox:SetText(string_format("%.2f", db.centerX))
    frame.centerY.editBox:SetText(string_format("%.2f", db.centerY))
    frame.centerZ.editBox:SetText(string_format("%.2f", db.centerZ))

    frame.directionCheck:SetChecked(db.clockwise)
end

--- Toggle the config frame visibility
function SS:ToggleConfig()
    if not self.configFrame then
        CreateConfigFrame()
        self:RefreshConfigUI()
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
---@return number|nil x, number|nil y, number|nil z
function SS:GetPlayerPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end

    -- Note: In housing, you may need to use different APIs
    -- This provides map coordinates which may need conversion
    local x, y = pos:GetXY()

    -- Try to get the actual world position if available
    local _, _, _, instanceX, instanceY, _, _, _, _, _, _ = UnitPosition("player")
    if instanceX and instanceY then
        -- UnitPosition returns y, x in game coordinates
        return instanceX, instanceY, 0
    end

    return x * 100, y * 100, 0
end

--- Copy stair positions to an edit box for clipboard copying
function SS:CopyPositionsToClipboard()
    if #self.stairs == 0 then
        self:CalculateStairs()
    end

    local text = "Spiral Staircase Positions\n"
    text = text .. string_format("Center: (%.2f, %.2f, %.2f)\n",
        SpiralStairsDB.centerX, SpiralStairsDB.centerY, SpiralStairsDB.centerZ)
    text = text .. string_format("Radius: %.2f, Height/Step: %.2f, Angle: %d°, Steps: %d\n\n",
        SpiralStairsDB.radius, SpiralStairsDB.heightPerStep,
        SpiralStairsDB.anglePerStep, SpiralStairsDB.numSteps)

    for _, stair in ipairs(self.stairs) do
        text = text .. string_format("Step %d: X=%.2f, Y=%.2f, Z=%.2f, Rot=%d°\n",
            stair.step, stair.x, stair.y, stair.z, stair.rotation)
    end

    -- Create a copy dialog
    if not SS.copyFrame then
        local copyFrame = CreateFrame("Frame", "SpiralStairsCopyFrame", UIParent, "BasicFrameTemplateWithInset")
        copyFrame:SetSize(400, 300)
        copyFrame:SetPoint("CENTER")
        copyFrame:SetMovable(true)
        copyFrame:EnableMouse(true)
        copyFrame:RegisterForDrag("LeftButton")
        copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
        copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
        copyFrame.TitleText:SetText("Copy Positions (Ctrl+C)")

        local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetWidth(340)
        editBox:SetAutoFocus(true)
        editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)

        scrollFrame:SetScrollChild(editBox)
        copyFrame.editBox = editBox
        SS.copyFrame = copyFrame
    end

    SS.copyFrame.editBox:SetText(text)
    SS.copyFrame.editBox:HighlightText()
    SS.copyFrame:Show()
end

-- ============================================================================
-- Preview/Visualization (Optional - uses world markers if available)
-- ============================================================================

--- Create a simple preview indicator
function SS:ShowPreview()
    if #self.stairs == 0 then
        self:CalculateStairs()
    end

    print("|cff00ff00Spiral Staircase Preview:|r")
    print("The staircase will span from:")

    local firstStair = self.stairs[1]
    local lastStair = self.stairs[#self.stairs]

    if firstStair and lastStair then
        print(string_format("  Start: (%.2f, %.2f, %.2f)", firstStair.x, firstStair.y, firstStair.z))
        print(string_format("  End:   (%.2f, %.2f, %.2f)", lastStair.x, lastStair.y, lastStair.z))
        print(string_format("  Total Height: %.2f", lastStair.z - firstStair.z))
        print(string_format("  Total Rotation: %d°", (SpiralStairsDB.numSteps - 1) * SpiralStairsDB.anglePerStep))
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_SPIRALSTAIRS1 = "/stairs"
SLASH_SPIRALSTAIRS2 = "/spiral"
SLASH_SPIRALSTAIRS3 = "/ss"

SlashCmdList["SPIRALSTAIRS"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

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
    elseif cmd == "copy" then
        SS:CalculateStairs()
        SS:CopyPositionsToClipboard()
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
    elseif cmd == "clockwise" or cmd == "cw" then
        SpiralStairsDB.clockwise = true
        SS:CalculateStairs()
        print("|cff00ff00Direction set to clockwise.|r")
    elseif cmd == "counterclockwise" or cmd == "ccw" then
        SpiralStairsDB.clockwise = false
        SS:CalculateStairs()
        print("|cff00ff00Direction set to counter-clockwise.|r")
    elseif cmd == "help" then
        print("|cff00ff00=== Spiral Staircase Helper Commands ===|r")
        print("|cffffcc00/stairs|r or |cffffcc00/spiral|r or |cffffcc00/ss|r - Open config UI")
        print("|cffffcc00/stairs print|r - Print all stair positions")
        print("|cffffcc00/stairs step <num>|r - Print position for step #")
        print("|cffffcc00/stairs preview|r - Show staircase preview info")
        print("|cffffcc00/stairs copy|r - Copy positions to clipboard")
        print("|cffffcc00/stairs setcenter|r - Set center to player position")
        print("|cffffcc00/stairs radius <num>|r - Set radius")
        print("|cffffcc00/stairs height <num>|r - Set height per step")
        print("|cffffcc00/stairs angle <num>|r - Set angle per step (degrees)")
        print("|cffffcc00/stairs steps <num>|r - Set number of steps")
        print("|cffffcc00/stairs cw|r - Set clockwise direction")
        print("|cffffcc00/stairs ccw|r - Set counter-clockwise direction")
        print("|cff00ff00=========================================|r")
    else
        print("|cffff0000Unknown command. Use /stairs help for a list of commands.|r")
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
        print("|cff00ff00Spiral Staircase Helper|r loaded. Type |cffffcc00/stairs|r or |cffffcc00/ss|r for options.")
    end
end)
