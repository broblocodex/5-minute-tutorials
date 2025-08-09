# Use cases — Teleporter

Four tiny ideas to spark integrations. Copy and tweak.

Note
- Each use case should live in its own Script (or LocalScript where called out). Don’t mix snippets. Place the script where the Setup/heading implies, and keep top-of-snippet variables clear (e.g., `local portal = script.Parent`).

## 1) Fast‑travel hub

- Place 4 portals in a hub. Each portal’s Target points to a zone’s spawn pad.
- Show the zone name with a SurfaceGui.

Snippet: set the label from the destination Part name.
```lua
local portal = script.Parent
local target = script.Parent:FindFirstChild("Target")
local label = script.Parent.SurfaceGui.TextLabel
label.Text = target.Value and target.Value.Name or "?"
```

## 2) Key‑locked portal

- Use Step 02 (gated‑access): only allow when the player has a key.
```lua
-- Add near canUse(player)
local function hasKey(player)
    return player:GetAttribute("HasBlueKey") == true
end

local function canUse(player)
    if not hasKey(player) then return false end
    -- cooldown check (from Step 02)
    local t = os.clock(); local prev = lastUseAtByUserId[player.UserId]
    if prev and (t - prev) < COOLDOWN then return false end
    lastUseAtByUserId[player.UserId] = t; return true
end
```

## 3) Puzzle: rotate destinations

- One portal cycles through 3 targets. Swap Target.Value on click.
```lua
local portal = script.Parent
local target = portal:FindFirstChild("Target")
local choices = {workspace.A, workspace.B, workspace.C}
local i = 1
local click = Instance.new("ClickDetector", portal)
click.MouseClick:Connect(function()
    i = (i % #choices) + 1
    target.Value = choices[i]
    portal:SetAttribute("DestIndex", i)
end)
```

## 4) Party arrival VFX

- Use Step 03 (remoteevent). Add a RemoteEvent named "Teleported" under the portal. On client, spawn a sparkle at arrival.
```lua
-- Client (LocalScript in StarterPlayerScripts)
local rs = game:GetService("ReplicatedStorage")
local function hook(part)
    local ev = part:FindFirstChild("Teleported")
    if ev then
        ev.OnClientEvent:Connect(function(portal, player, dest)
            if not dest or not dest.Position then return end
            -- quick sparkle
            local p = Instance.new("ParticleEmitter")
            p.Rate = 200; p.Lifetime = NumberRange.new(0.3, 0.6)
            p.Speed = NumberRange.new(4, 8)
            p.Parent = dest
            task.delay(0.25, function() p.Enabled = false; task.delay(0.5, function() p:Destroy() end) end)
        end)
    end
end
for _, portal in ipairs(workspace:GetDescendants()) do if portal:IsA("BasePart") then hook(portal) end end
workspace.DescendantAdded:Connect(function(inst) if inst:IsA("BasePart") then hook(inst) end end)
```