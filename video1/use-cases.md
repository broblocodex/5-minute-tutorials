# Use Cases (in‑game inspiration)

Short, fun, and punchy. Each idea lists the required step of the main script.
- Step 02 publishes `ColorIndex`
- Step 03 publishes `LastUserId`
- Step 04 broadcasts `ColorChanged` RemoteEvent

Note
- Each use case should live in its own Script. Don’t mix snippets. Place the Script exactly where the Setup says, and keep the top-of-snippet variables as shown so references resolve (e.g., `part = script.Parent`).

---

## 1) Secret portal (color code to open)
- Where: hub world door, hidden room, event gate.
- Goal: set the block to the right color to reveal a portal Part.

Setup
1) Use Step 02 (`steps/02-attributes.lua`) and set your target color index (e.g., 4 = yellow). Any later step also works.
2) Put a portal Part with CanCollide=false and Transparency=1; toggle when solved.
3) Put both the block and the portal under one Model; add a Script under the block. Name the portal sibling "Portal" (snippet expects it).

Snippet
```lua
local part = script.Parent
local portal = part.Parent:WaitForChild("Portal")

local TARGET = 4 -- yellow in the default palette
part:GetAttributeChangedSignal("ColorIndex"):Connect(function()
    if part:GetAttribute("ColorIndex") == TARGET then
        portal.CanCollide = true
        portal.Transparency = 0
    else
        portal.CanCollide = false
        portal.Transparency = 1
    end
end)
```

---

## 2) Time‑trial boost pad (tap to arm it)
- Where: racetrack start, obby checkpoint.
- Goal: the last player who tapped the block gets a 3‑second speed boost when they step on the nearby pad.

Setup
1) Use Step 03 (`steps/03-last-user-id.lua`) so the block writes `LastUserId`. Step 04 also works.
2) Place a BoostPad part; on Touched, check if the toucher is the last user.
3) Put a Script inside the BoostPad Part. Place the tap block (the one running `script.extended.lua`) as a sibling in the same parent and name it "TapBlock". The snippet uses `BoostPad.Parent:FindFirstChild("TapBlock")` to reference it; if not found, it falls back to `BoostPad`.

Snippet
```lua
local BoostPad = script.Parent
local part = (BoostPad.Parent and BoostPad.Parent:FindFirstChild("TapBlock")) or BoostPad -- sibling named "TapBlock"

local BOOST, DURATION = 8, 3
local active = {} -- hum -> { original: number, expire: number }

BoostPad.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
    if not player then return end
    if part:GetAttribute("LastUserId") ~= player.UserId then return end

    local now = os.clock()
    local st = active[hum]
    if st then
        -- Already boosted; just refresh the expiry so it cleanly extends.
        st.expire = now + DURATION
        return
    end

    active[hum] = { original = hum.WalkSpeed, expire = now + DURATION }
    hum.WalkSpeed += BOOST

    task.spawn(function()
        while active[hum] and os.clock() < active[hum].expire do
            task.wait(0.1)
        end
        if not active[hum] then return end
        local original = active[hum].original
        active[hum] = nil
        if hum.Parent then
            hum.WalkSpeed = original
        end
    end)
end)
```

---

## 3) Lamp color sync (RemoteEvent‑driven)
- Where: lobby pads, kiosks, decorative lights.
- Goal: lamp color mirrors the block’s color whenever the block changes, using the block’s `ColorChanged` RemoteEvent.

Setup
1) Use Step 04 (`steps/04-remoteevent.lua`) on the color block. Ensure there is a `RemoteEvent` named `ColorChanged` under the block.
2) Create a lamp Part.
3) Put a LocalScript in `StarterPlayerScripts`. Rename objects or update variables below: the lamp Part (e.g., "Lamp") and ensure the color block is a sibling named "Part".

Snippet
```lua
-- Edit these lines to match your setup
local lamp = workspace:WaitForChild("Lamp")
local block = lamp.Parent:FindFirstChild("Part") or lamp -- sibling named "Part"

local remote = block:WaitForChild("ColorChanged")

local function apply()
    lamp.Color = block.Color
end

remote.OnClientEvent:Connect(function(thePart, _colorIndex)
    if thePart ~= block then return end
    apply()
end)

-- Initialize on join
apply()
```

---

## 4) Claimable nameplate lamp (owner display via RemoteEvent)
- Where: lobby pads, base claim spots, kiosks.
- Goal: when a player taps the block, the lamp shows the owner’s display name (from `LastUserId`), updating when the block changes via `ColorChanged`.

Setup
1) Use Step 04 (`steps/04-remoteevent.lua`) on the color block. It writes `LastUserId` (from Step 03) and broadcasts changes via `ColorChanged`. Ensure there is a `RemoteEvent` named `ColorChanged` under the block.
2) Add a `BillboardGui` with a `TextLabel` to the lamp Part.
3) Put a LocalScript in `StarterPlayerScripts`. Rename objects or update variables below: the lamp Part (e.g., "Lamp") and ensure the color block is a sibling named "Part".

Snippet
```lua
local Players = game:GetService("Players")

-- Edit these lines to match your setup
local lamp = workspace:WaitForChild("Lamp")
local block = lamp.Parent:FindFirstChild("Part") or lamp -- sibling named "Part"

local textLabel = lamp:WaitForChild("BillboardGui"):WaitForChild("TextLabel")
local remote = block:WaitForChild("ColorChanged")

local function apply()
    local uid = block:GetAttribute("LastUserId")
    local name = "Unclaimed"
    if uid then
        local plr = Players:GetPlayerByUserId(uid)
        if plr then name = plr.DisplayName end
    end
    textLabel.Text = name
end

remote.OnClientEvent:Connect(function(thePart, _colorIndex)
    if thePart ~= block then return end
    apply()
end)

-- Initialize on join
apply()
```

---

Tips
- Use 3–4 strong colors for clarity.
- Attributes (`ColorIndex`, `LastUserId`) make it easy to wire logic without editing the base scripts.