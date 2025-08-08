-- Magic Jump Pad (extended variations)
-- Adds: per-player cooldown, direction modes (up/forward), optional sound, RemoteEvent, and Attributes for easy hooks.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local pad = script.Parent
assert(pad and pad:IsA("BasePart"), "Place this script inside a Part")

-- Config
local POWER = 50
local CLEANUP = 0.5
local CLICK_RANGE = 28
local COOLDOWN = 0.8 -- seconds per player
local MODE = "up" -- "up" | "forward"
local ENABLE_SOUND = false
local SET_ATTRIBUTES = true

-- Optional attachments
local launchSound = pad:FindFirstChildOfClass("Sound")
local remote = pad:FindFirstChild("Launched") -- RemoteEvent (optional). Contract: FireAllClients(pad, player, velocity)

-- State
local last = {} -- UserId -> os.clock()

-- Helpers
local function canLaunch(player)
    if not player then return false end
    local t = os.clock()
    local prev = last[player.UserId]
    if prev and (t - prev) < COOLDOWN then return false end
    last[player.UserId] = t
    return true
end

-- Returns target linear velocity and MaxForce per axis
local function computeVelocity(root)
    if MODE == "forward" then
        local look = root.CFrame.LookVector
        return look * POWER + Vector3.new(0, POWER * 0.6, 0), Vector3.new(4000, math.huge, 4000)
    end
    return Vector3.new(0, POWER, 0), Vector3.new(0, math.huge, 0)
end

local function launchFor(player, root)
    local vel, maxF = computeVelocity(root)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = vel
    bv.MaxForce = maxF
    bv.Parent = root
    Debris:AddItem(bv, CLEANUP)

    if ENABLE_SOUND and launchSound then launchSound:Play() end
    if SET_ATTRIBUTES then
        pad:SetAttribute("LastUserId", player.UserId)
        pad:SetAttribute("LastVelocityY", vel.Y)
    end
    if remote then remote:FireAllClients(pad, player, vel) end

    pad.BrickColor = BrickColor.new("Lime green")
    task.delay(0.1, function()
        if pad.Parent then pad.BrickColor = BrickColor.new("Bright yellow") end
    end)
end

local function onTouched(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if not canLaunch(player) then return end
    local root = hum.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end
    launchFor(player, root)
end

pad.BrickColor = BrickColor.new("Bright yellow")
pad.Material = Enum.Material.Neon

local touchedConn = pad.Touched:Connect(onTouched)
pad.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchedConn then touchedConn:Disconnect() end
end)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = CLICK_RANGE
clickDetector.Parent = pad
clickDetector.MouseClick:Connect(function(player)
    if not canLaunch(player) then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then launchFor(player, root) end
end)
