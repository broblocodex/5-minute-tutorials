-- Step 01 — Per-player cooldown (anti-spam)
-- What: add a per-player cooldown so one user can't trigger the pad repeatedly in a short time.
-- Why: reduces chaos in lobbies/spawn areas and keeps the launch feeling intentional.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local pad = script.Parent
assert(pad and pad:IsA("BasePart"), "Place this script inside a Part")

local POWER = 50
local CLEANUP = 0.5
local CLICK_RANGE = 24
local COOLDOWN = 0.8 -- seconds per player

pad.BrickColor = BrickColor.new("Bright yellow")
pad.Material = Enum.Material.Neon

local lastLaunchAtByUserId = {}

local function canLaunch(player)
    if not player then return false end
    local now = os.clock()
    local prev = lastLaunchAtByUserId[player.UserId]
    if prev and (now - prev) < COOLDOWN then return false end
    lastLaunchAtByUserId[player.UserId] = now
    return true
end

local function launchFor(player, root)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Velocity = Vector3.new(0, POWER, 0)
    bv.Parent = root
    Debris:AddItem(bv, CLEANUP)

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


