# Real-World examples

Time to steal some ideas. You've got a spinning platform — now let's turn it into features that make games memorable.

**Important:** Each snippet goes in its own Script. Don't try to mash them together — that way lies confusion and bugs.

---

## 1) Progressive nightmare obby

**The idea:** Every time someone touches a ProximityPrompt on the platform, it spins faster. Turn a simple spinning platform into an escalating challenge that gets harder with each attempt.

**Why it's brilliant:** Creates natural difficulty ramping. Early players get an easier experience, but as more people play, it becomes a proper test of skill.

**Setup:**
1. Use Step 01 (`steps/01-attributes-presets.lua`) 
2. Add a ProximityPrompt to the spinning platform
3. Put this Script in ServerScriptService

```lua
local spinner = workspace:WaitForChild("Spinner")  -- Adjust path as needed
local prompt = spinner:WaitForChild("ProximityPrompt")

prompt.Triggered:Connect(function(player)
    local currentSpeed = spinner:GetAttribute("SpeedSec") or 2
    local newSpeed = currentSpeed * 0.8  -- Each use makes it 20% faster
    
    -- Don't let it get impossibly fast
    newSpeed = math.max(0.4, newSpeed)
    spinner:SetAttribute("SpeedSec", newSpeed)
    
    print(player.Name .. " made it " .. math.floor((2/newSpeed) * 100) .. "% harder!")
end)
```

**More ideas:** Add a leaderboard showing who made it the hardest, or reset the difficulty every hour.

---

## 2) Team rivalry spinner

**The idea:** A central control button that speeds up your team's spinner and slows down the enemy team's spinner. Creates instant strategic advantage when you reach it first.

**Why it works:** Players race to control the button. Whoever clicks it gets faster practice while making the other team's training harder.

**Setup:**
1. Create two spinning platforms: "BlueSpinner" and "RedSpinner"
2. Create a control button part: "ControlButton" 
3. Use Step 01 (`steps/01-attributes-presets.lua`) on both spinners
4. Add this Script to the ControlButton

```lua
-- Put this Script inside the ControlButton part
local Teams = game:GetService("Teams")
local controlButton = script.Parent

local blueSpinner = workspace:WaitForChild("BlueSpinner")
local redSpinner = workspace:WaitForChild("RedSpinner")

-- Make it clickable
local clickDetector = Instance.new("ClickDetector")
clickDetector.Parent = controlButton

clickDetector.MouseClick:Connect(function(player)
    if not player.Team then return end  -- Player must be on a team
    
    if player.Team.Name == "Blue" then
        -- Blue team clicked: speed up blue, slow down red
        blueSpinner:SetAttribute("SpeedSec", 0.8)   -- Faster spin
        redSpinner:SetAttribute("SpeedSec", 3.0)    -- Slower spin
        
        -- Visual feedback
        controlButton.Color = Color3.new(0, 0, 1)   -- Flash blue
        print(player.Name .. " gave Blue team the advantage!")
        
    elseif player.Team.Name == "Red" then
        -- Red team clicked: speed up red, slow down blue
        redSpinner:SetAttribute("SpeedSec", 0.8)    -- Faster spin
        blueSpinner:SetAttribute("SpeedSec", 3.0)   -- Slower spin
        
        -- Visual feedback  
        controlButton.Color = Color3.new(1, 0, 0)   -- Flash red
        print(player.Name .. " gave Red team the advantage!")
    end
    
    -- Reset button color after flash
    task.delay(1, function()
        controlButton.Color = Color3.new(0.5, 0.5, 0.5)  -- Back to gray
    end)
end)
```

**More ideas:** Add a cooldown so the same team can't spam-click, or make the effect fade back to normal speed after 30 seconds.

---

## 3) Screenshot showcase pedestal

**The idea:** Slow, elegant spinning for displaying special items or achievements. Players can switch between X, Y, Z rotation with a simple GUI for the perfect angle.

**Why it's genius:** Turns functional spinning into a presentation tool. Perfect for showing off rare items, trophies, or build showcases.

**Setup:**
1. Use Step 01 (`steps/01-attributes-presets.lua`) for the spinner
2. Create a ScreenGui with axis buttons in StarterPlayerScripts
3. Use Step 02 (`steps/02-remoteevent.lua`) to let clients control it

```lua
-- LocalScript in StarterPlayerScripts for the control GUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create simple GUI
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local xButton = Instance.new("TextButton")
local yButton = Instance.new("TextButton") 
local zButton = Instance.new("TextButton")

screenGui.Parent = playerGui
frame.Parent = screenGui
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(1, -220, 0, 20)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.3

-- Set up buttons
local buttons = {xButton, yButton, zButton}
local axes = {"X", "Y", "Z"}

for i, button in pairs(buttons) do
    button.Parent = frame
    button.Size = UDim2.new(0, 60, 0, 30)
    button.Position = UDim2.new(0, (i-1) * 65 + 5, 0, 5)
    button.Text = axes[i] .. " Spin"
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    button.TextColor3 = Color3.new(1, 1, 1)
    
    button.MouseButton1Click:Connect(function()
        local controlEvent = ReplicatedStorage:WaitForChild("ControlSpin")
        controlEvent:FireServer(workspace.Spinner, {
            SpeedSec = 4,  -- Nice and slow for photos
            Axis = axes[i]
        })
    end)
end
```

**More ideas:** Add a "Stop" button that sets SpeedSec to 0 for perfect screenshots.

---

The secret to great spinning platforms? They're never just spinning for the sake of it. They're tools for creating tension, rewards, or pure chaos. Master these patterns and you can turn any rotation into a memorable game moment.
