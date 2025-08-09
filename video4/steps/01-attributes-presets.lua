-- Step 01 — Attributes + speed presets
-- What: expose spin config via Attributes and add click-to-cycle speed presets.
-- Why: lets other scripts/UI react and control the platform without editing this script.

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Presets and defaults
local PRESETS = {0.5, 1, 2, 4}
local START_INDEX = 3 -- 2 sec/turn
local CLICK_RANGE = 40

local currentTween = nil
local speedSec = part:GetAttribute("SpeedSec") or PRESETS[START_INDEX]
local axis = part:GetAttribute("Axis") or "Y"
local direction = part:GetAttribute("Direction") or 1 -- 1 or -1

-- Visual baseline
part.Anchored = true
part.Material = Enum.Material.Neon

local function axisRotation(deg)
    local r = math.rad(deg)
    if axis == "X" then return CFrame.Angles(r, 0, 0)
    elseif axis == "Y" then return CFrame.Angles(0, r, 0)
    elseif axis == "Z" then return CFrame.Angles(0, 0, r)
    else return CFrame.Angles(0, r, 0) end
end

local function stopTween()
    if currentTween then currentTween:Cancel(); currentTween = nil end
end

local function startTween()
    stopTween()
    part:SetAttribute("SpeedSec", speedSec)
    part:SetAttribute("Axis", axis)
    part:SetAttribute("Direction", direction)
    local target = part.CFrame * axisRotation(360 * (direction >= 0 and 1 or -1))
    local info = TweenInfo.new(speedSec, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
    currentTween = TweenService:Create(part, info, { CFrame = target })
    currentTween:Play()
end

-- Click to cycle speed presets
local clickDetector = part:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
    clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = CLICK_RANGE
    clickDetector.Parent = part
end

local presetIndex = table.find(PRESETS, speedSec) or START_INDEX
clickDetector.MouseClick:Connect(function()
    presetIndex = presetIndex + 1
    if presetIndex > #PRESETS then presetIndex = 1 end
    speedSec = PRESETS[presetIndex]
    startTween()
end)

-- Kick off
startTween()


