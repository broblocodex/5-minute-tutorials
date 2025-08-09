# Real-World examples

Time to steal some ideas. You've got a pad that launches players — now let's turn it into features that make games memorable.

**Important:** Each snippet goes in its own Script. Don't try to mash them together — that way lies confusion and bugs.

---

## 1) Race start gate

**The idea:** Step on the pad at race start to get launched up and over the starting gate. Creates instant excitement and momentum.

**Why it works:** Everyone loves that moment of "WHOOSH!" at the beginning of a race. It sets the energy and makes players feel powerful.

**Setup:**
1. Use the basic `script.lua` 
2. Place the pad right at the starting line
3. Build a gate or barrier that players launch over
4. Tune `LAUNCH_FORCE` until it feels perfect (usually 45-60)

**More ideas:** Try making the pad slightly bigger than normal and add a particle effect on launch for extra impact.

---

## 2) Anti-spam cooldown

**The idea:** Each player can only use the jump pad once every 0.8 seconds. Prevents chaos in spawn areas while keeping it fun.

**Why it's brilliant:** Stops griefers from spam-bouncing but doesn't kill the fun for normal players.

**Setup:**
1. Use Step 01 (`steps/01-cooldown.lua`)
2. Place in lobby or spawn area
3. Adjust `COOLDOWN` value as needed (0.8s is usually perfect)

```lua
-- The key pattern from Step 01:
local lastLaunchTimes = {}
local COOLDOWN = 0.8

local function canLaunch(player)
    if not player then return false end
    local now = os.clock()
    local lastTime = lastLaunchTimes[player.UserId]
    
    if lastTime and (now - lastTime) < COOLDOWN then 
        return false  -- Still cooling down
    end
    
    lastLaunchTimes[player.UserId] = now
    return true
end
```

**More ideas:** Add a subtle visual indicator when someone's on cooldown — maybe dim the pad color slightly.

---

## 3) Speed strip combo

**The idea:** Hit a speed boost strip, then immediately hit a jump pad while moving fast. The combination creates massive air time.

**Perfect for:** Obstacle courses, racing games, any place you want players to feel like superheroes.

**Setup:**
1. Create a speed strip Part that boosts WalkSpeed for 2 seconds
2. Place a jump pad right after it (timing is everything)
3. Use basic `script.lua` for the pad

**Speed strip code** (put this in a separate Script inside the speed strip Part):
```lua
local Players = game:GetService("Players")
local speedStrip = script.Parent

local SPEED_BOOST = 8  -- How much faster they go
local BOOST_DURATION = 2  -- How long the boost lasts

speedStrip.Touched:Connect(function(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if not player then return end
    
    -- Apply speed boost
    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = originalSpeed + SPEED_BOOST
    
    -- Remove boost after duration
    task.delay(BOOST_DURATION, function()
        if humanoid.Parent then  -- Check if player still exists
            humanoid.WalkSpeed = originalSpeed
        end
    end)
    
    -- Visual feedback
    speedStrip.BrickColor = BrickColor.new("Cyan")
    task.delay(0.2, function()
        speedStrip.BrickColor = BrickColor.new("White")
    end)
end)
```

**More ideas:** Put the jump pad exactly 2-3 studs after the speed strip ends. Players should hit it right as they're at peak speed.

---

Here's the thing: jump pads work best when players don't expect them. Tuck one around a corner, hide it after a long climb, or put it right where someone's about to give up on a tricky jump. That surprise "WHOOSH!" moment? That's what keeps people playing.
