-- Step 02 — BridgeState RemoteEvent
-- What: fire a RemoteEvent named "BridgeState" on warn/vanish/respawn.
-- Why: clients can show countdowns and VFX without changing the server script.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local disappearDelay = part:GetAttribute("DisappearDelay") or 1.0
local respawnDelay   = part:GetAttribute("RespawnDelay") or 3.0
local fadeTime       = part:GetAttribute("FadeTime") or 0.4

part.CanCollide = true
part.Transparency = 0

local bridgeState = part:FindFirstChild("BridgeState")
if not bridgeState then
    bridgeState = Instance.new("RemoteEvent")
    bridgeState.Name = "BridgeState"
    bridgeState.Parent = part
end

local warnSound = part:FindFirstChild("WarnSound")
local respawnSound = part:FindFirstChild("RespawnSound")

local function makeTweens()
    return TweenService:Create(part, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }),
           TweenService:Create(part, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 0 })
end

local fadeOut, fadeIn = makeTweens()
local busyByCharacter = {}

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

local function warnClients()
    if warnSound and warnSound:IsA("Sound") then warnSound:Play() end
    bridgeState:FireAllClients("warn")
end

local function vanishFor(character)
    if busyByCharacter[character] then return end
    busyByCharacter[character] = true

    local player = Players:GetPlayerFromCharacter(character)
    if player then
        part:SetAttribute("LastUserId", player.UserId)
        part:SetAttribute("LastTouchedAt", os.time())
    end

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

    busyByCharacter[character] = nil
end

part.Touched:Connect(function(hit)
    local character = hit.Parent
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    vanishFor(character)
end)


