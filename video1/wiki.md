### Core Pieces (What You Actually Use)

| Thing | Why You Touch It |
|-------|------------------|
| Players | Turn character model into Player object |
| BasePart.Touched | Trigger on player contact |
| Humanoid | Filter touch to real characters |
| ClickDetector | Alternate input (mouse / tap) |
| BrickColor | Fast named colors |

### Minimal Patterns

Get player from hit:
```lua
local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
if not hum then return end
local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
if not player then return end
```

Cycle state:
```lua
index += 1
if index > #COLORS then index = 1 end
part.BrickColor = COLORS[index]
```

Click support:
```lua
local cd = Instance.new("ClickDetector")
cd.Parent = part
cd.MouseClick:Connect(cycleColor)
```

Basic debounce (touch spam guard):
```lua
local last = 0
local GAP = 0.1
if os.clock() - last < GAP then return end
last = os.clock()
```

### Gotchas
- Multiple rapid Touched events per single contact – add a small debounce.
- If the part is destroyed, old connections can still try to run; keep code short and safe.
- BrickColor vs Color3: BrickColor is perfect here for a quick named palette.

### Extend Fast
| Add | Change |
|-----|--------|
| Sound | Play on cycleColor |
| RemoteEvent | Replicate client‑side effects |
| Particle | Only when hitting final color |

### Study Links (Roblox docs)
- Players service: https://create.roblox.com/docs/reference/engine/classes/Players
- BasePart (Touched event): https://create.roblox.com/docs/reference/engine/classes/BasePart#events
- Humanoid: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- ClickDetector: https://create.roblox.com/docs/reference/engine/classes/ClickDetector
- BrickColor datatype: https://create.roblox.com/docs/reference/engine/datatypes/BrickColor
- Attributes (SetAttribute/GetAttribute): https://create.roblox.com/docs/production/attributes
- RemoteEvent: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
