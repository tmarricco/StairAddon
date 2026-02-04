# Spiral Staircase Helper Addon for World of Warcraft

A World of Warcraft addon that helps calculate and visualize positions for building spiral staircases in player housing.

## Installation

1. Download or clone this repository
2. Copy the `StairAddon` folder to your WoW `Interface\AddOns` directory:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - Mac: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or reload your UI with `/reload`

## Usage

### Basic Commands

The addon can be accessed using any of these commands:
- `/stairs` - Main command (opens configuration UI)
- `/spiral` - Alias for /stairs
- `/ss` - Short alias

### Command List

Type `/stairs help` in-game to see all available commands:

- `/stairs` - Open the configuration UI
- `/stairs print` - Print all stair positions to chat
- `/stairs step <num>` - Print position for a specific step number
- `/stairs preview` - Show staircase preview information
- `/stairs copy` - Open a window to copy positions to clipboard
- `/stairs setcenter` - Set the spiral center to your current player position
- `/stairs radius <num>` - Set the radius of the spiral (distance from center)
- `/stairs height <num>` - Set the height increase per step
- `/stairs angle <num>` - Set the rotation angle per step (in degrees)
- `/stairs steps <num>` - Set the total number of steps
- `/stairs cw` - Set clockwise direction
- `/stairs ccw` - Set counter-clockwise direction

### Configuration UI

The graphical configuration interface allows you to:
- Adjust radius, height per step, angle per step, and number of steps using sliders
- Set the center coordinates (X, Y, Z)
- Use your current player position as the center
- Toggle between clockwise and counter-clockwise spiral direction
- Print positions to chat
- Copy positions to clipboard
- Reset to default values

## Features

- **Accurate Position Calculations**: Uses trigonometry to calculate exact X, Y, Z coordinates and rotation angles for each step
- **Customizable Parameters**: Adjust radius, height, angle, and number of steps to fit your design
- **Visual Configuration**: Easy-to-use UI with sliders and input boxes
- **Position Tracking**: Set center based on your current location
- **Export Options**: Print to chat or copy to clipboard for external use
- **Persistent Settings**: Your configuration is saved between sessions

## Default Settings

- Radius: 3.0 units
- Height per step: 0.5 units
- Angle per step: 30 degrees
- Number of steps: 12
- Direction: Clockwise
- Center: (0, 0, 0)

## Examples

### Creating a standard spiral staircase:
```
/stairs
```
This opens the UI where you can adjust the settings visually.

### Quick setup via commands:
```
/stairs setcenter
/stairs radius 4
/stairs height 0.6
/stairs steps 16
/stairs print
```

### Getting positions for a specific step:
```
/stairs step 5
```

## Support

For issues, questions, or feature requests, please create an issue in the GitHub repository.

## Version

Current version: 1.0.0
Compatible with WoW Interface: 110100 (Patch 11.1.0)
