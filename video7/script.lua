-- Coin Collector (simple)
-- Put this Script inside a coin Part (Cylinder or MeshPart). Optional Sound named "CollectSound".

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Tweak these
local ROTATE_RPS = 1.5 -- rotations per second
local COLLECT_TIME = 0.25 -- seconds
local COIN_VALUE = 1 -- leaderstats.Coins increment (if present)

local CollectSound = part:FindFirstChild("CollectSound")
local collecting = false

-- Spin continuously
local spinConn
spinConn = RunService.Heartbeat:Connect(function(dt)
    if not part.Parent then spinConn:Disconnect() return end
    local angle = ROTATE_RPS * 2 * math.pi * dt
    part.CFrame = part.CFrame * CFrame.Angles(0, angle, 0)
end)

local function collect(player)
    if collecting then return end
    collecting = true
    part.CanTouch = false

    if CollectSound and CollectSound:IsA("Sound") then CollectSound:Play() end

    -- Award one coin if leaderstats/Coins exists
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local coins = stats:FindFirstChild("Coins")
        if coins and typeof(coins.Value) == "number" then
            coins.Value = coins.Value + COIN_VALUE
        end
    end

    -- Shrink + fade, then destroy
    local goal = { Size = part.Size * 0.05, Transparency = 1 }
    local tween = TweenService:Create(part, TweenInfo.new(COLLECT_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In), goal)
    tween:Play()
    tween.Completed:Connect(function()
        if spinConn then spinConn:Disconnect() end
        part:Destroy()
    end)
end

part.Touched:Connect(function(hit)
    if collecting then return end
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if player then collect(player) end
end)