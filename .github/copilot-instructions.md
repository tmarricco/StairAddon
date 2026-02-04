# World of Warcraft Addon Development Best Practices

This document outlines best practices for developing World of Warcraft addons using Lua and the WoW API.

## General Lua Coding Standards

### Variable Naming and Scope
- Use descriptive, meaningful variable names
- Prefix global variables with your addon name to avoid conflicts (e.g., `SpiralStairs`)
- Use local variables whenever possible for better performance and to avoid namespace pollution
- Local references to frequently used functions improve performance:
  ```lua
  local math_sin = math.sin
  local math_cos = math.cos
  local string_format = string.format
  ```

### Code Organization
- Keep addon code organized into logical sections with clear comments
- Use section headers with equals signs for major code blocks
- Group related functions together
- Place helper/utility functions before main functions that use them

### Comments and Documentation
- Use `---` for function documentation comments
- Document function parameters and return values
- Add inline comments for complex logic
- Include header comments explaining the purpose of major sections

## TOC File Structure

The `.toc` (Table of Contents) file is required for WoW to recognize your addon:

```lua
## Interface: 110100
## Title: Your Addon Name
## Notes: Brief description of what your addon does
## Author: Your Name
## Version: 1.0.0
## SavedVariables: YourAddonDB
## SavedVariablesPerCharacter: YourAddonDBChar

YourAddon.lua
```

Comments:
- Interface: Current WoW interface version (e.g., 110100 for 11.1.0)
- SavedVariables: Global saved variables persisted across all characters
- SavedVariablesPerCharacter: Per-character saved variables
- List all Lua and XML files in load order

### TOC Best Practices
- Keep the Interface version updated with each WoW patch
- Use semantic versioning (Major.Minor.Patch)
- List file loading order matters - load dependencies first
- Use descriptive titles and notes for user clarity

## Saved Variables and Data Persistence

### SavedVariables Pattern
```lua
-- Define defaults
local defaults = {
    setting1 = value1,
    setting2 = value2,
}

-- Initialize on ADDON_LOADED
function OnAddonLoaded()
    if not YourAddonDB then
        YourAddonDB = {}
    end
    
    -- Apply defaults for missing values
    for k, v in pairs(defaults) do
        if YourAddonDB[k] == nil then
            YourAddonDB[k] = v
        end
    end
end
```

### Best Practices
- Always initialize SavedVariables before use
- Provide sensible defaults
- Use nil checks before accessing saved data
- Don't store temporary/calculated data in SavedVariables
- Keep saved data structures simple for forward compatibility

## Event Handling

### Event Frame Pattern
```lua
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize addon
    elseif event == "PLAYER_LOGIN" then
        -- Perform actions after player is fully loaded
    end
end)
```

### Event Best Practices
- Only register events you actually need
- Unregister events when no longer needed to save CPU
- Use ADDON_LOADED to initialize your specific addon only: `if arg1 == addonName`
- Use PLAYER_LOGIN for actions that need the player to be fully loaded
- Check for nil values when accessing event arguments

## UI and Frame Creation

### Modern Backdrop API
WoW 9.0+ requires explicit use of BackdropTemplate:
```lua
local frame = CreateFrame("Frame", "FrameName", parent, "BackdropTemplate")

-- Check if SetBackdrop exists (API changes)
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
```

### Frame Creation Best Practices
- Always specify BackdropTemplate for frames that use backdrops
- Use templates when available (UIPanelButtonTemplate, etc.)
- Set frame strata appropriately (BACKGROUND, LOW, MEDIUM, HIGH, DIALOG, FULLSCREEN)
- Make frames movable with drag handlers for better UX
- Add close buttons to dialog frames
- Use FontStrings for text display, not EditBox unless input is needed

### UI Element Sizing
- Use consistent sizing for buttons and controls
- Standard button height is 22-24 pixels
- Leave adequate spacing between UI elements (30-35 pixels vertically)
- Make clickable areas large enough (minimum 20x20 for checkboxes)

