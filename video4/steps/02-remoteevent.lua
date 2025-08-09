-- Step 02 — RemoteEvent (SpinChanged)
-- What: fire a RemoteEvent named "SpinChanged" whenever spin parameters change.
-- Why: clients can do VFX/UI (danger flash, HUD) without changing server code.

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local PRESETS = {0.5, 1, 2, 4}
local START_INDEX = 3
local CLICK_RANGE = 40

local currentTween = nil
local speedSec = part:GetAttribute("SpeedSec") or PRESETS[START_INDEX]
local axis = part:GetAttribute("Axis") or "Y"
local direction = part:GetAttribute("Direction") or 1

-- Visual
part.Anchored = true
part.Material = Enum.Material.Neon

-- RemoteEvent
local spinChanged = part:FindFirstChild("SpinChanged")
if not spinChanged then
    spinChanged = Instance.new("RemoteEvent")
    spinChanged.Name = "SpinChanged"
    spinChanged.Parent = part
end

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
    spinChanged:FireAllClients(speedSec, axis, direction)
end

-- Attribute live edits
part:GetAttributeChangedSignal("SpeedSec"):Connect(function()
    local v = part:GetAttribute("SpeedSec")
    if typeof(v) == "number" and v > 0 then
        speedSec = v
        startTween()
    end
end)

part:GetAttributeChangedSignal("Axis"):Connect(function()
    local v = part:GetAttribute("Axis")
    if v == "X" or v == "Y" or v == "Z" then
        axis = v
        startTween()
    end
end)

part:GetAttributeChangedSignal("Direction"):Connect(function()
    local v = part:GetAttribute("Direction")
    if v == 1 or v == -1 then
        direction = v
        startTween()
    end
end)

-- Click to cycle speed
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


