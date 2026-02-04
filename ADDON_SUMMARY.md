# Spiral Staircase Helper - Addon Summary

## What This Addon Does

The Spiral Staircase Helper is a World of Warcraft addon designed to assist players in building spiral staircases within the game's player housing system. It calculates precise 3D positions (X, Y, Z coordinates) and rotation angles for each step of a spiral staircase based on customizable parameters.

## Key Features

### 1. **Mathematical Position Calculation**
   - Uses trigonometric functions (sin, cos) to calculate exact positions
   - Supports both clockwise and counter-clockwise spirals
   - Configurable radius, height per step, and rotation angle

### 2. **User Interface**
   - Graphical configuration window with sliders and input fields
   - Real-time updates when parameters change
   - Visual feedback with color-coded messages

### 3. **Slash Commands**
   - Primary command: `/stairs`
   - Aliases: `/spiral`, `/ss`
   - Extensive command set for quick adjustments

### 4. **Position Management**
   - Set spiral center to current player position
   - Export positions to clipboard
   - Print individual or all step positions to chat

### 5. **Persistent Settings**
   - Saves configuration between gaming sessions
   - Uses WoW's SavedVariables system

## How It Works

### Spiral Mathematics

The addon uses polar coordinates converted to Cartesian coordinates:

```
For each step i (0 to numSteps-1):
  angle = i × anglePerStep × direction (in radians)
  x = centerX + radius × cos(angle)
  y = centerY + radius × sin(angle)
  z = centerZ + i × heightPerStep
  rotation = (i × anglePerStep × direction) % 360
```

### Example Calculation

With default settings:
- Radius: 3.0 units
- Height per step: 0.5 units
- Angle per step: 30°
- Steps: 12
- Direction: Clockwise

The staircase will make one complete rotation (12 × 30° = 360°) and rise 5.5 units in height (11 × 0.5).

## Bug Fixes Applied

### Issue #1: UnitPosition API Call
**Problem:** The original code attempted to destructure 11 values from `UnitPosition()`:
```lua
local _, _, _, instanceX, instanceY, _, _, _, _, _, _ = UnitPosition("player")
```

**Fix:** Corrected to use the proper API signature:
```lua
local posY, posX = UnitPosition("player")
local posZ = select(3, UnitPosition("player")) or 0
```

**Reason:** The WoW API `UnitPosition()` returns only `positionY, positionX` (in that order), with an optional third parameter for Z height. The original code was using an incorrect signature that would cause the function to fail.

### Additional Improvements
- Added proper fallback to map coordinates if `UnitPosition` is unavailable
- Added safe default return values (0, 0, 0) if no position can be determined
- This ensures the addon works even in areas where position APIs might be restricted

## File Structure

```
StairAddon/
├── StairAddon.toc     # Addon metadata and load order
├── StairAddon.lua     # Main addon code (569 lines)
└── README.md          # User documentation
```

## Addon Load Process

1. WoW loads `StairAddon.toc` and reads metadata
2. WoW loads `StairAddon.lua` as specified in .toc file
3. Addon registers event handlers for `ADDON_LOADED` and `PLAYER_LOGIN`
4. On `ADDON_LOADED`, initializes saved variables with defaults
5. On `PLAYER_LOGIN`, displays welcome message
6. Slash commands are registered and ready to use

## Usage Flow

```
Player types: /stairs
    ↓
Config UI opens with current settings
    ↓
Player adjusts sliders (radius, height, angle, steps)
    ↓
Addon recalculates all stair positions in real-time
    ↓
Player clicks "Print Positions" or "Copy to Clipboard"
    ↓
Player uses the coordinates to place items in-game
```

## Technical Details

- **Language:** Lua 5.1 (WoW's embedded Lua version)
- **WoW API Version:** Interface 110100 (Patch 11.1.0)
- **Saved Variables:** SpiralStairsDB (global table)
- **Global Namespace:** SpiralStairs (SS alias)
- **Dependencies:** None (uses built-in WoW UI framework)

## Testing Recommendations

To test this addon:
1. Install in WoW AddOns directory
2. Launch WoW and log into a character
3. Verify welcome message appears
4. Type `/stairs` to open UI
5. Adjust sliders and verify calculations update
6. Test position export features
7. Use coordinates to place housing items in a spiral pattern

## Future Enhancement Opportunities

- Visual 3D preview of the staircase
- Presets for common staircase types
- Import/export of configurations
- Integration with other housing addons
- Waypoint markers in the game world
- Support for elliptical (non-circular) spirals
