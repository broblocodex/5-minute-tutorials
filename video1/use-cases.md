# Use Cases (in‑game inspiration)

Short, fun, and punchy. Each idea uses tiny hooks (Attributes/RemoteEvents) the extended script now publishes: `ColorIndex` and `LastUserId`.

---

## 1) Secret portal (color code to open)
- Where: hub world door, hidden room, event gate.
- Goal: set the block to the right color to reveal a portal Part.

Setup
1) Use `script.extended.lua` and set your target color index (e.g., 4 = yellow).
2) Put a portal Part with CanCollide=false and Transparency=1; toggle when solved.

Snippet
```lua
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
1) Use `script.extended.lua` (it writes `LastUserId`).
2) Place a BoostPad part; on Touched, check if the toucher is the last user.

Snippet
```lua
BoostPad.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
    if not player then return end
    if part:GetAttribute("LastUserId") == player.UserId then
        local old = hum.WalkSpeed
        hum.WalkSpeed = old + 8
        task.delay(3, function() hum.WalkSpeed = old end)
    end
end)
```

---

## 3) Party light (sync to music beats)
- Where: club area, lobby, event stage.
- Goal: block cycles color on beat; clients add sparkles locally for zero lag.

Setup
1) Add a `RemoteEvent` named `ColorChanged` under the block.
2) From the server DJ script, fire on beats. Clients listen and play effects.

Snippet (server beat driver)
```lua
local remote = part:FindFirstChild("ColorChanged")
while true do
    remote:FireAllClients(part, (part:GetAttribute("ColorIndex") % 4) + 1)
    task.wait(0.5) -- half‑second beat
end
```

Snippet (client VFX)
```lua
remote.OnClientEvent:Connect(function(p, idx)
    if p ~= part then return end
    -- spawn a quick sparkle or flash GUI here
end)
```

---

## 4) Team claim tile (lightweight control)
- Where: mini‑games, king‑of‑the‑hill ring, tile maps.
- Goal: touching paints it to your team; the UI shows live team dominance.

Setup
1) Keep it simple: when clicked/touched, set `part.BrickColor = player.TeamColor`.
2) Count by BrickColor and update a ScreenGui bar.

Snippet
```lua
local function countTiles(tiles, teamColor)
    local n = 0
    for _,p in ipairs(tiles) do if p.BrickColor == teamColor then n += 1 end end
    return n
end

-- Recount when color changes
for _,p in ipairs(tiles) do
    p:GetPropertyChangedSignal("BrickColor"):Connect(updateScores)
end
```

Tips
- Use 3–4 strong colors for clarity.
- Attributes (`ColorIndex`, `LastUserId`) make it easy to wire logic without editing the base scripts.