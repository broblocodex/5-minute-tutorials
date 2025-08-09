# Real-World examples

Time to steal some ideas. You've got a teleporter that moves players — now let's turn it into features that make games memorable.

**Important:** Each snippet goes in its own Script. Don't try to mash them together — that way lies confusion and bugs.

---

## 1) Fast-travel hub

**The idea:** Central hub with 4 portals, each taking you to a different zone. Perfect for RPGs, adventure games, or any world with multiple areas.

**Why it works:** Players love feeling like they can zip around your world quickly. No more boring walking between zones.

**Setup:**
1. Use the basic `script.lua` in each portal
2. Point each Target to a spawn pad in different zones  
3. Add a SurfaceGui label showing where each portal goes

```lua
-- Put this in each portal to auto-label the destination
local portal = script.Parent
local target = portal:FindFirstChild("Target")
local label = portal.SurfaceGui.TextLabel

-- Show the destination name
label.Text = target.Value and target.Value.Name or "Unknown"
```

**More ideas:** Color-code each portal to match its destination zone.

---

## 2) Key-locked portal

**The idea:** Portal only works if you have the right key. Great for progression systems and secret areas.

**Why it's brilliant:** Creates natural game progression. Players feel rewarded when they finally unlock new areas.

**Setup:**
1. Use Step 02 (`steps/02-gated-access.lua`)
2. Create a pickupable key Part somewhere in your world
3. Check for the key before allowing teleportation

```lua
-- Put this Script inside a key Part to make it pickupable
local Players = game:GetService("Players")

local key = script.Parent
key.Name = "BlueKey"
key.BrickColor = BrickColor.new("Bright blue")
key.Material = Enum.Material.Neon

-- Pick up the key when touched
key.Touched:Connect(function(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player then return end
    
    -- Give them the key and destroy it
    player:SetAttribute("HasBlueKey", true)
    key:Destroy()
end)
```

**More ideas:** Add a sound effect when the key is picked up, or change the portal color when unlocked.

---

## 3) Rotating puzzle portal

**The idea:** One portal that cycles between 3 different destinations when clicked. Players must figure out the pattern.

**Why it's genius:** Adds puzzle elements to movement. Creates those "aha!" moments when players crack the rotation pattern.

**Setup:**
1. Use the basic `script.lua`
2. Add destinations to workspace (A, B, C)
3. Add this cycling logic

```lua
-- Put this in the portal to make it cycle destinations
local portal = script.Parent
local target = portal:FindFirstChild("Target")
local destinations = {workspace.ZoneA, workspace.ZoneB, workspace.ZoneC}
local currentIndex = 1

local clickDetector = Instance.new("ClickDetector")
clickDetector.Parent = portal

clickDetector.MouseClick:Connect(function()
    currentIndex = (currentIndex % #destinations) + 1
    target.Value = destinations[currentIndex]
    
    -- Visual feedback showing current destination
    portal.BrickColor = BrickColor.new({"Bright red", "Bright green", "Bright blue"}[currentIndex])
end)
```

**More ideas:** Add sound effects for each rotation to give players audio cues.

---

Good teleporters don't just move players — they make travel feel intentional and exciting. Hide them behind challenges, use them to reward exploration, or make them part of the puzzle itself.