## WoW API Usage

### Common API Patterns

#### Position and Coordinates
```lua
-- Get player position (works in instances/housing)
local y, x, z, instanceID = UnitPosition("player")

-- Fallback to map coordinates
local mapID = C_Map.GetBestMapForUnit("player")
if mapID then
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        local px, py = pos:GetXY()
    end
end
```

#### Safe API Calls
- Always check if API functions exist before calling: `if C_Map and C_Map.GetBestMapForUnit then`
- Provide fallback behavior for older API versions
- Use pcall() for operations that might fail: `local success, result = pcall(functionCall)`

### Color Codes
Use WoW color codes in strings for colored text:
```lua
"|cffRRGGBB text |r"  -- RRGGBB is hex color, |r resets color
"|cff00ff00Success!|r"  -- Green
"|cffff0000Error!|r"    -- Red
"|cffffcc00Warning|r"   -- Yellow/Gold
```

Common colors:
- Green (success): `|cff00ff00`
- Red (error): `|cffff0000`
- Yellow/Gold (highlight): `|cffffcc00`
- Blue: `|cff0000ff`

## Slash Commands

### Slash Command Registration
```lua
SLASH_YOURADDON1 = "/command1"
SLASH_YOURADDON2 = "/command2"  -- Alternative commands
SLASH_YOURADDON3 = "/shortcut"

SlashCmdList["YOURADDON"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    
    if cmd == "" or cmd == "help" then
        -- Show help
    elseif cmd == "option" and arg ~= "" then
        -- Handle option with argument
    end
end
```

### Slash Command Best Practices
- Provide multiple command aliases for user convenience
- Include a help command that lists all available commands
- Validate and sanitize user input
- Provide clear error messages for invalid commands
- Use pattern matching to parse commands and arguments
- Convert commands to lowercase for case-insensitive matching

## Performance Considerations

### Optimization Tips
1. **Cache Frequently Used Values**
   ```lua
   local math_floor = math.floor
   local string_format = string.format
   ```

2. **Minimize Global Lookups**
   - Store references to frequently accessed globals
   - Use local variables inside loops

3. **Efficient Table Operations**
   ```lua
   -- Pre-size tables when possible
   local myTable = {}
   for i = 1, numItems do
       table.insert(myTable, item)
   end
   ```

4. **Avoid Unnecessary Recalculations**
   - Cache calculated values when inputs haven't changed
   - Use OnValueChanged callbacks efficiently

5. **String Concatenation**
   - Use `string.format()` instead of multiple concatenations
   - Build large strings with table.concat() for efficiency

### Frame and Event Performance
- Unregister events when not needed
- Use OnUpdate sparingly; prefer events when possible
- Set OnUpdate intervals when using it: `frame:SetScript("OnUpdate", function(self, elapsed) ... end)`
- Limit the frequency of expensive operations

## Compatibility Across WoW Versions

### API Compatibility Checks
Always check for API existence before use:
```lua
-- Check namespace
if C_Map and C_Map.GetPlayerMapPosition then
    -- Use new API
else
    -- Use fallback or old API
end

-- Check for frame methods
if frame.SetBackdrop then
    frame:SetBackdrop(backdropTable)
end
```

### Version-Specific Code
- Use the Interface version to conditionally execute code
- Test addons across different WoW versions (Classic, Retail)
- Keep compatibility layers minimal and well-documented
- Document which WoW versions your addon supports

## Error Handling

### Protected Calls
```lua
local success, err = pcall(function()
    -- Risky operation
    CreateSomeFrame()
end)

if not success then
    print("|cffff0000Error: " .. tostring(err) .. "|r")
    -- Provide fallback behavior
end
```

### Validation
- Validate user input before processing
- Check for nil values before using API results
- Provide sensible defaults for missing or invalid data
- Show user-friendly error messages

## Addon Namespace Pattern

