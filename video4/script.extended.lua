-- Spinning Platform (extended)
-- Copy into a Part. Click to cycle speeds. Change Attributes live.
-- Exposes Attributes: SpeedSec (number), Axis ("X"|"Y"|"Z"), Direction (1|-1)
-- Fires RemoteEvent "SpinChanged" on updates: (speedSec, axis, direction)

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Defaults
local PRESETS = {0.5, 1, 2, 4}
local START_INDEX = 3 -- 2 sec/turn
local CLICK_RANGE = 40

-- Internal state
local currentTween = nil
local speedSec = part:GetAttribute("SpeedSec") or PRESETS[START_INDEX]
local axis = part:GetAttribute("Axis") or "Y"
local direction = part:GetAttribute("Direction") or 1 -- 1 or -1

-- Visual baseline
part.Anchored = true
part.Material = Enum.Material.Neon

-- RemoteEvent (child of part)
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
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

local function startTween()
    stopTween()
    -- Store attributes for others to read
    part:SetAttribute("SpeedSec", speedSec)
    part:SetAttribute("Axis", axis)
    part:SetAttribute("Direction", direction)

    -- Recompute from current CFrame for seamless restart
    local target = part.CFrame * axisRotation(360 * (direction >= 0 and 1 or -1))
    local info = TweenInfo.new(speedSec, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
    currentTween = TweenService:Create(part, info, { CFrame = target })
    currentTween:Play()

    -- Optional: play a looped Sound named "SpinSound" under the part
    local spinSound = part:FindFirstChild("SpinSound")
    if spinSound and spinSound:IsA("Sound") then
        spinSound.Looped = true
        if not spinSound.IsPlaying then spinSound:Play() end
        -- Map speed to playback (faster spin → higher pitch)
        spinSound.PlaybackSpeed = math.clamp(2 / speedSec, 0.5, 3)
    end

    -- Notify clients
    spinChanged:FireAllClients(speedSec, axis, direction)
end

-- Attribute live edits (e.g., from command bar or another script)
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

-- Click to cycle speed presets
local clickDetector = part:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
    clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = CLICK_RANGE
    clickDetector.Parent = part
end

local presetIndex = table.find(PRESETS, speedSec) or START_INDEX
clickDetector.MouseClick:Connect(function(player)
    presetIndex = presetIndex + 1
    if presetIndex > #PRESETS then presetIndex = 1 end
    speedSec = PRESETS[presetIndex]
    startTween()
end)

-- Kick off
startTween()

-- Cleanup
part.AncestryChanged:Connect(function(_, parent)
    if not parent then
        stopTween()
        if spinChanged then spinChanged:Destroy() end
    end
end)
