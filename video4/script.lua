-- Spinning Platform
-- Put this Script inside a Part. It'll spin forever around the chosen axis.

local STEP_DEGREES = 120        -- Degrees per tween step (smaller = smoother, more tweens)
local AXIS = "Y"                -- Axis to rotate around: "X", "Y", or "Z"
local SECONDS_PER_TURN = 2      -- Seconds for one full rotation (lower = faster)

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

-- Make it look cool and stay in place
part.Anchored = true
part.Material = Enum.Material.Neon

-- Store the original CFrame
local originalCFrame = part.CFrame
local currentAngle = 0

-- Convert degrees to the right rotation for our chosen axis
local function axisRotation(degrees)
    local radians = math.rad(degrees)
    if AXIS == "X" then return CFrame.Angles(radians, 0, 0)
    elseif AXIS == "Y" then return CFrame.Angles(0, radians, 0)
    elseif AXIS == "Z" then return CFrame.Angles(0, 0, radians)
    else return CFrame.Angles(0, radians, 0) end
end

-- Create spinning function that uses smaller rotation steps
local function spin()
    -- Calculate duration for this step based on the fraction of a full turn
    local duration = SECONDS_PER_TURN * (STEP_DEGREES / 360)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local nextAngle = currentAngle + STEP_DEGREES
    local tween = TweenService:Create(part, tweenInfo, {
        CFrame = originalCFrame * axisRotation(nextAngle)
    })
    
    tween.Completed:Once(function()
        currentAngle = nextAngle % 360  -- Keep angle within 0-360 range
        spin()  -- Continue spinning
    end)
    
    tween:Play()
end

-- Start the spinning
spin()
