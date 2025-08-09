# Use Cases (in-game inspiration)

Short, fun, and copyable. Four ways to use a jump pad today.

Note
- Each use case should live in its own Script. Don’t mix snippets. Place the Script exactly where the Setup says, and keep the top-of-snippet variables as shown so references resolve (e.g., `pad = script.Parent`).

---

## 1) Start gate pop (obby/race)
- Where: race start line, challenge gate.
- Goal: step on pad → pop up and over the gate for a hype start.

Setup
1) Use `script.lua`.
2) Tune POWER (LAUNCH_FORCE) until it feels right.

Tiny snippet (color pulse):
```lua
local pad = script.Parent -- Script inside the pad Part
pad.BrickColor = BrickColor.new("Lime green")
task.delay(0.1, function() pad.BrickColor = BrickColor.new("Bright yellow") end)
```

---

## 2) Cooldown gate (anti‑spam)
- Where: spawn area, lobby toy.
- Goal: stop spam launching; 0.8s personal cooldown.

Setup
1) Use Step 01 (`steps/01-cooldown.lua`).

Tiny snippet (pattern):
```lua
local last = {}
local t, prev = os.clock(), last[uid]
if prev and (t - prev) < 0.8 then return end
last[uid] = t
```

---

## 3) Forward fling (speed run)
- Where: straightaway into a big jump.
- Goal: launch in look direction for flow.

Setup
1) Use Step 02 (`steps/02-forward-mode.lua`) and set `MODE = "forward"`.

Tiny snippet (forward velocity idea):
```lua
-- Context: inside the pad’s launch function where `root`, `bv`, and `POWER` exist
local look = root.CFrame.LookVector
bv.MaxForce = Vector3.new(4000, math.huge, 4000)
bv.Velocity = look * POWER + Vector3.new(0, POWER * 0.6, 0)
```

---

## 4) Combo with speed strip
- Where: arc jump after a boost.
- Goal: hit speed strip → hit jump pad → big air.

Setup
1) On the speed strip, give WalkSpeed boost for 2s; place pad right after it.

Tiny snippet (speed strip):
```lua
-- Context: inside a Touched handler where `hum` is the toucher’s Humanoid
local old = hum.WalkSpeed
hum.WalkSpeed = old + 8
task.delay(2, function() hum.WalkSpeed = old end)
```