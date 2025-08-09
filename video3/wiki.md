# The Essential Roblox stuff

Here's the bare minimum that matters for teleportation.

## Core Services & Objects

| Thing | What It Does | When You Need It |
|-------|-------------|------------------|
| `Players` | Connects character models to actual players | Getting player data for cooldowns and permissions |
| `BasePart.Touched` | Fires when something hits your portal | The trigger for all teleportation |
| `Humanoid` | Proves something is a real character | Filtering out random parts and NPCs |
| `HumanoidRootPart` | The physics center of a character | What you actually teleport (not the character model) |
| `CFrame` | Position + rotation in one object | Controlling where players appear after teleporting |
| `Vector3` | 3D direction and magnitude | Height offsets to prevent floor-clipping |
| `ObjectValue` | Reference to another object | Linking portals to their destinations |

## Code patterns

**Safe teleportation (always do this):**
```lua
local function teleportPlayer(player, destination)
    local character = player.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Always add height offset to avoid getting stuck in floors
    root.CFrame = destination.CFrame + Vector3.new(0, 4, 0)
end
```

**Per-player cooldown tracking:**
```lua
local lastTeleportTime = {}
local COOLDOWN = 2.0

local function canTeleport(player)
    local now = os.clock()
    local lastTime = lastTeleportTime[player.UserId]
    if lastTime and (now - lastTime) < COOLDOWN then
        return false
    end
    lastTeleportTime[player.UserId] = now
    return true
end
```

## Common gotchas

**Players get stuck in floors**
- Problem: Teleporting directly to a Part's position puts players inside it
- Solution: Always add a height offset like `Vector3.new(0, 4, 0)`

**Teleporter triggers too many times**
- Problem: Touch events fire rapidly, causing multiple teleports
- Solution: Add per-player cooldowns (1-2 seconds is usually good)

## The official docs

These are the only Roblox documentation pages you'll actually need:

- **Players Service**: https://create.roblox.com/docs/reference/engine/classes/Players
- **BasePart Events**: https://create.roblox.com/docs/reference/engine/classes/BasePart#events
- **Humanoid Class**: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- **CFrame Positioning**: https://create.roblox.com/docs/reference/engine/datatypes/CFrame
- **ObjectValue**: https://create.roblox.com/docs/reference/engine/classes/ObjectValue
- **RemoteEvents**: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent (for visual effects)
