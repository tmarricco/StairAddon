-- Spiral Staircase Helper Addon
-- Helps calculate positions for building spiral staircases in WoW housing

local addonName, addon = ...

-- Configuration constants
local MIN_ROTATION = 45      -- Minimum total rotation in degrees
local MAX_ROTATION = 1080    -- Maximum total rotation in degrees (3 full rotations)
local FLOOR_HEIGHT = 6.0     -- Standard floor-to-floor height in housing units

-- Saved variables defaults
local defaults = {
    radius = 3.0,           -- Distance from center to each stair
    heightPerStep = 0.5,    -- Height increase per step
    totalRotation = 360,    -- Total rotation from bottom to top (degrees)
    numSteps = 12,          -- Total number of stairs
    clockwise = true,       -- Direction of spiral
    buttonPos = nil,        -- Position of the Edit Mode button {point, x, y}
    selectedBeamIndex = 1,  -- Index of selected beam type
    originalRotation = 0,   -- Original rotation of first beam when placed (degrees)
    stairStyle = 1,         -- Index of selected stair style (1 = Default, 2 = Gradual, 3 = Regal)
    activeTabPage = 1,      -- Which tab is currently active (1 = Stairway, 2 = Archway)
    bridgeSegmentCount = 8, -- Number of segments for archway bridge (2-24)
    archwayType = 1,        -- Index of selected archway type (1 = Human, 2 = Elven, 3 = Drawbridge)
}

-- Stair style definitions
-- Defines how beams are configured for different stair styles
-- All styles are calculated to reach FLOOR_HEIGHT (6.0 units) from one floor to the next
local STAIR_STYLES = {
    {
        name = "Default",
        description = "Standard stairs with 12 beams",
        numSteps = 12,
        heightPerStep = 0.5,  -- 12 * 0.5 = 6.0 (one floor)
    },
    {
        name = "Gradual",
        description = "Gradual stairs with 16 beams and overlap",
        numSteps = 16,
        heightPerStep = 0.375,  -- 16 * 0.375 = 6.0 (one floor), beams overlap by 25%
    },
    {
        name = "Regal",
        description = "Regal stairs with 24 beams at 75% tread depth",
        numSteps = 24,
        heightPerStep = 0.25,  -- 24 * 0.25 = 6.0 (one floor), 75% visible tread
    },
}

-- Archway type definitions
-- Defines different archway path shapes for bridge construction
local ARCHWAY_TYPES = {
    {
        name = "Human",
        description = "Gradual archway above grade (180° arc)",
    },
    {
        name = "Elven",
        description = "First 15% and last 15% level with gradual dome in middle",
    },
    {
        name = "Regal",
        description = "Gradual archway with sharp peak at center",
    },
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
local math_pi = math.pi
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

--- Apply stair style settings to override numSteps and heightPerStep
--- @param styleIndex number The index of the stair style (1-3)
function SS:ApplyStairStyle(styleIndex)
    local db = SpiralStairsDB or defaults
    
    -- Ensure styleIndex is valid
    if styleIndex < 1 or styleIndex > #STAIR_STYLES then
        styleIndex = 1  -- Default to Default style
    end
    
    local style = STAIR_STYLES[styleIndex]
    
    -- Override numSteps and heightPerStep based on selected style
    db.numSteps = style.numSteps
    db.heightPerStep = style.heightPerStep
    db.stairStyle = styleIndex
    
    -- Refresh UI if it exists
    if self.configFrame and self.configFrame:IsShown() then
        self:RefreshConfigUI()
    end
end

--- Calculate all stair positions based on current settings
function SS:CalculateStairs()
    self.stairs = {}
    local db = SpiralStairsDB or defaults

    local direction = db.clockwise and 1 or -1
    local anglePerStep = CalculateAnglePerStep(db.totalRotation, db.numSteps)
    local originalRotation = db.originalRotation or 0

    for i = 1, db.numSteps do
        local stepIndex = i - 1
        local angle = math_rad(stepIndex * anglePerStep * direction)
        
        -- Calculate rotation relative to original rotation
        local relativeRotation = stepIndex * anglePerStep * direction
        local absoluteRotation = (originalRotation + relativeRotation) % 360

        local stair = {
            step = i,
            x = db.radius * math_cos(angle),
            y = db.radius * math_sin(angle),
            z = stepIndex * db.heightPerStep,
            rotation = absoluteRotation,
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

local function CreateStairStyleRow(parent, yPos)
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 20, yPos)
    labelText:SetText("Stair Style:")
    labelText:SetWidth(100)
    labelText:SetJustifyH("LEFT")
    
    -- Create dropdown menu
    local dropdown = CreateFrame("Frame", "SpiralStairsStyleDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 110, yPos + 5)
    UIDropDownMenu_SetWidth(dropdown, 180)
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for i, style in ipairs(STAIR_STYLES) do
            info.text = style.name
            info.value = i
            info.func = function()
                SS:ApplyStairStyle(i)
                SS:CalculateStairs()
                UIDropDownMenu_SetSelectedValue(dropdown, i)
            end
            info.checked = (SpiralStairsDB.stairStyle == i)
            
            -- Add tooltip info
            info.tooltipTitle = style.name
            info.tooltipText = style.description .. "\n\nSteps: " .. style.numSteps .. "\nHeight/Step: " .. string_format("%.2f", style.heightPerStep)
            info.tooltipOnButton = true
            
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial selection
    UIDropDownMenu_SetSelectedValue(dropdown, SpiralStairsDB.stairStyle or 1)
    
    return dropdown
end

local function CreateArchwayTypeRow(parent, yPos)
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 20, yPos)
    labelText:SetText("Archway Type:")
    labelText:SetWidth(100)
    labelText:SetJustifyH("LEFT")
    
    -- Create dropdown menu
    local dropdown = CreateFrame("Frame", "SpiralStairsArchwayTypeDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 110, yPos + 5)
    UIDropDownMenu_SetWidth(dropdown, 180)
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for i, archType in ipairs(ARCHWAY_TYPES) do
            info.text = archType.name
            info.value = i
            info.func = function()
                SpiralStairsDB.archwayType = i
                UIDropDownMenu_SetSelectedValue(dropdown, i)
                

            end
            info.checked = (SpiralStairsDB.archwayType == i)
            
            -- Add tooltip info
            info.tooltipTitle = archType.name
            info.tooltipText = archType.description
            info.tooltipOnButton = true
            
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial selection
    UIDropDownMenu_SetSelectedValue(dropdown, SpiralStairsDB.archwayType or 1)
    
    return dropdown
end

--- Calculate Y-axis rotation angles for archway bridge segments
--- @param segmentCount number Number of segments (2-24)
--- @param archwayType number Type of archway (1=Human, 2=Elven, 3=Drawbridge)
local function ComputeBridgeAngles(segmentCount, archwayType)
    local angles = {}
    if segmentCount < 2 then
        return angles
    end
    
    archwayType = archwayType or 1  -- Default to Human
    
    if archwayType == 1 then
        -- Human: Standard 180-degree arc
        local totalArc = 180
        local angleIncrement = totalArc / (segmentCount - 1)
        
        for i = 1, segmentCount do
            -- Start at 0 (left side), end at 180 (right side)
            local angle = (i - 1) * angleIncrement
            angles[i] = angle
        end
        
    elseif archwayType == 2 then
        -- Elven: Gradual dome with flat 15% at each end
        local flatPercent = 0.15
        
        for i = 1, segmentCount do
            local normalizedPos = (i - 1) / (segmentCount - 1)  -- 0 to 1
            
            if normalizedPos <= flatPercent then
                -- First 15%: flat (90 degrees - horizontal)
                angles[i] = 90
            elseif normalizedPos >= (1 - flatPercent) then
                -- Last 15%: flat (90 degrees - horizontal)
                angles[i] = 90
            else
                -- Middle 70%: gradual dome shape
                -- Map to 0-1 range for the curved section
                local curvePos = (normalizedPos - flatPercent) / (1 - 2 * flatPercent)
                -- Use sine curve for smooth dome (90° at edges, peaks at 120° at center)
                local angle = 90 + math_sin(curvePos * math_pi) * 30  -- 90° base + max 30° at center
                angles[i] = angle
            end
        end
        
    elseif archwayType == 3 then
        -- Regal: Gradual archway with sharp peak at center
        -- Creates a pointed/Gothic arch with cubic easing for sharp peak
        for i = 1, segmentCount do
            local normalizedPos = (i - 1) / (segmentCount - 1)  -- 0 to 1
            
            if normalizedPos <= 0.5 then
                -- Left side: gradual rise with acceleration toward center
                local leftProgress = normalizedPos * 2  -- Map 0-0.5 to 0-1
                -- Use cubic easing for gradual start, sharp approach to peak
                local angle = 0 + (180 * leftProgress * leftProgress * leftProgress)
                angles[i] = angle
            else
                -- Right side: mirror with sharp descent from peak
                local rightProgress = 1 - (normalizedPos - 0.5) * 2  -- Map 0.5-1 to 1-0
                -- Use cubic easing for sharp peak, gradual end
                local angle = 180 - (180 * rightProgress * rightProgress * rightProgress)
                angles[i] = angle
            end
        end
    end
    
    return angles
end

local function CreateConfigFrame()
    -- Main frame
    local frame = CreateFrame("Frame", "SpiralStairsConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(320, 450)
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
    title:SetText("Beam Builder Helper")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    local db = SpiralStairsDB or defaults
    
    -- Tab buttons
    local tabButtonWidth = 150
    local tabStairwayBtn = CreateButton(frame, nil, "Stairway", tabButtonWidth, 24)
    tabStairwayBtn:SetPoint("TOPLEFT", 10, -40)
    
    local tabArchwayBtn = CreateButton(frame, nil, "Archway", tabButtonWidth, 24)
    tabArchwayBtn:SetPoint("LEFT", tabStairwayBtn, "RIGHT", 10, 0)
    
    -- Container frames for each tab
    local stairwayContainer = CreateFrame("Frame", nil, frame)
    stairwayContainer:SetPoint("TOPLEFT", 0, -70)
    stairwayContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local archwayContainer = CreateFrame("Frame", nil, frame)
    archwayContainer:SetPoint("TOPLEFT", 0, -70)
    archwayContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Function to switch tabs
    local function SwitchToTab(tabIndex)
        SpiralStairsDB.activeTabPage = tabIndex
        
        if tabIndex == 1 then
            stairwayContainer:Show()
            archwayContainer:Hide()
            tabStairwayBtn:Disable()
            tabArchwayBtn:Enable()
        else
            stairwayContainer:Hide()
            archwayContainer:Show()
            tabStairwayBtn:Enable()
            tabArchwayBtn:Disable()
        end
    end
    
    tabStairwayBtn:SetScript("OnClick", function() SwitchToTab(1) end)
    tabArchwayBtn:SetScript("OnClick", function() SwitchToTab(2) end)
    
    frame.tabStairwayBtn = tabStairwayBtn
    frame.tabArchwayBtn = tabArchwayBtn
    frame.stairwayContainer = stairwayContainer
    frame.archwayContainer = archwayContainer
    frame.switchToTabFunc = SwitchToTab

    -- ==========================
    -- STAIRWAY TAB CONTENT
    -- ==========================
    local yOffset = -5

    -- Add stair style selector
    frame.styleDropdown = CreateStairStyleRow(stairwayContainer, yOffset)
    yOffset = yOffset - 35

    -- Helper to create a labeled slider row
    local function CreateSliderRow(label, dbKey, minVal, maxVal, step, isInteger)
        local rowY = yOffset

        local labelText = stairwayContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("TOPLEFT", 20, rowY)
        labelText:SetText(label)
        labelText:SetWidth(100)
        labelText:SetJustifyH("LEFT")

        local slider = CreateSlider(stairwayContainer, nil, minVal, maxVal, step)
        slider:SetPoint("TOPLEFT", 125, rowY)

        -- Create an editable EditBox instead of a FontString
        local valueBox = CreateEditBox(stairwayContainer, nil, 45)
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
    frame.originalRotationRow = CreateSliderRow("Original Rotation:", "originalRotation", 0, 359, 1, true)

    -- Direction checkbox
    yOffset = yOffset - 10
    local dirCheck = CreateCheckbox(stairwayContainer, nil, "Clockwise Direction")
    dirCheck:SetPoint("TOPLEFT", 20, yOffset)
    dirCheck:SetScript("OnClick", function(self)
        SpiralStairsDB.clockwise = self:GetChecked()
        SS:CalculateStairs()
    end)
    frame.directionCheck = dirCheck
    yOffset = yOffset - 35

    -- Buttons
    local resetBtn = CreateButton(stairwayContainer, nil, "Reset Defaults", 280, 24)
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

    local printBtn = CreateButton(stairwayContainer, nil, "Print Steps", 280, 24)
    printBtn:SetPoint("TOPLEFT", 20, yOffset)
    printBtn:SetScript("OnClick", function()
        SS:PrintStairPositions()
    end)
    
    -- Add tooltip to Print Steps button
    printBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Print Steps", 1, 1, 1)
        GameTooltip:AddLine("Outputs all staircase configuration and positions to chat.", nil, nil, nil, true)
        GameTooltip:AddLine(" ", nil, nil, nil, true)
        GameTooltip:AddLine("Height/Step: The vertical distance (Z) that each step rises from the previous one.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    printBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- ==========================
    -- ARCHWAY TAB CONTENT
    -- ==========================
    local archwayYOffset = -5
    
    -- Archway Type dropdown
    local archwayTypeDropdown = CreateArchwayTypeRow(archwayContainer, archwayYOffset)
    frame.archwayTypeDropdown = archwayTypeDropdown
    
    archwayYOffset = archwayYOffset - 35
    
    -- Segment count slider
    local segmentLabel = archwayContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    segmentLabel:SetPoint("TOPLEFT", 20, archwayYOffset)
    segmentLabel:SetText("Bridge Segments:")
    segmentLabel:SetWidth(120)
    segmentLabel:SetJustifyH("LEFT")
    
    local segmentSlider = CreateSlider(archwayContainer, nil, 2, 24, 1)
    segmentSlider:SetPoint("TOPLEFT", 145, archwayYOffset)
    
    local segmentValueBox = CreateEditBox(archwayContainer, nil, 45)
    segmentValueBox:SetPoint("LEFT", segmentSlider, "RIGHT", 8, 0)
    
    local segmentUpdatingFromSlider = false
    local segmentUpdatingFromEditBox = false
    
    local function ValidateSegmentValue()
        if segmentUpdatingFromSlider then return end
        segmentUpdatingFromEditBox = true
        
        local value = tonumber(segmentValueBox:GetText())
        if value then
            if value < 2 then
                value = 2
            elseif value > 24 then
                value = 24
            end
            
            value = math_floor(value + 0.5)
            SpiralStairsDB.bridgeSegmentCount = value
            segmentSlider:SetValue(value)
            segmentValueBox:SetText(string_format("%d", value))
            

        else
            local currentValue = SpiralStairsDB.bridgeSegmentCount
            segmentValueBox:SetText(string_format("%d", currentValue))
        end
        
        segmentUpdatingFromEditBox = false
    end
    
    segmentSlider:SetScript("OnValueChanged", function(self, value)
        if segmentUpdatingFromEditBox then return end
        segmentUpdatingFromSlider = true
        
        value = math_floor(value + 0.5)
        SpiralStairsDB.bridgeSegmentCount = value
        segmentValueBox:SetText(string_format("%d", value))
        

        
        segmentUpdatingFromSlider = false
    end)
    
    segmentValueBox:SetScript("OnEnterPressed", function(self)
        ValidateSegmentValue()
        self:ClearFocus()
    end)
    
    segmentValueBox:SetScript("OnEscapePressed", function(self)
        local currentValue = SpiralStairsDB.bridgeSegmentCount
        self:SetText(string_format("%d", currentValue))
        self:ClearFocus()
    end)
    
    segmentValueBox:SetScript("OnEditFocusLost", function(self)
        ValidateSegmentValue()
    end)
    
    frame.segmentSlider = segmentSlider
    frame.segmentValueBox = segmentValueBox
    
    archwayYOffset = archwayYOffset - 35
    
    -- Reset Defaults button
    local resetArchwayBtn = CreateButton(archwayContainer, nil, "Reset Defaults", 280, 24)
    resetArchwayBtn:SetPoint("TOPLEFT", 20, archwayYOffset)
    resetArchwayBtn:SetScript("OnClick", function()
        -- Reset only archway-specific settings
        SpiralStairsDB.bridgeSegmentCount = defaults.bridgeSegmentCount
        SpiralStairsDB.archwayType = defaults.archwayType
        SS:RefreshConfigUI()
        print("|cff00ff00Archway settings reset to defaults.|r")
    end)
    
    archwayYOffset = archwayYOffset - 30
    
    -- Print Arches button
    local printArchesBtn = CreateButton(archwayContainer, nil, "Print Arches", 280, 24)
    printArchesBtn:SetPoint("TOPLEFT", 20, archwayYOffset)
    printArchesBtn:SetScript("OnClick", function()
        local count = SpiralStairsDB.bridgeSegmentCount or 8
        local archwayType = SpiralStairsDB.archwayType or 1
        local angles = ComputeBridgeAngles(count, archwayType)
        
        local typeName = ARCHWAY_TYPES[archwayType].name
        print("|cffffcc00Archway Bridge - Y-Axis Rotation Angles|r")
        print(string_format("Type: %s", typeName))
        print(string_format("Segments: %d", count))
        print("---")
        
        for i, angle in ipairs(angles) do
            print(string_format("Segment %d: |cff00ff00%.1f°|r", i, angle))
        end
    end)
    
    printArchesBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Print Arches", 1, 1, 1)
        GameTooltip:AddLine("Prints the rotation angles for each archway segment to the chat window.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    printArchesBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Initialize tab state
    SwitchToTab(db.activeTabPage or defaults.activeTabPage)

    frame:Hide()
    SS.configFrame = frame
    return frame
end

--- Refresh the config UI with current values
function SS:RefreshConfigUI()
    local frame = self.configFrame
    if not frame then return end

    local db = SpiralStairsDB or defaults

    -- Update style dropdown
    if frame.styleDropdown then
        local currentStyle = db.stairStyle or 1
        UIDropDownMenu_SetSelectedValue(frame.styleDropdown, currentStyle)
    end

    -- Update sliders and their associated edit boxes
    frame.radiusRow.slider:SetValue(db.radius)
    frame.radiusRow.valueBox:SetText(string_format("%.1f", db.radius))
    
    frame.heightRow.slider:SetValue(db.heightPerStep)
    frame.heightRow.valueBox:SetText(string_format("%.1f", db.heightPerStep))
    
    frame.rotationRow.slider:SetValue(db.totalRotation)
    frame.rotationRow.valueBox:SetText(string_format("%d", db.totalRotation))
    
    frame.stepsRow.slider:SetValue(db.numSteps)
    frame.stepsRow.valueBox:SetText(string_format("%d", db.numSteps))
    
    frame.originalRotationRow.slider:SetValue(db.originalRotation or 0)
    frame.originalRotationRow.valueBox:SetText(string_format("%d", db.originalRotation or 0))

    frame.directionCheck:SetChecked(db.clockwise)
    
    -- Update archway tab controls
    if frame.segmentSlider and frame.segmentValueBox then
        local segmentCount = db.bridgeSegmentCount or 8
        frame.segmentSlider:SetValue(segmentCount)
        frame.segmentValueBox:SetText(string_format("%d", segmentCount))
        

    end
    
    -- Update archway type dropdown
    if frame.archwayTypeDropdown then
        local currentType = db.archwayType or 1
        UIDropDownMenu_SetSelectedValue(frame.archwayTypeDropdown, currentType)
    end
    
    -- Update tab state
    if frame.switchToTabFunc then
        frame.switchToTabFunc(db.activeTabPage or defaults.activeTabPage)
    end
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
    elseif cmd == "original" and arg ~= "" then
        local value = tonumber(arg)
        if value then
            SpiralStairsDB.originalRotation = value % 360
            SS:CalculateStairs()
            print(string_format("|cff00ff00Original rotation set to: %d°|r", SpiralStairsDB.originalRotation))
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
    elseif cmd == "style" and arg ~= "" then
        local styleArg = arg:lower()
        local styleIndex = nil
        if styleArg == "default" or styleArg == "base" then
            styleIndex = 1
        elseif styleArg == "gradual" then
            styleIndex = 2
        elseif styleArg == "regal" then
            styleIndex = 3
        end
        
        if styleIndex then
            SS:ApplyStairStyle(styleIndex)
            SS:CalculateStairs()
            print(string_format("|cff00ff00Stair style set to: %s|r", STAIR_STYLES[styleIndex].name))
            print(string_format("  Steps: %d, Height/Step: %.2f", STAIR_STYLES[styleIndex].numSteps, STAIR_STYLES[styleIndex].heightPerStep))
        else
            print("|cffff0000Invalid style. Use: default, gradual, or regal|r")
        end
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
        print("|cffffcc00/stairs original <n>|r - Set original rotation (degrees)")
        print("|cffffcc00/stairs steps <n>|r - Set num steps")
        print("|cffffcc00/stairs cw|ccw|r - Set direction")
        print("|cffffcc00/stairs style <default|gradual|regal>|r - Set stair style")
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
