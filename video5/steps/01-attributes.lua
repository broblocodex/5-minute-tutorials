-- Step 01 — Attributes for live tuning
-- What: expose DisappearDelay, RespawnDelay, and FadeTime as Attributes and react to changes.
-- Why: lets you tweak difficulty and pacing without editing code; other scripts can drive timing.

local TweenService = game:GetService("TweenService")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local disappearDelay = part:GetAttribute("DisappearDelay") or 1.0
local respawnDelay   = part:GetAttribute("RespawnDelay") or 3.0
local fadeTime       = part:GetAttribute("FadeTime") or 0.4

part.CanCollide = true
part.Transparency = 0

local function makeTweens()
    return TweenService:Create(part, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }),
           TweenService:Create(part, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 0 })
end

local fadeOut, fadeIn = makeTweens()
local busy = false

part:GetAttributeChangedSignal("DisappearDelay"):Connect(function()
    local v = part:GetAttribute("DisappearDelay")
    if typeof(v) == "number" and v >= 0 then disappearDelay = v end
end)

part:GetAttributeChangedSignal("RespawnDelay"):Connect(function()
    local v = part:GetAttribute("RespawnDelay")
    if typeof(v) == "number" and v >= 0 then respawnDelay = v end
end)

part:GetAttributeChangedSignal("FadeTime"):Connect(function()
    local v = part:GetAttribute("FadeTime")
    if typeof(v) == "number" and v > 0 then
        fadeTime = v
        fadeOut, fadeIn = makeTweens()
    end
end)

local function vanishAndRespawn()
    if busy then return end
    busy = true
    task.wait(disappearDelay)

    fadeOut:Play(); fadeOut.Completed:Wait()
    part.CanCollide = false

    task.wait(respawnDelay)
    part.CanCollide = true

    fadeIn:Play(); fadeIn.Completed:Wait()
    busy = false
end

part.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if hum then vanishAndRespawn() end
end)


