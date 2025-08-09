# The Essential Roblox stuff

Here's the bare minimum that matters for jump pads.

## Core Services & Objects

| Thing | What It Does | When You Need It |
|-------|-------------|------------------|
| `Players` | Connects character models to actual players | Getting player data for cooldowns and permissions |
| `Debris` | Auto-deletes objects after a timer | Cleaning up BodyVelocity so physics don't get weird |
| `BasePart.Touched` | Fires when something hits your part | The trigger for all jump pad interactions |
| `Humanoid` | Proves something is a real character | Filtering out random parts and tools |
| `HumanoidRootPart` | The physics center of a character | Where you attach forces to move players |
| `BodyVelocity` | Applies instant velocity to objects | The actual launching mechanism |
| `Vector3` | 3D direction and magnitude | Controlling launch direction and power |

## Code patterns

**Basic upward launch:**
```lua
local function launchUp(humanoidRootPart, power)
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)  -- Only upward force
    bodyVelocity.Velocity = Vector3.new(0, power, 0)      -- Straight up
    bodyVelocity.Parent = humanoidRootPart
    
    -- Clean up automatically (prevents physics weirdness)
    game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
end
```

**Getting player from touch event:**
```lua
local function getPlayerFromHit(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    
    local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
    local rootPart = hit.Parent:FindFirstChild("HumanoidRootPart")
    
    return player, rootPart
end

-- Usage:
jumpPad.Touched:Connect(function(hit)
    local player, rootPart = getPlayerFromHit(hit)
    if not player or not rootPart then return end
    
    -- Launch the player
    launchUp(rootPart, 50)
end)
```

## Common gotchas

**BodyVelocity sticks around forever**
- Solution: Always use `Debris:AddItem()` to clean up after 0.5 seconds
- Why: Leftover BodyVelocity objects cause weird physics behavior

**Touch events fire multiple times**
- Problem: One step can trigger 5+ touch events
- Solution: Add a small debounce or use per-player cooldowns

**Dead players can still trigger pads**
- Always check `humanoid.Health > 0` before launching
- Dead characters should not be launchable

## The official docs

These are the only Roblox documentation pages you'll actually need:

- **Players Service**: https://create.roblox.com/docs/reference/engine/classes/Players
- **Debris Service**: https://create.roblox.com/docs/reference/engine/classes/Debris
- **BasePart Events**: https://create.roblox.com/docs/reference/engine/classes/BasePart#events
- **Humanoid Class**: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- **BodyVelocity**: https://create.roblox.com/docs/reference/engine/classes/BodyVelocity
- **Vector3 Math**: https://create.roblox.com/docs/reference/engine/datatypes/Vector3