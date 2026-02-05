-- Spiral Staircase Helper Addon
-- Helps calculate positions for building spiral staircases in WoW housing

local addonName, addon = ...

-- Configuration constants
local MIN_ROTATION = 45      -- Minimum total rotation in degrees
local MAX_ROTATION = 1080    -- Maximum total rotation in degrees (3 full rotations)

-- Saved variables defaults
local defaults = {
    radius = 3.0,           -- Distance from center to each stair
    heightPerStep = 0.5,    -- Height increase per step
    totalRotation = 360,    -- Total rotation from bottom to top (degrees)
    numSteps = 12,          -- Total number of stairs
    clockwise = true,       -- Direction of spiral
    buttonPos = nil,        -- Position of the Edit Mode button {point, x, y}
    selectedBeamIndex = 1,  -- Index of selected beam type
}

-- Beam platform items for building stairs
-- These are the 4 city-themed beam platforms available in WoW housing
local BEAM_TYPES = {
    { name = "Stormwind Beam Platform", itemID = 246244 },    -- Alliance - traditional, rustic
    { name = "Bel'ameth Beam Platform", itemID = 246254 },    -- Alliance - black, dark brown
    { name = "Silvermoon Beam Platform", itemID = 246249 },   -- Horde - dark gray, gray, tan
    { name = "Orgrimmar Beam Platform", itemID = 246259 },    -- Horde - orcish style
}

-- Spiral build mode state
local buildState = {
    active = false,         -- Whether spiral build mode is active
    currentStep = 1,        -- Current step being placed (1-based)
    lastRotation = 0,       -- Last rotation value applied
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

--- Calculate angle per step based on total rotation and number of steps
local function CalculateAnglePerStep(totalRotation, numSteps)
    -- For a single step, no rotation is needed
    if numSteps <= 1 then
        return 0
    end
    -- For multiple steps, distribute rotation across the intervals
    return totalRotation / (numSteps - 1)
end

--- Calculate all stair positions based on current settings
function SS:CalculateStairs()
    self.stairs = {}
    local db = SpiralStairsDB or defaults

    local direction = db.clockwise and 1 or -1
    local anglePerStep = CalculateAnglePerStep(db.totalRotation, db.numSteps)

    for i = 1, db.numSteps do
        local stepIndex = i - 1
        local angle = math_rad(stepIndex * anglePerStep * direction)

        local stair = {
            step = i,
            x = db.radius * math_cos(angle),
            y = db.radius * math_sin(angle),
            z = stepIndex * db.heightPerStep,
            rotation = (stepIndex * anglePerStep * direction) % 360,
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
    local anglePerStep = CalculateAnglePerStep(db.totalRotation, db.numSteps)

    print("|cff00ff00=== Spiral Staircase Positions ===|r")
    print(string_format("Radius: %.2f | Height/Step: %.2f | Total Rotation: %d°",
        db.radius, db.heightPerStep, db.totalRotation))
    print(string_format("Angle/Step: %.2f° | Direction: %s | Steps: %d",
        anglePerStep, db.clockwise and "Clockwise" or "Counter-clockwise", db.numSteps))
    print("|cff00ff00---------------------------------|r")

    for _, stair in ipairs(self.stairs) do
        print(string_format("|cffffcc00Step %2d:|r Rotation: %3d°",
            stair.step, stair.rotation))
    end

    print("|cff00ff00=================================|r")
end

--- Print position for a single step
function SS:PrintSingleStep(stepNum)
    local stair = self:GetStairPosition(stepNum)
    if stair then
        print(string_format("|cff00ff00Step %d:|r Rotation: %d°",
            stair.step, stair.rotation))
    else
        print("|cffff0000Invalid step number.|r")
    end
end

-- ============================================================================
-- Spiral Build Mode Functions
-- ============================================================================

--- Get the current rotation for the active step
function SS:GetCurrentStepRotation()
    if #self.stairs == 0 then
        self:CalculateStairs()
    end
    local stair = self.stairs[buildState.currentStep]
    if stair then
        return stair.rotation
    end
    return 0
end

--- Start spiral build mode
function SS:StartBuildMode()
    if buildState.active then
        print("|cffffcc00Spiral build mode is already active.|r")
        return
    end

    buildState.active = true
    buildState.currentStep = 1
    self:CalculateStairs()

    local rotation = self:GetCurrentStepRotation()
    buildState.lastRotation = rotation

    print("|cff00ff00Spiral build mode started!|r")
    print(string_format("|cffffcc00Step 1/%d:|r Set rotation to |cff00ffff%d°|r and place your item.",
        SpiralStairsDB.numSteps, rotation))

    self:UpdateBuildModeUI()
end

--- Stop spiral build mode
function SS:StopBuildMode()
    if not buildState.active then
        print("|cffffcc00Spiral build mode is not active.|r")
        return
    end

    buildState.active = false
    buildState.currentStep = 1

    print("|cff00ff00Spiral build mode stopped.|r")

    self:UpdateBuildModeUI()
end

--- Advance to the next step in build mode
function SS:AdvanceStep()
    if not buildState.active then
        print("|cffff0000Spiral build mode is not active. Use /stairs start|r")
        return
    end

    local db = SpiralStairsDB or defaults

    if buildState.currentStep >= db.numSteps then
        print("|cff00ff00All steps complete! Spiral staircase finished.|r")
        self:StopBuildMode()
        return
    end

    buildState.currentStep = buildState.currentStep + 1
    local rotation = self:GetCurrentStepRotation()
    buildState.lastRotation = rotation

    print(string_format("|cffffcc00Step %d/%d:|r Set rotation to |cff00ffff%d°|r and place your item.",
        buildState.currentStep, db.numSteps, rotation))

    self:UpdateBuildModeUI()
end

--- Go back to the previous step in build mode
function SS:PreviousStep()
    if not buildState.active then
        print("|cffff0000Spiral build mode is not active. Use /stairs start|r")
        return
    end

    if buildState.currentStep <= 1 then
        print("|cffffcc00Already at step 1.|r")
        return
    end

    buildState.currentStep = buildState.currentStep - 1
    local rotation = self:GetCurrentStepRotation()
    buildState.lastRotation = rotation

    local db = SpiralStairsDB or defaults
    print(string_format("|cffffcc00Step %d/%d:|r Set rotation to |cff00ffff%d°|r",
        buildState.currentStep, db.numSteps, rotation))

    self:UpdateBuildModeUI()
end

--- Update the build mode UI elements
function SS:UpdateBuildModeUI()
    if not self.configFrame then return end

    local frame = self.configFrame
    local db = SpiralStairsDB or defaults

    if buildState.active then
        if frame.buildStatusText then
            frame.buildStatusText:SetText(string_format(
                "|cff00ff00BUILDING|r - Step %d/%d\nRotation: |cff00ffff%d°|r",
                buildState.currentStep, db.numSteps, self:GetCurrentStepRotation()))
        end
        if frame.startBuildBtn then
            frame.startBuildBtn:SetText("Stop Building")
        end
        if frame.nextStepBtn then
            frame.nextStepBtn:Enable()
        end
        if frame.prevStepBtn then
            frame.prevStepBtn:Enable()
        end
    else
        if frame.buildStatusText then
            frame.buildStatusText:SetText("|cff888888Not building|r\nPress Start to begin")
        end
        if frame.startBuildBtn then
            frame.startBuildBtn:SetText("Start Building")
        end
        if frame.nextStepBtn then
            frame.nextStepBtn:Disable()
        end
        if frame.prevStepBtn then
            frame.prevStepBtn:Disable()
        end
    end
end

--- Check if build mode is active
function SS:IsBuildModeActive()
    return buildState.active
end

--- Get current build state
function SS:GetBuildState()
    return buildState
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
    slider:SetSize(120, 17)
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

local function CreateDropdown(parent, name, width)
    local dropdown = CreateFrame("Frame", name, parent, "BackdropTemplate")
    dropdown:SetSize(width or 150, 25)

    dropdown:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    -- Selected text display
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    selectedText:SetPoint("LEFT", 10, 0)
    selectedText:SetPoint("RIGHT", -25, 0)
    selectedText:SetJustifyH("LEFT")
    dropdown.selectedText = selectedText

    -- Dropdown arrow button
    local arrowBtn = CreateFrame("Button", nil, dropdown)
    arrowBtn:SetSize(20, 20)
    arrowBtn:SetPoint("RIGHT", -3, 0)
    arrowBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrowBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    arrowBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    -- Dropdown menu frame
    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    menuFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    menuFrame:Hide()
    dropdown.menuFrame = menuFrame

    dropdown.items = {}
    dropdown.selectedIndex = 1
    dropdown.OnSelectCallback = nil

    function dropdown:SetItems(items)
        -- Clear existing items
        for _, item in ipairs(self.items) do
            item:Hide()
            item:SetParent(nil)
        end
        self.items = {}

        local yOffset = -5
        for i, itemData in ipairs(items) do
            local itemBtn = CreateFrame("Button", nil, menuFrame)
            itemBtn:SetSize(width - 10, 20)
            itemBtn:SetPoint("TOPLEFT", 5, yOffset)

            local itemText = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            itemText:SetPoint("LEFT", 5, 0)
            itemText:SetText(itemData.name)
            itemBtn.text = itemText

            itemBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

            itemBtn:SetScript("OnClick", function()
                self.selectedIndex = i
                self.selectedText:SetText(itemData.name)
                menuFrame:Hide()
                if self.OnSelectCallback then
                    self.OnSelectCallback(i, itemData)
                end
            end)

            table.insert(self.items, itemBtn)
            yOffset = yOffset - 20
        end

        menuFrame:SetHeight(math.abs(yOffset) + 10)

        -- Set initial selection
        if items[self.selectedIndex] then
            self.selectedText:SetText(items[self.selectedIndex].name)
        end
    end

    function dropdown:SetSelectedIndex(index)
        self.selectedIndex = index
        if BEAM_TYPES[index] then
            self.selectedText:SetText(BEAM_TYPES[index].name)
        end
    end

    -- Toggle menu on click
    local function ToggleMenu()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end

    arrowBtn:SetScript("OnClick", ToggleMenu)
    dropdown:SetScript("OnMouseDown", ToggleMenu)

    -- Close menu when clicking elsewhere
    menuFrame:SetScript("OnShow", function()
        menuFrame:SetFrameLevel(dropdown:GetFrameLevel() + 10)
    end)

    return dropdown
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
    frame:SetSize(320, 420)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

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

        -- Create an editable EditBox instead of a FontString
        local valueBox = CreateEditBox(frame, nil, 45)
        valueBox:SetPoint("LEFT", slider, "RIGHT", 8, 0)
        
        -- Flag to prevent infinite update loops
        local updatingFromSlider = false
        local updatingFromEditBox = false

        -- Helper function to validate and apply value from edit box
        local function ValidateAndApplyValue()
            if updatingFromSlider then return end
            updatingFromEditBox = true
            
            local value = tonumber(valueBox:GetText())
            if value then
                -- Clamp value to min/max range
                if value < minVal then
                    value = minVal
                elseif value > maxVal then
                    value = maxVal
                end
                
                if isInteger then
                    value = math_floor(value + 0.5)
                end
                
                SpiralStairsDB[dbKey] = value
                slider:SetValue(value)
                
                if isInteger then
                    valueBox:SetText(string_format("%d", value))
                else
                    valueBox:SetText(string_format("%.1f", value))
                end
                SS:CalculateStairs()
            else
                -- Invalid input, revert to current value
                local currentValue = SpiralStairsDB[dbKey]
                if isInteger then
                    valueBox:SetText(string_format("%d", currentValue))
                else
                    valueBox:SetText(string_format("%.1f", currentValue))
                end
            end
            
            updatingFromEditBox = false
        end

        slider:SetScript("OnValueChanged", function(self, value)
            if updatingFromEditBox then return end
            updatingFromSlider = true
            
            if isInteger then
                value = math_floor(value + 0.5)
            end
            SpiralStairsDB[dbKey] = value
            if isInteger then
                valueBox:SetText(string_format("%d", value))
            else
                valueBox:SetText(string_format("%.1f", value))
            end
            SS:CalculateStairs()
            
            updatingFromSlider = false
        end)

        -- Handle Enter key press in edit box
        valueBox:SetScript("OnEnterPressed", function(self)
            ValidateAndApplyValue()
            self:ClearFocus()
        end)

        -- Handle Escape key press in edit box
        valueBox:SetScript("OnEscapePressed", function(self)
            local currentValue = SpiralStairsDB[dbKey]
            if isInteger then
                self:SetText(string_format("%d", currentValue))
            else
                self:SetText(string_format("%.1f", currentValue))
            end
            self:ClearFocus()
        end)
        
        -- Handle focus loss
        valueBox:SetScript("OnEditFocusLost", function(self)
            ValidateAndApplyValue()
        end)

        yOffset = yOffset - 35

        return { slider = slider, valueBox = valueBox, dbKey = dbKey, isInteger = isInteger }
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
    frame.rotationRow = CreateSliderRow("Total Rotation:", "totalRotation", MIN_ROTATION, MAX_ROTATION, MIN_ROTATION, true)
    frame.stepsRow = CreateSliderRow("Num Steps:", "numSteps", 2, 36, 1, true)

    -- Direction checkbox
    yOffset = yOffset - 10
    local dirCheck = CreateCheckbox(frame, nil, "Clockwise Direction")
    dirCheck:SetPoint("TOPLEFT", 20, yOffset)
    dirCheck:SetScript("OnClick", function(self)
        SpiralStairsDB.clockwise = self:GetChecked()
        SS:CalculateStairs()
    end)
    frame.directionCheck = dirCheck
    yOffset = yOffset - 35

    -- Buttons
    local resetBtn = CreateButton(frame, nil, "Reset Defaults", 280, 24)
    resetBtn:SetPoint("TOPLEFT", 20, yOffset)
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(defaults) do
            SpiralStairsDB[k] = v
        end
        SS:RefreshConfigUI()
        SS:CalculateStairs()
        print("|cff00ff00Settings reset to defaults.|r")
    end)

    yOffset = yOffset - 30

    local printBtn = CreateButton(frame, nil, "Print Positions", 280, 24)
    printBtn:SetPoint("TOPLEFT", 20, yOffset)
    printBtn:SetScript("OnClick", function()
        SS:PrintStairPositions()
    end)
    
    -- Add tooltip to Print Positions button
    printBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Print Positions", 1, 1, 1)
        GameTooltip:AddLine("Outputs all staircase configuration and positions to chat.", nil, nil, nil, true)
        GameTooltip:AddLine(" ", nil, nil, nil, true)
        GameTooltip:AddLine("Height/Step: The vertical distance (Z) that each step rises from the previous one.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    printBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    yOffset = yOffset - 35

    -- Separator line
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", 15, yOffset)
    separator:SetPoint("TOPRIGHT", -15, yOffset)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 10

    -- Build Mode Section Title
    local buildTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildTitle:SetPoint("TOPLEFT", 20, yOffset)
    buildTitle:SetText("|cff00ff00Spiral Build Mode|r")
    yOffset = yOffset - 25

    -- Beam Type Dropdown
    local beamLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    beamLabel:SetPoint("TOPLEFT", 20, yOffset)
    beamLabel:SetText("Beam Type:")

    local beamDropdown = CreateDropdown(frame, "SpiralStairsBeamDropdown", 170)
    beamDropdown:SetPoint("TOPLEFT", 110, yOffset + 3)
    beamDropdown:SetItems(BEAM_TYPES)
    beamDropdown:SetSelectedIndex(SpiralStairsDB.selectedBeamIndex or 1)
    beamDropdown.OnSelectCallback = function(index, itemData)
        SpiralStairsDB.selectedBeamIndex = index
    end
    frame.beamDropdown = beamDropdown
    yOffset = yOffset - 35

    -- Build status display
    local buildStatusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildStatusText:SetPoint("TOPLEFT", 20, yOffset)
    buildStatusText:SetText("|cff888888Not building|r\nPress Start to begin")
    buildStatusText:SetJustifyH("LEFT")
    frame.buildStatusText = buildStatusText
    yOffset = yOffset - 40

    -- Start/Stop Build button
    local startBuildBtn = CreateButton(frame, nil, "Start Building", 135, 24)
    startBuildBtn:SetPoint("TOPLEFT", 20, yOffset)
    startBuildBtn:SetScript("OnClick", function()
        if buildState.active then
            SS:StopBuildMode()
        else
            SS:StartBuildMode()
        end
    end)
    frame.startBuildBtn = startBuildBtn

    -- Next Step button
    local nextStepBtn = CreateButton(frame, nil, "Next Step →", 125, 24)
    nextStepBtn:SetPoint("TOPLEFT", 165, yOffset)
    nextStepBtn:SetScript("OnClick", function()
        SS:AdvanceStep()
    end)
    nextStepBtn:Disable()
    frame.nextStepBtn = nextStepBtn
    yOffset = yOffset - 28

    -- Previous Step button
    local prevStepBtn = CreateButton(frame, nil, "← Prev Step", 125, 24)
    prevStepBtn:SetPoint("TOPLEFT", 165, yOffset)
    prevStepBtn:SetScript("OnClick", function()
        SS:PreviousStep()
    end)
    prevStepBtn:Disable()
    frame.prevStepBtn = prevStepBtn

    frame:Hide()
    SS.configFrame = frame
    return frame
end

--- Refresh the config UI with current values
function SS:RefreshConfigUI()
    local frame = self.configFrame
    if not frame then return end

    local db = SpiralStairsDB or defaults

    -- Update sliders and their associated edit boxes
    frame.radiusRow.slider:SetValue(db.radius)
    frame.radiusRow.valueBox:SetText(string_format("%.1f", db.radius))
    
    frame.heightRow.slider:SetValue(db.heightPerStep)
    frame.heightRow.valueBox:SetText(string_format("%.1f", db.heightPerStep))
    
    frame.rotationRow.slider:SetValue(db.totalRotation)
    frame.rotationRow.valueBox:SetText(string_format("%d", db.totalRotation))
    
    frame.stepsRow.slider:SetValue(db.numSteps)
    frame.stepsRow.valueBox:SetText(string_format("%d", db.numSteps))

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
-- Edit Mode Button
-- ============================================================================

--- Create the Edit Mode button that opens the config window
local function CreateEditModeButton()
    -- Create a movable button frame
    local button = CreateFrame("Button", "SpiralStairsEditModeButton", UIParent, "UIPanelButtonTemplate")
    button:SetSize(120, 30)
    button:SetText("Stairs Helper")
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:SetFrameStrata("HIGH")
    button:SetClampedToScreen(true)
    
    -- Set initial position
    if SpiralStairsDB.buttonPos and SpiralStairsDB.buttonPos.point and
       SpiralStairsDB.buttonPos.x ~= nil and SpiralStairsDB.buttonPos.y ~= nil then
        button:ClearAllPoints()
        button:SetPoint(SpiralStairsDB.buttonPos.point, UIParent, SpiralStairsDB.buttonPos.point, 
                       SpiralStairsDB.buttonPos.x, SpiralStairsDB.buttonPos.y)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
    
    -- Drag handlers
    button:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position: GetPoint returns (point, relativeTo, relativePoint, x, y)
        local point, _, _, x, y = self:GetPoint()
        SpiralStairsDB.buttonPos = { point = point, x = x, y = y }
    end)
    
    -- Click handler to open config window
    button:SetScript("OnClick", function()
        SS:ToggleConfig()
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Spiral Staircase Helper", 1, 1, 1)
        -- AddLine parameters: text, r, g, b, wrap
        GameTooltip:AddLine("Click to open configuration window", nil, nil, nil, true)
        GameTooltip:AddLine("Drag to move this button", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Initially hidden
    button:Hide()
    
    SS.editModeButton = button
    return button
end

-- ============================================================================
-- Position Helpers
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
    local db = SpiralStairsDB or defaults

    if firstStair and lastStair then
        print(string_format("  Start: (%.2f, %.2f, %.2f)", firstStair.x, firstStair.y, firstStair.z))
        print(string_format("  End:   (%.2f, %.2f, %.2f)", lastStair.x, lastStair.y, lastStair.z))
        print(string_format("  Total Height: %.2f", lastStair.z - firstStair.z))
        print(string_format("  Total Rotation: %d°", db.totalRotation))
    end
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Initialize or ensure SpiralStairsDB is set up with defaults
local function InitializeDatabase()
    if not SpiralStairsDB then
        SpiralStairsDB = {}
    end
    
    -- Apply defaults for any missing values
    for k, v in pairs(defaults) do
        if SpiralStairsDB[k] == nil then
            SpiralStairsDB[k] = v
        end
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_SPIRALSTAIRS1 = "/stairs"
SLASH_SPIRALSTAIRS2 = "/spiral"
SLASH_SPIRALSTAIRS3 = "/ss"

SlashCmdList["SPIRALSTAIRS"] = function(msg)
    -- Ensure SpiralStairsDB is initialized (safety check for edit mode or early command use)
    InitializeDatabase()
    
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
    elseif cmd == "rotation" and arg ~= "" then
        local value = tonumber(arg)
        if value and value >= MIN_ROTATION and value <= MAX_ROTATION then
            SpiralStairsDB.totalRotation = value
            SS:CalculateStairs()
            print(string_format("|cff00ff00Total rotation set to: %d°|r", value))
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
    elseif cmd == "start" or cmd == "begin" then
        SS:StartBuildMode()
    elseif cmd == "stop" or cmd == "end" then
        SS:StopBuildMode()
    elseif cmd == "next" or cmd == "n" then
        SS:AdvanceStep()
    elseif cmd == "prev" or cmd == "p" or cmd == "back" then
        SS:PreviousStep()
    elseif cmd == "help" then
        print("|cff00ff00=== Spiral Staircase Helper ===|r")
        print("|cffffcc00/stairs|r - Open config window")
        print("|cffffcc00/stairs print|r - Print all positions")
        print("|cffffcc00/stairs step <n>|r - Print step N position")
        print("|cffffcc00/stairs preview|r - Show preview info")
        print("|cffffcc00/stairs radius <n>|r - Set radius")
        print("|cffffcc00/stairs height <n>|r - Set height/step")
        print("|cffffcc00/stairs rotation <n>|r - Set total rotation (degrees)")
        print("|cffffcc00/stairs steps <n>|r - Set num steps")
        print("|cffffcc00/stairs cw|ccw|r - Set direction")
        print("|cff00ff00--- Build Mode ------|r")
        print("|cffffcc00/stairs start|r - Start spiral build mode")
        print("|cffffcc00/stairs stop|r - Stop spiral build mode")
        print("|cffffcc00/stairs next|r - Advance to next step")
        print("|cffffcc00/stairs prev|r - Go back to previous step")
        print("|cff00ff00--- Utility ------|r")
        print("|cffffcc00/stairs button|r - Toggle the helper button")
    elseif cmd == "button" or cmd == "show" then
        -- Manually toggle the edit mode button visibility
        if SS.editModeButton then
            if SS.editModeButton:IsShown() then
                SS.editModeButton:Hide()
                print("|cff00ff00Stairs Helper button hidden.|r")
            else
                SS.editModeButton:Show()
                print("|cff00ff00Stairs Helper button shown.|r")
            end
        else
            print("|cffff0000Button not created yet. Try reloading UI.|r")
        end
    elseif cmd == "debug" then
        print("|cff00ff00Debug info:|r")
        print("SpiralStairsDB exists: " .. tostring(SpiralStairsDB ~= nil))
        print("Config frame exists: " .. tostring(SS.configFrame ~= nil))
        print("Edit mode button exists: " .. tostring(SS.editModeButton ~= nil))
        if SS.editModeButton then
            print("Edit mode button shown: " .. tostring(SS.editModeButton:IsShown()))
        end
        if SpiralStairsDB then
            print("Radius: " .. tostring(SpiralStairsDB.radius))
            print("Steps: " .. tostring(SpiralStairsDB.numSteps))
            print("Total Rotation: " .. tostring(SpiralStairsDB.totalRotation))
        end
        -- Check for housing-related frames
        print("|cff00ff00Housing frames check:|r")
        local frameNames = {
            "HousingDecorFrame", "HousingDecorPlacementFrame", "PlayerHousingFrame",
            "HousingEditorFrame", "HousingUI", "DecorPlacementFrame",
            "HousingEditFrame", "HousingFrame", "DecorFrame"
        }
        for _, name in ipairs(frameNames) do
            local frame = _G[name]
            if frame then
                print("  " .. name .. ": |cff00ff00EXISTS|r (shown: " .. tostring(frame:IsShown()) .. ")")
            end
        end
        -- Check C_Housing API
        if C_Housing then
            print("C_Housing API: |cff00ff00Available|r")
        else
            print("C_Housing API: |cffff0000Not found|r")
        end
    else
        print("|cffff0000Unknown command. Type /stairs help|r")
    end
end

-- ============================================================================
-- Housing Edit Mode Detection
-- ============================================================================

-- Try to hook into Blizzard's housing UI frames
local function SetupHousingFrameHooks()
    -- List of possible Blizzard housing frame names to try
    local housingFrameNames = {
        "HousingDecorFrame",
        "HousingDecorPlacementFrame",
        "PlayerHousingFrame",
        "HousingEditorFrame",
        "HousingUI",
        "DecorPlacementFrame",
    }

    local hookedFrame = nil

    for _, frameName in ipairs(housingFrameNames) do
        local frame = _G[frameName]
        if frame then
            -- Found a housing frame, hook into its Show/Hide
            frame:HookScript("OnShow", function()
                if SS.editModeButton then
                    SS.editModeButton:Show()
                end
            end)
            frame:HookScript("OnHide", function()
                if SS.editModeButton then
                    SS.editModeButton:Hide()
                end
                if buildState.active then
                    SS:StopBuildMode()
                end
            end)
            hookedFrame = frameName
            break
        end
    end

    return hookedFrame
end

-- ============================================================================
-- Addon Initialization
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize saved variables
        InitializeDatabase()

        -- Calculate initial stairs
        SS:CalculateStairs()

        -- Create the Edit Mode button
        CreateEditModeButton()

        -- Try to hook into housing frames
        local hookedFrame = SetupHousingFrameHooks()
        if hookedFrame then
            -- Successfully hooked
        end

    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00Spiral Staircase Helper|r loaded. Type |cffffcc00/stairs|r or |cffffcc00/stairs button|r")

        -- Delayed attempt to hook housing frames (they might load later)
        C_Timer.After(2, function()
            SetupHousingFrameHooks()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Ensure addon is initialized when entering edit mode or any zone
        InitializeDatabase()

        -- Recalculate stairs to ensure data is fresh when zoning
        SS:CalculateStairs()

        -- Try to hook housing frames again (in case they weren't available before)
        C_Timer.After(1, function()
            SetupHousingFrameHooks()
        end)
    end
end)
