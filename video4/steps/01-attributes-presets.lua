-- Step 01 - Clickable Speed Control
-- Problem: You want to change spin speed without editing the script each time.
-- Solution: Add click-to-cycle presets (no attributes yet — those come later).

local STEP_DEGREES = 120
local AXIS = "Y"

-- Click speed control config
local SPEED_PRESETS = {0.5, 1, 2, 4}
local DEFAULT_PRESET = 3
local CLICK_RANGE = 40

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local currentTween = nil          -- Track active tween so we can cancel when speed changes
local secondsPerTurn = SPEED_PRESETS[DEFAULT_PRESET]  -- Current selected speed (seconds per full spin)

part.Anchored = true
part.Material = Enum.Material.Neon

-- Set initial speed attribute
part:SetAttribute("SpeedSec", secondsPerTurn)

local function axisRotation(degrees)
    local radians = math.rad(degrees)
    if AXIS == "X" then return CFrame.Angles(radians, 0, 0)
    elseif AXIS == "Y" then return CFrame.Angles(0, radians, 0)
    elseif AXIS == "Z" then return CFrame.Angles(0, 0, radians)
    else return CFrame.Angles(0, radians, 0) end
end

-- Stop any current spin tween
local function stopCurrentSpin()
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
end

-- Perform one step of rotation, then repeat
local function spin()
	local duration = secondsPerTurn * (STEP_DEGREES / 360)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)

	-- Rotate relative to current position (prevents snapping/freezing on click)
	local target = part.CFrame * axisRotation(STEP_DEGREES)

	currentTween = TweenService:Create(part, tweenInfo, { CFrame = target })
	currentTween.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			spin()
		end
	end)
	currentTween:Play()
end

-- Restart spinning with new speed
local function restartSpin()
	stopCurrentSpin()
	spin()
end

-- Click-to-cycle-speed functionality
local clickDetector = part:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
	clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = CLICK_RANGE
	clickDetector.Parent = part
end

-- Track which preset we're using
local currentPresetIndex = DEFAULT_PRESET

clickDetector.MouseClick:Connect(function()
	currentPresetIndex += 1
	if currentPresetIndex > #SPEED_PRESETS then
		currentPresetIndex = 1
	end
	secondsPerTurn = SPEED_PRESETS[currentPresetIndex]
	part:SetAttribute("SpeedSec", secondsPerTurn)  -- Update attribute when speed changes
	restartSpin()
end)

spin()
