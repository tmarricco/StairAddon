# Visual Guide to Spiral Staircase Helper

## Addon Interface

```
┌─────────────────────────────────────┐
│  Spiral Staircase Helper      [X]   │
├─────────────────────────────────────┤
│                                     │
│  Radius:          [====|===] 3.0    │
│  Height/Step:     [===|====] 0.5    │
│  Angle/Step:      [===|====] 30°    │
│  Number of Steps: [====|===] 12     │
│                                     │
│  Center Coordinates:                │
│    Center X:  [    0.00    ]        │
│    Center Y:  [    0.00    ]        │
│    Center Z:  [    0.00    ]        │
│                                     │
│  [✓] Clockwise Direction            │
│                                     │
│  [Print Positions] [Use Player Pos] │
│  [Copy to Clipboard] [Reset]        │
│                                     │
└─────────────────────────────────────┘
```

## Spiral Pattern Visualization

### Top-Down View (X-Y Plane)
```
                  12 ●
              11 ●     ● 1
          10 ●             ● 2
        9 ●      [CENTER]    ● 3
          8 ●      (0,0)   ● 4
              7 ●       ● 5
                  6 ●
```

### Side View (showing height increase)
```
12 ●                              
11 ●                          Height increases
10 ●                          by 0.5 per step
 9 ●                              
 8 ●                          Total rise: 5.5 units
 7 ●                          (11 × 0.5)
 6 ●                              
 5 ●                              
 4 ●                              
 3 ●                              
 2 ●                              
 1 ●__________________________ Ground Level
```

### 3D Perspective
```
        12 ●
       /  11 ●
      /   /  10 ●
     /   /   /  9 ●
    /   /   /   / 8 ●
   /   /   /   /  / 7 ●
  /   /   /   /  /  / 6 ●
 /   /   /   /  /  /  / 5 ●
/   /   /   /  /  /  /  / 4 ●
   /   /   /  /  /  /  /  / 3 ●
      /   /  /  /  /  /  /  / 2 ●
         /  /  /  /  /  /  /  / 1 ●___
                                    [CENTER]
```

## Slash Commands Quick Reference

```
COMMAND                   DESCRIPTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/stairs                   Open config UI
/stairs help             Show all commands
/stairs print            Display all positions
/stairs step 5           Show position for step 5
/stairs setcenter        Use player position as center
/stairs radius 4         Set radius to 4.0
/stairs height 0.6       Set height per step
/stairs angle 45         Set 45° rotation per step
/stairs steps 16         Create 16 steps
/stairs cw               Clockwise direction
/stairs ccw              Counter-clockwise direction
/stairs copy             Copy to clipboard
/stairs preview          Show preview info
```

## Example Output

When you type `/stairs print`, you'll see:

```
=== Spiral Staircase Positions ===
Center: (0.00, 0.00, 0.00)
Radius: 3.00 | Height/Step: 0.50 | Angle/Step: 30°
Direction: Clockwise | Steps: 12
---------------------------------
Step  1: X:    3.00  Y:    0.00  Z:    0.00  Rot:   0°
Step  2: X:    2.60  Y:    1.50  Z:    0.50  Rot:  30°
Step  3: X:    1.50  Y:    2.60  Z:    1.00  Rot:  60°
Step  4: X:    0.00  Y:    3.00  Z:    1.50  Rot:  90°
Step  5: X:   -1.50  Y:    2.60  Z:    2.00  Rot: 120°
Step  6: X:   -2.60  Y:    1.50  Z:    2.50  Rot: 150°
Step  7: X:   -3.00  Y:    0.00  Z:    3.00  Rot: 180°
Step  8: X:   -2.60  Y:   -1.50  Z:    3.50  Rot: 210°
Step  9: X:   -1.50  Y:   -2.60  Z:    4.00  Rot: 240°
Step 10: X:    0.00  Y:   -3.00  Z:    4.50  Rot: 270°
Step 11: X:    1.50  Y:   -2.60  Z:    5.00  Rot: 300°
Step 12: X:    2.60  Y:   -1.50  Z:    5.50  Rot: 330°
=================================
```

## Workflow Example

```
┌────────────────────────────────────────────────────────────┐
│  1. Open addon                                             │
│     Type: /stairs                                          │
│     ↓                                                      │
│  2. Set center point                                       │
│     Stand where you want the center                        │
│     Click: "Use Player Position"                           │
│     ↓                                                      │
│  3. Adjust parameters                                      │
│     - Move "Radius" slider to 4.0                          │
│     - Set "Height/Step" to 0.6                             │
│     - Set "Angle/Step" to 30°                              │
│     - Set "Steps" to 12                                    │
│     ↓                                                      │
│  4. Get coordinates                                        │
│     Click: "Print Positions"                               │
│     or                                                     │
│     Click: "Copy to Clipboard"                             │
│     ↓                                                      │
│  5. Build your staircase!                                  │
│     Use the coordinates to place items in-game             │
│     Each step shows: X, Y, Z position and Rotation angle   │
└────────────────────────────────────────────────────────────┘
```

## Mathematical Formula

For each step `i` (from 0 to numSteps-1):

```
angle = i × anglePerStep × direction (converted to radians)

x = centerX + radius × cos(angle)
y = centerY + radius × sin(angle)
z = centerZ + i × heightPerStep

rotation = (i × anglePerStep × direction) mod 360
```

Where:
- `direction` = 1 for clockwise, -1 for counter-clockwise
- All angle calculations use radians internally
- Rotation output is in degrees for easier understanding
