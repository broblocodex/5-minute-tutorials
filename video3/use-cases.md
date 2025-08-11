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
3. Add the script longside with the teleporter script (it will add a SurfaceGui with TextLabel automatically)

```lua
-- Auto-label portals with their destination names
local portal = script.Parent
local target = portal:FindFirstChild("Target")

-- Create the UI if it doesn't exist
local surfaceGui = portal:FindFirstChild("SurfaceGui")
if not surfaceGui then
    surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front  -- Show on top face - change to Top/Back/etc as needed
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50  -- Higher = sharper text
    surfaceGui.Parent = portal
end

local textLabel = surfaceGui:FindFirstChild("TextLabel")
if not textLabel then
    textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)  -- Fill the entire surface
    textLabel.BackgroundTransparency = 0.3
    textLabel.BackgroundColor3 = Color3.new(0, 0, 0)  -- Semi-transparent black
    textLabel.TextColor3 = Color3.new(1, 1, 1)  -- White text
    textLabel.TextScaled = true  -- Auto-size text to fit
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = surfaceGui
end

-- Update the label with destination name
local function updateLabel()
    if target.Value then
        textLabel.Text = "→ " .. target.Value.Name
    else
        textLabel.Text = "No Destination"
    end
end

-- Update immediately and whenever target changes
updateLabel()
target.Changed:Connect(updateLabel)
```

**More ideas:** Color-code each portal and its label to match the destination zone, or add icons for different area types.

---

## 2) Key-locked portal

**The idea:** Portal only works if you have the right key. Great for progression systems and secret areas.

**Why it works:** Creates natural game progression. Players feel rewarded when they finally unlock new areas.

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

## 3) Portal with arrival effects

**The idea:** Teleporter that plays a sound and shows a quick visual effect when you arrive, making teleportation feel more satisfying.

**Why it works:** Just a little audio-visual feedback makes teleportation feel way more polished and satisfying to use.

**Setup:**
1. Use Step 02 (`steps/02-remoteevent.lua`) 
2. Add a RemoteEvent named "Teleported" under each portal
3. Add this simple Script(RunContext=Client) for arrival effects

```lua
-- Simple teleportation effects (CLIENT SCRIPT)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Store original portal colors to avoid conflicts
local portalOriginalColors = {}

-- Function to create arrival effect
local function onPlayerTeleported(teleportedPlayer, sourcePortal, destinationPortal)
    -- Only show effects for this player
    if teleportedPlayer ~= player then return end
    
    -- Quick camera punch effect
    local camera = workspace.CurrentCamera
    local originalCFrame = camera.CFrame
    
    -- Single quick shake
    local shakeOffset = Vector3.new(
        math.random(-1, 1),
        math.random(-1, 1),
        math.random(-1, 1)
    )
    
    camera.CFrame = originalCFrame + shakeOffset
    
    -- Smoothly return to original position
    task.wait(0.1)
    camera.CFrame = originalCFrame
    
    -- Portal flash effect (store original color only once)
    if not portalOriginalColors[destinationPortal] then
        portalOriginalColors[destinationPortal] = destinationPortal.BrickColor
    end
    
    destinationPortal.BrickColor = BrickColor.new("Bright green")
    
    task.spawn(function()
        task.wait(0.15)
        destinationPortal.BrickColor = portalOriginalColors[destinationPortal]
    end)
end

-- Connect to your portal's RemoteEvent
local myPortal = workspace:FindFirstChild("Portal1")  -- Change this to your portal's name
if myPortal then
    local teleportEvent = myPortal:FindFirstChild("Teleported")
    if teleportEvent then
        teleportEvent.OnClientEvent:Connect(onPlayerTeleported)
    end
end
```

**More ideas:** Try different shake intensities or add a small particle burst at the destination.

---

Good teleporters don't just move players — they make travel feel intentional and exciting. Hide them behind challenges, use them to reward exploration, or make them part of the puzzle itself.