Use the vararg pattern to create addon namespaces:
```lua
local addonName, addon = ...

-- Create global namespace if needed for external access
YourAddon = {}
local YA = YourAddon  -- Local reference for internal use

-- Store addon data in namespace
YA.version = "1.0.0"
YA.data = {}
```

Benefits:
- Reduces global namespace pollution
- Provides clear addon boundaries
- Makes code more modular and maintainable

## Testing and Debugging

### Debug Helpers
```lua
-- Debug print function
local function DebugPrint(...)
    if YourAddonDB and YourAddonDB.debug then
        print("|cff888888[Debug]|r", ...)
    end
end

-- Add debug slash command
elseif cmd == "debug" then
    print("Debug Info:")
    print("Variable1:", tostring(value1))
    print("Table size:", #myTable)
end
```

### Common Debugging Techniques
- Use `print()` statements liberally during development
- Add debug commands to inspect addon state
- Use `/reload` (or `/rl`) to reload UI after changes
- Check for Lua errors with BugSack or similar error addons
- Use `/dump` for complex table inspection (requires addon like DevPad)
- Test edge cases and boundary conditions

## Documentation

### Code Documentation
- Document all public functions with purpose, parameters, and return values
- Use clear section headers
- Add usage examples for complex features
- Keep comments up-to-date with code changes

### User Documentation
- Provide in-game help via slash commands
- Include README files for installation and usage
- Document known issues and limitations
- Provide examples of common usage patterns

## Security and Best Practices

1. **Never Store Sensitive Data** - Don't save passwords or authentication tokens
2. **Validate User Input** - Always sanitize and validate data from users
3. **Respect User Privacy** - Don't collect unnecessary data
4. **Follow WoW ToS** - Ensure addon doesn't violate Terms of Service
5. **No Automation** - Addons cannot perform automated actions (no botting)
6. **Protected Functions** - Respect Blizzard's protected function restrictions

## Common Pitfalls to Avoid

1. **Global Variable Pollution** - Always use local when possible
2. **Missing nil Checks** - API functions can return nil
3. **Incorrect Event Usage** - Match event to the data you need
4. **Frame Leaks** - Frames persist; clean up unused frames
5. **Ignoring API Changes** - WoW API evolves; maintain compatibility
6. **Poor Performance** - Profile and optimize hot code paths
7. **Hardcoded Values** - Use variables for magic numbers
8. **Missing Error Handling** - Expect operations to fail gracefully

## Resources

- **WoW API Documentation**: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- **Widget API**: https://warcraft.wiki.gg/wiki/Widget_API
- **Events**: https://warcraft.wiki.gg/wiki/Events
- **Lua 5.1 Reference**: WoW uses Lua 5.1 (with some 5.2 features)
- **Interface Version History**: Track current version numbers for TOC files

## Example: Complete Addon Structure

```lua
-- MyAddon.lua
local addonName, addon = ...

-- Create namespace
MyAddon = {}
local MA = MyAddon

-- Local references for performance
local print = print
local string_format = string.format

-- Defaults
local defaults = {
    enabled = true,
    option1 = "value",
}

-- Initialize
function MA:Initialize()
    if not MyAddonDB then
        MyAddonDB = {}
    end
    for k, v in pairs(defaults) do
        if MyAddonDB[k] == nil then
            MyAddonDB[k] = v
        end
    end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        MA:Initialize()
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00MyAddon|r loaded!")
    end
end)

-- Slash commands
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    local cmd = (msg or ""):lower()
    if cmd == "" or cmd == "help" then
        print("MyAddon Commands:")
        print("/myaddon help - Show this help")
    end
end
```

## Summary

Follow these guidelines to create maintainable, performant, and user-friendly World of Warcraft addons:
- Use proper Lua style and local variables
- Handle events efficiently
- Maintain backward compatibility
- Validate inputs and handle errors gracefully
- Document your code
- Test thoroughly across WoW versions
