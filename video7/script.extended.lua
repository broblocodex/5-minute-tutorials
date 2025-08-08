-- Coin Collector (extended)
-- Adds Attributes, RemoteEvent, anti-dupe, optional auto-respawn.
-- Place this Script inside a coin Part. Optionally add a Sound named "CollectSound".

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Attributes ---------------------------------------------------------------
local function ensureAttr(name, value)
    if part:GetAttribute(name) == nil then part:SetAttribute(name, value) end
end

ensureAttr("CoinValue", 1)            -- How many coins to award
ensureAttr("RotateRPS", 1.5)          -- Rotations per second
ensureAttr("CollectTime", 0.25)       -- Shrink+fade seconds
ensureAttr("AutoRespawn", false)      -- If true, coin respawns after RespawnTime
ensureAttr("RespawnTime", 8)          -- Seconds before respawn
ensureAttr("LastUserId", 0)           -- For UI hooks
ensureAttr("LastCollectedAt", 0)      -- os.time()

-- RemoteEvent --------------------------------------------------------------
local event = part:FindFirstChild("CoinCollected")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "CoinCollected"
    event.Parent = part
end

local CollectSound = part:FindFirstChild("CollectSound")

-- Rotation -----------------------------------------------------------------
local spinConn
local function startSpin()
    if spinConn then spinConn:Disconnect() end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not part.Parent then spinConn:Disconnect() return end
        local angle = (part:GetAttribute("RotateRPS") or 1.5) * 2 * math.pi * dt
        part.CFrame = part.CFrame * CFrame.Angles(0, angle, 0)
    end)
end
startSpin()

-- Live tweak of spin speed
part:GetAttributeChangedSignal("RotateRPS"):Connect(function()
    -- nothing else needed; next heartbeat uses new value
end)

-- Collection ---------------------------------------------------------------
local collecting = false

local function award(player)
    local value = part:GetAttribute("CoinValue") or 1
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local coins = stats:FindFirstChild("Coins")
        if coins and typeof(coins.Value) == "number" then
            coins.Value = coins.Value + value
        end
    end
end

local function vanishAndMaybeRespawn()
    -- Cache properties
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
            -- hide, then respawn later
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

    award(player)
    part:SetAttribute("LastUserId", player.UserId)
    part:SetAttribute("LastCollectedAt", os.time())

    event:FireAllClients(player, part:GetAttribute("CoinValue") or 1)
    vanishAndMaybeRespawn()
end

part.Touched:Connect(function(hit)
    if collecting then return end
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if player then collect(player) end
end)

-- Cleanup spin on destroy
part.AncestryChanged:Connect(function(_, parent)
    if not parent and spinConn then spinConn:Disconnect() end
end)
