-- Spinning Platform (simple)
-- How to use: put this Script inside a Part. It spins forever around AXIS.

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Tweak these
local SECONDS_PER_TURN = 2  -- lower = faster
local AXIS = "Y"            -- "X" | "Y" | "Z"

-- Visual
part.Anchored = true
part.Material = Enum.Material.Neon

local function axisRotation(deg)
    local r = math.rad(deg)
    if AXIS == "X" then return CFrame.Angles(r, 0, 0)
    elseif AXIS == "Y" then return CFrame.Angles(0, r, 0)
    elseif AXIS == "Z" then return CFrame.Angles(0, 0, r)
    else return CFrame.Angles(0, r, 0) end
end

local tweenInfo = TweenInfo.new(SECONDS_PER_TURN, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local tween = TweenService:Create(part, tweenInfo, { CFrame = part.CFrame * axisRotation(360) })
tween:Play()