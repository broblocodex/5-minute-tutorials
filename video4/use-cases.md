# Real-World examples

Time to steal some ideas. You've got a platform that spins — now let's turn it into features players actually care about.

**Important:** Each snippet goes in its own Script. Don't try to mash them together.

---

## 1) Click-controlled speed challenge

**The idea:** Click the spinning platform to make it spin faster or slower. Simple speed control for players.

**Why it works:** Players can adjust the difficulty to their skill level. Click to cycle through speeds: slow → medium → fast → very fast.

**Setup:**
1. Use Step 01 (`steps/01-attributes-presets.lua`) - it already has click speed control
2. Add this LocalScript to StarterPlayerScripts to show speed on screen

```lua
-- LocalScript in StarterPlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local spinner = workspace:WaitForChild("Spinner")  -- Adjust path as needed

-- Create screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui

local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(0, 200, 0, 60)
speedFrame.Position = UDim2.new(0, 20, 0, 20)
speedFrame.BackgroundColor3 = Color3.new(0, 0, 0)
speedFrame.BackgroundTransparency = 0.3
speedFrame.BorderSizePixel = 0
speedFrame.Parent = screenGui

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Text = "Spinner: 2.0s per turn"
speedLabel.Parent = speedFrame

-- Update when speed changes
spinner:GetAttributeChangedSignal("SpeedSec"):Connect(function()
    local speed = spinner:GetAttribute("SpeedSec") or 2
    speedLabel.Text = "Spinner: " .. speed .. "s"
end)
```

**More ideas:** Add different colored lights for each speed, or make it play different sounds.

---

## 2) Deadly spinning blade

**The idea:** Touch the spinning platform and you die instantly. Turn your innocent spinner into a lethal obstacle that demands perfect timing and movement.

**Why it works:** Creates high-stakes gameplay where one mistake means starting over. The spinning motion makes the danger constantly moving and unpredictable.

**Setup:**
1. Use basic `script.lua` as your spinner base
2. Add this death script to the same spinner

```lua
-- Death Spinner - Touch = Death
local spinner = script.Parent

-- Make it look deadly
spinner.Color = Color3.new(1, 0, 0)  -- Blood red
spinner.Material = Enum.Material.Neon

-- The killing touch
spinner.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Health = 0  -- Instant death
        
        -- Optional: dramatic effect
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            print(player.Name .. " was eliminated by the spinning blade! ⚔️")
        end
    end
end)
```

**More ideas:** Add particle effects for sparks.

---

## 3) Simple touch counter

**The idea:** Each time someone touches the spinning platform, it counts up and displays the number. Simple but incredibly versatile for many game mechanics.

**Why it's brilliant:** Can be used for score systems, unlock conditions, community challenges, progress tracking, or any mechanic that needs to count player interactions.

**Setup:**
1. Use basic `script.lua` as your spinner base
2. Add this counting script to the same spinner

```lua
-- Touch Counter Spinner
local spinner = script.Parent
local touches = 0

-- Create floating display above spinner
local gui = Instance.new("BillboardGui")
gui.Size = UDim2.new(0, 200, 0, 50)
gui.StudsOffset = Vector3.new(0, 4, 0)  -- Float above spinner
gui.Parent = spinner

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "Touches: 0"
label.Parent = gui

-- Count touches
spinner.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        touches = touches + 1
        label.Text = "Touches: " .. touches
        
        -- Optional: announce milestones
        if touches % 10 == 0 then
            print("Spinner reached " .. touches .. " touches!")
        end
    end
end)
```

**More ideas:** Unlock doors at 50 touches, spawn rewards at 100 touches, change spinner speed based on touch count, or use multiple counters for team competition.

---

The best spinning platforms aren't just obstacles — they're tools for creating memorable moments. Whether it's escalating difficulty, team competition, or elegant presentation, the key is making the rotation serve a purpose that players actually care about.
