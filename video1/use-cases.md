# Real-World examples

Time to steal some ideas. You've got a block that changes colors — now let's turn it into features players actually care about.

**Important:** Each snippet goes in its own Script. Don't try to mash them together.

---

## 1) Secret Portal (Color Code Lock)

**The idea:** Players need to set the block to a specific color to unlock a hidden door or portal. Think escape rooms, puzzle games, or hidden areas.

**Why it's cool:** Everyone loves secrets. Plus, you can chain multiple blocks for complex codes.

**Setup:**
1. Use Step 02 (`steps/02-attributes.lua`) or later
2. Add a portal Part(name "Portal") with `CanCollide=false` and `Transparency=1`
3. Put both under one Model, add this Script to the portal block

```lua
local portal = script.Parent
local part = portal.Parent:WaitForChild("ColorBlock")

local TARGET_COLOR = 4 -- Change this to whatever color unlocks the portal

part:GetAttributeChangedSignal("ColorIndex"):Connect(function()
    local currentColor = part:GetAttribute("ColorIndex")
    
    if currentColor == TARGET_COLOR then
        -- Portal appears!
        portal.CanCollide = true
        portal.Transparency = 0
        print("Portal activated!") -- Nice for debugging
    else
        -- Portal hidden
        portal.CanCollide = false
        portal.Transparency = 1
    end
end)
```

**More ideas:** Use 3-4 blocks with different target colors for a proper code sequence.

---

## 2) Speed boost pad

**The idea:** The last player who touched the color block gets a speed boost when they step on a nearby boost pad. Perfect for racing games or competitive elements.

**Why it's brilliant:** Creates interesting player interactions. "Quick, touch the block before someone else does!"

**Setup:**
1. Use Step 03 (`steps/03-last-user-id.lua`) on your color block
2. Create a separate BoostPad Part  
3. Put this Script inside the BoostPad Part
4. Make sure the color block is a sibling named "ColorBlock"

```lua
local boostPad = script.Parent
local colorBlock = boostPad.Parent and boostPad.Parent:FindFirstChild("ColorBlock") or boostPad

local SPEED_BOOST = 8  -- How much faster they go
local BOOST_DURATION = 3  -- How long it lasts
local activeBoosters = {}  -- Keep track of who's currently boosted

boostPad.Touched:Connect(function(hit)
    -- Get the player who stepped on the pad
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
    if not player then return end
    
    -- Check if this player was the last one to touch the color block
    local lastUserId = colorBlock:GetAttribute("LastUserId")
    if lastUserId ~= player.UserId then return end
    
    -- Prevent double-boosting
    if activeBoosters[humanoid] then
        activeBoosters[humanoid].expire = os.clock() + BOOST_DURATION
        return
    end
    
    -- Apply the boost!
    local originalSpeed = humanoid.WalkSpeed
    activeBoosters[humanoid] = {
        original = originalSpeed,
        expire = os.clock() + BOOST_DURATION
    }
    
    humanoid.WalkSpeed = originalSpeed + SPEED_BOOST
    print(player.Name .. " got a speed boost!")
    
    -- Remove boost after duration
    task.spawn(function()
        while activeBoosters[humanoid] and os.clock() < activeBoosters[humanoid].expire do
            task.wait(0.1)
        end
        
        if activeBoosters[humanoid] and humanoid.Parent then
            humanoid.WalkSpeed = activeBoosters[humanoid].original
            activeBoosters[humanoid] = nil
        end
    end)
end)
```

**More ideas:** Place multiple boost pads around the area, but only one color block.

---

## 3) Synchronized lamps

**The idea:** Every time someone changes the color block, all lamps in the area change to match. Great for ambient lighting or visual feedback systems.

**Why it works:** Players love immediate visual feedback. It makes the world feel alive and responsive.

**Setup:**
1. Use Step 04 (`steps/04-remoteevent.lua`) on your color block
2. Create a detached Attachment (name "LampAttachment") (place it anywhere in 3D space). (if it's still in Beta, make sure it's enabled in studio)
3. Create a lamp Part as a child of LampAttachment (name "Lamp")
4. Put this Script(RunContext=Local) inside the LampAttachment
5. Make sure the ColorBlock is a sibling of LampAttachment

```lua
-- This runs on each player's computer, so everyone sees the same effect
local lamp = script.Parent:WaitForChild("Lamp")
local colorBlock = script.Parent.Parent:WaitForChild("ColorBlock")

local colorChangedEvent = colorBlock:WaitForChild("ColorChanged")

-- Function to sync the lamp color with the block
local function syncLampColor()
	lamp.Color = colorBlock.Color
	-- Bonus: add some sparkle effects here if you want
end

-- Listen for color changes from the server
colorChangedEvent.OnClientEvent:Connect(function(changedPart, colorIndex)
	if changedPart == colorBlock then
		syncLampColor()
	end
end)

-- Sync on first join
syncLampColor()
```
---

## 4) Ownership display

**The idea:** When players touch the block, their name appears on a nearby display. Last toucher "owns" the block until someone else takes it.

**Perfect for:** Territory control, base claiming, leaderboard systems.

**Setup:**
1. Use Step 04 (`steps/04-remoteevent.lua`) on your color block
2. Create a detached Attachment (place it anywhere in 3D space). (if it's still in Beta, make sure it's enabled in studio)
3. Add a BillboardGui as a child of the Attachment with a TextLabel
4. Put this LocalScript inside the BillboardGui
5. Make sure the ColorBlock is accessible (adjust the path as needed)

```lua
local Players = game:GetService("Players")

local billboardGui = script.Parent
local textLabel = billboardGui:WaitForChild("TextLabel")

-- Find the ColorBlock (adjust path as needed for your setup)
local colorBlock = workspace:WaitForChild("ColorBlock")
local colorChangedEvent = colorBlock:WaitForChild("ColorChanged")

-- Update the display with current owner
local function updateOwnerDisplay()
    local lastUserId = colorBlock:GetAttribute("LastUserId")
    
    if lastUserId then
        -- Try to get the player's current display name
        local player = Players:GetPlayerByUserId(lastUserId)
        if player then
            textLabel.Text = "Owned by " .. player.DisplayName
            textLabel.TextColor3 = Color3.new(0, 1, 0)  -- Green for active
        else
            textLabel.Text = "Owned by [Player Left]"
            textLabel.TextColor3 = Color3.new(1, 1, 0)  -- Yellow for offline
        end
    else
        textLabel.Text = "Unclaimed"
        textLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)  -- Gray for unclaimed
    end
end

-- Listen for ownership changes
colorChangedEvent.OnClientEvent:Connect(function(changedPart, colorIndex)
    if changedPart == colorBlock then
        updateOwnerDisplay()
    end
end)

-- Set initial display
updateOwnerDisplay()
```

---


The beauty of this system is its simplicity. Master these patterns, and you can build almost any interactive system your game needs.
