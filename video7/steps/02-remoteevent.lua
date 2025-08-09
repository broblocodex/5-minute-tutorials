-- Step 02 — RemoteEvent (CoinCollected)
-- What: fire a RemoteEvent named "CoinCollected" with (player, value) when collected.
-- Why: clients can drive combo meters, progress bars, sounds, and analytics.

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function ensureAttr(name, value)
    if part:GetAttribute(name) == nil then part:SetAttribute(name, value) end
end

ensureAttr("CoinValue", 1)
ensureAttr("RotateRPS", 1.5)
ensureAttr("CollectTime", 0.25)
ensureAttr("AutoRespawn", false)
ensureAttr("RespawnTime", 8)
ensureAttr("LastUserId", 0)
ensureAttr("LastCollectedAt", 0)

local event = part:FindFirstChild("CoinCollected")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "CoinCollected"
    event.Parent = part
end

local CollectSound = part:FindFirstChild("CollectSound")
local collecting = false

local spinConn = RunService.Heartbeat:Connect(function(dt)
    if not part.Parent then spinConn:Disconnect() return end
    local angle = (part:GetAttribute("RotateRPS") or 1.5) * 2 * math.pi * dt
    part.CFrame = part.CFrame * CFrame.Angles(0, angle, 0)
end)

local function award(player)
    local value = part:GetAttribute("CoinValue") or 1
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local coins = stats:FindFirstChild("Coins")
        if coins and typeof(coins.Value) == "number" then
            coins.Value = coins.Value + value
        end
    end
    return value
end

local function vanishAndMaybeRespawn()
    local originalSize = part.Size
    local originalTransparency = part.Transparency
    local originalCanTouch = part.CanTouch
    part.CanTouch = false

    local time = part:GetAttribute("CollectTime") or 0.25
    local tween = TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = originalSize * 0.05,
        Transparency = 1
    })
    tween:Play()

    tween.Completed:Connect(function()
        if not (part and part.Parent) then return end
        if part:GetAttribute("AutoRespawn") then
            part.Transparency = 1
            part.CanTouch = false
            task.delay(part:GetAttribute("RespawnTime") or 8, function()
                if not (part and part.Parent) then return end
                part.Size = originalSize
                part.Transparency = originalTransparency
                part.CanTouch = originalCanTouch
                collecting = false
            end)
        else
            if spinConn then spinConn:Disconnect() end
            part:Destroy()
        end
    end)
end

local function collect(player)
    if collecting then return end
    collecting = true
    if CollectSound and CollectSound:IsA("Sound") then CollectSound:Play() end
    local value = award(player)
    part:SetAttribute("LastUserId", player.UserId)
    part:SetAttribute("LastCollectedAt", os.time())
    event:FireAllClients(player, value)
    vanishAndMaybeRespawn()
end

part.Touched:Connect(function(hit)
    if collecting then return end
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if player then collect(player) end
end)


