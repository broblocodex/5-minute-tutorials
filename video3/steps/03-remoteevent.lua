-- Step 03 — RemoteEvent for arrival VFX
-- What: fire an optional RemoteEvent named "Teleported" under the portal on each teleport.
-- Why: clients can listen and spawn VFX/UI at the destination without changing server code.

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "Place this script inside a Part")

local COOLDOWN = 1.2
local SAFE_OFFSET = Vector3.new(0, 4, 0)

local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' under the portal and point it to the destination Part")

-- Optional: Add a RemoteEvent named "Teleported" for visual effects
local teleportedEvent = portal:FindFirstChild("Teleported")

portal.BrickColor = BrickColor.new("Cyan")
portal.Material = Enum.Material.Neon

local lastTeleportTime = {}

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

    -- Tell clients about the teleportation for visual effects
    if teleportedEvent and teleportedEvent:IsA("RemoteEvent") then
        teleportedEvent:FireAllClients(portal, player, destination)
    end
end

portal.Touched:Connect(function(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player or not canTeleport(player) then return end
    
    teleportPlayer(player)
end)


