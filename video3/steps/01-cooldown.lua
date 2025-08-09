-- Step 01 — Per-player cooldown (anti-spam)
-- Problem: Players can spam the teleporter, creating ping-pong loops between portals
-- Solution: Add a personal cooldown timer so each player can only teleport once every 1.2 seconds

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "Hey! Put this script inside a Part, not floating around loose.")

local COOLDOWN = 1.2      -- Seconds between teleports per player (anti-spam)
local SAFE_OFFSET = Vector3.new(0, 4, 0)

local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' and point it to your destination Part!")

portal.BrickColor = BrickColor.new("Cyan")
portal.Material = Enum.Material.Neon

-- Track when each player last used this portal
local lastTeleportTime = {}

-- Check if this player can teleport right now (cooldown logic)
local function canTeleport(player)
    local now = os.clock()
    local lastTime = lastTeleportTime[player.UserId]
    if lastTime and (now - lastTime) < COOLDOWN then
        return false
    end
    lastTeleportTime[player.UserId] = now
    return true
end

local function teleportPlayer(player)
    local character = player.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local destination = targetValue.Value
    if not destination or not destination:IsA("BasePart") then return end
    
    root.CFrame = destination.CFrame + SAFE_OFFSET
end

portal.Touched:Connect(function(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player or not canTeleport(player) then return end
    
    teleportPlayer(player)
end)


