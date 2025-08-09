-- Spinning Platform
-- Put this Script inside a Part. It'll spin forever around the chosen axis.

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Tweak these to change the spin behavior
local SECONDS_PER_TURN = 2  -- Lower number = faster spinning
local AXIS = "Y"            -- "X", "Y", or "Z" - which way it rotates

-- Make it look cool and stay in place
part.Anchored = true
part.Material = Enum.Material.Neon

-- Convert degrees to the right rotation for our chosen axis
local function axisRotation(degrees)
    local radians = math.rad(degrees)
    if AXIS == "X" then 
        return CFrame.Angles(radians, 0, 0)
    elseif AXIS == "Y" then 
        return CFrame.Angles(0, radians, 0)
    elseif AXIS == "Z" then 
        return CFrame.Angles(0, 0, radians)
    else 
        return CFrame.Angles(0, radians, 0)  -- Default to Y if something's wrong
    end
end

-- Set up the infinite spinning tween
-- -1 for RepeatCount means "repeat forever"
local tweenInfo = TweenInfo.new(
    SECONDS_PER_TURN,                    -- Duration
    Enum.EasingStyle.Linear,             -- Constant speed (no acceleration)
    Enum.EasingDirection.InOut,          -- Doesn't matter for Linear
    -1                                   -- Repeat forever
)

-- Create the tween that rotates the part 360 degrees from its current position
local tween = TweenService:Create(
    part, 
    tweenInfo, 
    { CFrame = part.CFrame * axisRotation(360) }
)

-- Start spinning!
tween:Play()
