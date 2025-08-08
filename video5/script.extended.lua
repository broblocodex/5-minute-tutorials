-- Disappearing Bridge (extended)
-- Attributes: DisappearDelay (number), RespawnDelay (number), FadeTime (number)
-- RemoteEvent: BridgeState(speed) -> FireAllClients(state: "warn"|"vanish"|"respawn")
-- Optional child Sounds: WarnSound, RespawnSound

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Defaults
local disappearDelay = part:GetAttribute("DisappearDelay") or 1.0
local respawnDelay   = part:GetAttribute("RespawnDelay") or 3.0
local fadeTime       = part:GetAttribute("FadeTime") or 0.4

-- Visual
part.CanCollide = true
part.Transparency = 0

-- Event for clients
local bridgeState = part:FindFirstChild("BridgeState")
if not bridgeState then
    bridgeState = Instance.new("RemoteEvent")
    bridgeState.Name = "BridgeState"
    bridgeState.Parent = part
end

-- Sounds (optional)
local warnSound = part:FindFirstChild("WarnSound")
local respawnSound = part:FindFirstChild("RespawnSound")

-- Tween makers (recreate when fadeTime changes)
local function makeTweens()
    return TweenService:Create(part, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }),
           TweenService:Create(part, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 0 })
end

local fadeOut, fadeIn = makeTweens()

-- React to live attribute changes
part:GetAttributeChangedSignal("DisappearDelay"):Connect(function()
    local v = part:GetAttribute("DisappearDelay")
    if typeof(v) == "number" and v >= 0 then
        disappearDelay = v
    end
end)

part:GetAttributeChangedSignal("RespawnDelay"):Connect(function()
    local v = part:GetAttribute("RespawnDelay")
    if typeof(v) == "number" and v >= 0 then
        respawnDelay = v
    end
end)

part:GetAttributeChangedSignal("FadeTime"):Connect(function()
    local v = part:GetAttribute("FadeTime")
    if typeof(v) == "number" and v > 0 then
        fadeTime = v
        fadeOut, fadeIn = makeTweens()
    end
end)

local busyByPlayer = {} -- per-player debounce (character)

local function canTriggerFrom(hit)
    local character = hit and hit.Parent
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    return character
end

local function warnClients()
    if warnSound and warnSound:IsA("Sound") then warnSound:Play() end
    bridgeState:FireAllClients("warn")
end

local function vanishFor(character)
    -- prevent spamming per-character
    if busyByPlayer[character] then return end
    busyByPlayer[character] = true

    -- write attributes (nice for other scripts)
    part:SetAttribute("LastUserId", Players:GetPlayerFromCharacter(character) and Players:GetPlayerFromCharacter(character).UserId or 0)
    part:SetAttribute("LastTouchedAt", os.time())

    warnClients()
    task.wait(disappearDelay)

    bridgeState:FireAllClients("vanish")
    fadeOut:Play(); fadeOut.Completed:Wait()
    part.CanCollide = false

    task.wait(respawnDelay)

    part.CanCollide = true
    if respawnSound and respawnSound:IsA("Sound") then respawnSound:Play() end
    bridgeState:FireAllClients("respawn")
    fadeIn:Play(); fadeIn.Completed:Wait()

    busyByPlayer[character] = nil
end

part.Touched:Connect(function(hit)
    local character = canTriggerFrom(hit)
    if not character then return end
    vanishFor(character)
end)

-- Cleanup
part.AncestryChanged:Connect(function(_, parent)
    if not parent and bridgeState then bridgeState:Destroy() end
end)
