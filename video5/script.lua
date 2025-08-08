-- Disappearing Bridge (simple)
-- Put this Script inside a bridge Part. It fades out on touch and comes back.

local TweenService = game:GetService("TweenService")
local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Tweak these
local DISAPPEAR_DELAY = 1.0   -- seconds before fade starts
local RESPAWN_DELAY = 3.0     -- seconds invisible before coming back
local FADE_TIME = 0.4         -- seconds to fade

-- Visual
part.CanCollide = true
part.Transparency = 0

local busy = false

local fadeOut = TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 })
local fadeIn  = TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 0 })

local function vanishAndRespawn()
    if busy then return end
    busy = true
    task.wait(DISAPPEAR_DELAY)

    fadeOut:Play()
    fadeOut.Completed:Wait()
    part.CanCollide = false

    task.wait(RESPAWN_DELAY)
    part.CanCollide = true

    fadeIn:Play()
    fadeIn.Completed:Wait()
    busy = false
end

part.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if hum then vanishAndRespawn() end
end)