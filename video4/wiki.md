# The Essential Roblox stuff

Here's the bare minimum that matters for spinning platforms.

## Core Services & Objects

| Thing | What It Does | When You Need It |
|-------|-------------|------------------|
| `TweenService` | Creates smooth animations between values | Every spinning platform - handles the rotation math |
| `TweenInfo` | Controls timing, easing, and repetition | Setting speed, easing style, and infinite loops |
| `BasePart` | Your spinning object with CFrame and properties | Anchored positioning and visual styling |
| `CFrame.Angles` | Converts degrees to 3D rotations | Axis-specific spinning (X, Y, or Z rotation) |
| `ClickDetector` | Lets players interact with parts | Speed cycling and interactive controls |
| `RemoteEvent` | Sends data from server to clients | Visual effects when spin parameters change |

## Code patterns

**Infinite smooth rotation:**
```lua
local function startSpin(part, duration, axis)
    local rotationCFrame = CFrame.Angles(0, math.rad(360), 0) -- Y-axis example
    local tweenInfo = TweenInfo.new(
        duration,                        -- How long one full rotation takes
        Enum.EasingStyle.Linear,         -- Constant speed (no acceleration)
        Enum.EasingDirection.InOut,      -- Doesn't matter for Linear
        -1                               -- Repeat forever (-1 = infinite)
    )
    
    local tween = TweenService:Create(part, tweenInfo, {
        CFrame = part.CFrame * rotationCFrame  -- Rotate from current position
    })
    tween:Play()
    return tween
end
```

**Live control with attributes:**
```lua
-- Set up attribute listeners for external control
part:GetAttributeChangedSignal("SpeedSec"):Connect(function()
    local newSpeed = part:GetAttribute("SpeedSec")
    if typeof(newSpeed) == "number" and newSpeed > 0 then
        -- Cancel old tween and start with new speed
        restartSpin()
    end
end)
```

## Common gotchas

**Tweens don't update when you move the part**
- Problem: Tweens animate to absolute positions, not relative ones
- Solution: Use `part.CFrame * rotationCFrame` to rotate from current position

**Multiple tweens interfere with each other**
- Problem: Starting a new tween while another is running causes conflicts
- Solution: Always cancel the previous tween before starting a new one

**RepeatCount confusion**
- Remember: `-1` means infinite, `0` means play once, `1` means play twice total

## The official docs

These are the only Roblox documentation pages you'll actually need:

- **TweenService**: https://create.roblox.com/docs/reference/engine/classes/TweenService
- **TweenInfo**: https://create.roblox.com/docs/reference/engine/datatypes/TweenInfo
- **CFrame Math**: https://create.roblox.com/docs/reference/engine/datatypes/CFrame
- **BasePart Properties**: https://create.roblox.com/docs/reference/engine/classes/BasePart
- **EasingStyle Enums**: https://create.roblox.com/docs/reference/engine/enums/EasingStyle
- **ClickDetector**: https://create.roblox.com/docs/reference/engine/classes/ClickDetector
- **RemoteEvent**: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
