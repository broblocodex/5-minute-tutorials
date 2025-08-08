### Core Pieces (What You Actually Use)

| Thing | Why You Touch It |
|-------|------------------|
| Players | Turn character model into Player object |
| Debris | Cleanup BodyVelocity after a short delay |
| BasePart.Touched | Fire when a player steps on the pad |
| Humanoid/HumanoidRootPart | Validate real character and get the root part |
| BodyVelocity | Apply instantaneous velocity |
| Vector3 | Set velocity and MaxForce |

### Minimal Patterns

Launch up:
```lua
local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(0, math.huge, 0)
bv.Velocity = Vector3.new(0, power, 0)
bv.Parent = root
game:GetService("Debris"):AddItem(bv, 0.5)
```

Launch forward:
```lua
local look = root.CFrame.LookVector
local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(4000, math.huge, 4000)
bv.Velocity = look * power + Vector3.new(0, power * 0.6, 0)
bv.Parent = root
game:GetService("Debris"):AddItem(bv, 0.5)
```

Per‑player cooldown:
```lua
local last = {}
local COOLDOWN = 0.8
local uid = player.UserId
local t, prev = os.clock(), last[uid]
if prev and (t - prev) < COOLDOWN then return end
last[uid] = t
```

### Study Links (Roblox docs)
- Players: https://create.roblox.com/docs/reference/engine/classes/Players
- Debris: https://create.roblox.com/docs/reference/engine/classes/Debris
- BasePart (Touched): https://create.roblox.com/docs/reference/engine/classes/BasePart#events
- Humanoid: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- BodyVelocity: https://create.roblox.com/docs/reference/engine/classes/BodyVelocity
- Vector3: https://create.roblox.com/docs/reference/engine/datatypes/Vector3
- Attributes: https://create.roblox.com/docs/production/attributes
- RemoteEvent: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
