# The Essential Roblox stuff

Here's the bare minimum that matters for interactive parts.

## Core Services & Objects

| Thing | What it does | When you need it |
|-------|-------------|------------------|
| `Players` | Connects character models to actual players | Every time you want to know "who touched this?" |
| `BasePart.Touched` | Fires when something hits your part | The foundation of all physical interactions |
| `Humanoid` | Proves something is a real character (not a random brick) | Filtering out junk from touch events |
| `ClickDetector` | Lets players click parts from a distance | Testing, UI alternatives, accessibility |
| `BrickColor` | Pre-made color palette | Quick and easy colors without math |

## Code patterns

**Getting a player from a touch event:**
```lua
local function getPlayerFromHit(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    
    local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
    return player
end

-- Usage:
part.Touched:Connect(function(hit)
    local player = getPlayerFromHit(hit)
    if not player then return end
    -- Do something with the player
end)
```

## Common gotchas

**Touch events fire multiple times per contact** 
Solution: Use debounce or keep your code lightning fast.

**Parts can get destroyed while events are still running**
Solution: Always check if objects still exist before using them.

**BrickColor vs Color3 confusion**
- `BrickColor`: Named colors like "Bright red" (easier)
- `Color3`: RGB values like `Color3.new(1, 0, 0)` (more precise)

## The official docs

These are the only Roblox documentation pages you'll actually need:

- **Players Service**: https://create.roblox.com/docs/reference/engine/classes/Players
- **BasePart Events**: https://create.roblox.com/docs/reference/engine/classes/BasePart#events
- **Humanoid Class**: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- **ClickDetector**: https://create.roblox.com/docs/reference/engine/classes/ClickDetector
- **BrickColor List**: https://create.roblox.com/docs/reference/engine/datatypes/BrickColor
- **Attributes Guide**: https://create.roblox.com/docs/production/attributes
- **RemoteEvent**: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent