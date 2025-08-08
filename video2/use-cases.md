# Use Cases (in‑game inspiration)

Short, fun, and copyable. Four ways to use a jump pad today.

---

## 1) Start gate pop (obby/race)
- Where: race start line, challenge gate.
- Goal: step on pad → pop up and over the gate for a hype start.

Setup
1) Use `script.lua`.
2) Tune POWER (LAUNCH_FORCE) until it feels right.

Tiny snippet (color pulse):
```lua
pad.BrickColor = BrickColor.new("Lime green")
task.delay(0.1, function() pad.BrickColor = BrickColor.new("Bright yellow") end)
```

---

## 2) Forward fling (speed run)
- Where: straightaway into a big jump.
- Goal: launch in look direction for flow.

Setup
1) Use `script.extended.lua` and set MODE = "forward".

Tiny snippet (forward velocity idea):
```lua
local look = root.CFrame.LookVector
bv.MaxForce = Vector3.new(4000, math.huge, 4000)
bv.Velocity = look * POWER + Vector3.new(0, POWER * 0.6, 0)
```

---

## 3) Combo with speed strip
- Where: arc jump after a boost.
- Goal: hit speed strip → hit jump pad → big air.

Setup
1) On the speed strip, give WalkSpeed boost for 2s; place pad right after it.

Tiny snippet (speed strip):
```lua
local old = hum.WalkSpeed
hum.WalkSpeed = old + 8
task.delay(2, function() hum.WalkSpeed = old end)
```

---

## 4) Cooldown gate (anti‑spam)
- Where: spawn area, lobby toy.
- Goal: stop spam launching; 0.8s personal cooldown.

Setup
1) Use `script.extended.lua` (it includes a per‑player cooldown).

Tiny snippet (pattern):
```lua
local last = {}
local t, prev = os.clock(), last[uid]
if prev and (t - prev) < 0.8 then return end
last[uid] = t
```