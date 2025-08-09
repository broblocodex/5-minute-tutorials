-- Step 01 — Clickable Speed Control + Live Attributes
-- Problem: You want to change spin speed/direction without editing code every time
-- Solution: Attributes for live control + click-to-cycle speed presets

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Speed presets that players can cycle through by clicking
local SPEED_PRESETS = {0.5, 1, 2, 4}  -- seconds per full rotation
local DEFAULT_PRESET = 3  -- Start with 2 seconds (nice and visible)
local CLICK_RANGE = 40    -- How close you need to be to click it

-- Get current settings from attributes (or use defaults)
local currentTween = nil
local speedSec = part:GetAttribute("SpeedSec") or SPEED_PRESETS[DEFAULT_PRESET]
local axis = part:GetAttribute("Axis") or "Y"
local direction = part:GetAttribute("Direction") or 1  -- 1 or -1 for reverse

part.Anchored = true
part.Material = Enum.Material.Neon

local function axisRotation(degrees)
    local radians = math.rad(degrees)
    if axis == "X" then return CFrame.Angles(radians, 0, 0)
    elseif axis == "Y" then return CFrame.Angles(0, radians, 0)
    elseif axis == "Z" then return CFrame.Angles(0, 0, radians)
    else return CFrame.Angles(0, radians, 0) end
end

local function stopCurrentSpin()
    if currentTween then 
        currentTween:Cancel()
        currentTween = nil 
    end
end

-- Start spinning with current settings
local function startSpin()
    stopCurrentSpin()
    
    -- Update attributes so other scripts can see current settings
    part:SetAttribute("SpeedSec", speedSec)
    part:SetAttribute("Axis", axis)
    part:SetAttribute("Direction", direction)
    
    -- Create the rotation target (accounting for direction)
    local targetRotation = part.CFrame * axisRotation(360 * direction)
    local tweenInfo = TweenInfo.new(speedSec, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
    
    currentTween = TweenService:Create(part, tweenInfo, { CFrame = targetRotation })
    currentTween:Play()
end

-- Set up click-to-cycle-speed functionality
local clickDetector = part:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
    clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = CLICK_RANGE
    clickDetector.Parent = part
end

-- Track which preset we're currently using
local currentPresetIndex = table.find(SPEED_PRESETS, speedSec) or DEFAULT_PRESET

clickDetector.MouseClick:Connect(function()
    -- Cycle to next speed preset
    currentPresetIndex = currentPresetIndex + 1
    if currentPresetIndex > #SPEED_PRESETS then 
        currentPresetIndex = 1  -- Loop back to fastest
    end
    
    speedSec = SPEED_PRESETS[currentPresetIndex]
    startSpin()  -- Apply the new speed
end)

-- Start the initial spin
startSpin()
