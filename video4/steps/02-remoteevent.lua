-- Step 02 — Network Events for Client Effects
-- Problem: You want visual/audio feedback when spin changes, but only on player screens
-- Solution: Fire RemoteEvent when parameters change so LocalScripts can react

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local SPEED_PRESETS = {0.5, 1, 2, 4}
local DEFAULT_PRESET = 3
local CLICK_RANGE = 40

local currentTween = nil
local speedSec = part:GetAttribute("SpeedSec") or SPEED_PRESETS[DEFAULT_PRESET]
local axis = part:GetAttribute("Axis") or "Y"
local direction = part:GetAttribute("Direction") or 1

part.Anchored = true
part.Material = Enum.Material.Neon

-- Create RemoteEvent for notifying clients about spin changes
local spinChangedEvent = part:FindFirstChild("SpinChanged")
if not spinChangedEvent then
    spinChangedEvent = Instance.new("RemoteEvent")
    spinChangedEvent.Name = "SpinChanged"
    spinChangedEvent.Parent = part
end

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

local function startSpin()
    stopCurrentSpin()
    
    part:SetAttribute("SpeedSec", speedSec)
    part:SetAttribute("Axis", axis)
    part:SetAttribute("Direction", direction)
    
    local targetRotation = part.CFrame * axisRotation(360 * direction)
    local tweenInfo = TweenInfo.new(speedSec, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
    
    currentTween = TweenService:Create(part, tweenInfo, { CFrame = targetRotation })
    currentTween:Play()
    
    -- Notify all clients that spin parameters changed
    spinChangedEvent:FireAllClients(speedSec, axis, direction)
end

-- Listen for live attribute changes from other scripts
part:GetAttributeChangedSignal("SpeedSec"):Connect(function()
    local newSpeed = part:GetAttribute("SpeedSec")
    if typeof(newSpeed) == "number" and newSpeed > 0 then
        speedSec = newSpeed
        startSpin()
    end
end)

part:GetAttributeChangedSignal("Axis"):Connect(function()
    local newAxis = part:GetAttribute("Axis")
    if newAxis == "X" or newAxis == "Y" or newAxis == "Z" then
        axis = newAxis
        startSpin()
    end
end)

part:GetAttributeChangedSignal("Direction"):Connect(function()
    local newDirection = part:GetAttribute("Direction")
    if newDirection == 1 or newDirection == -1 then
        direction = newDirection
        startSpin()
    end
end)

local clickDetector = part:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
    clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = CLICK_RANGE
    clickDetector.Parent = part
end

local currentPresetIndex = table.find(SPEED_PRESETS, speedSec) or DEFAULT_PRESET
clickDetector.MouseClick:Connect(function()
    currentPresetIndex = currentPresetIndex + 1
    if currentPresetIndex > #SPEED_PRESETS then 
        currentPresetIndex = 1
    end
    speedSec = SPEED_PRESETS[currentPresetIndex]
    startSpin()
end)

startSpin()
