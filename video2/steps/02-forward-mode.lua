-- Step 02 — Direction mode (up or forward)
-- What: add a MODE setting to launch either straight up or in the character's look direction.
-- Why: great for flow sections in speed runs or to guide players across gaps.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local pad = script.Parent
assert(pad and pad:IsA("BasePart"), "Place this script inside a Part")

local POWER = 50
local CLEANUP = 0.5
local CLICK_RANGE = 24
local COOLDOWN = 0.8 -- keep the per-player cooldown from Step 01
local MODE = "up" -- change to "forward" for the forward fling use-case

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

local function computeVelocity(root)
    if MODE == "forward" then
        local look = root.CFrame.LookVector
        local lateral = look * POWER
        local upward = Vector3.new(0, POWER * 0.6, 0)
        return lateral + upward, Vector3.new(4000, math.huge, 4000)
    end
    return Vector3.new(0, POWER, 0), Vector3.new(0, math.huge, 0)
end

local function launchFor(player, root)
    local vel, maxF = computeVelocity(root)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = maxF
    bv.Velocity = vel
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


