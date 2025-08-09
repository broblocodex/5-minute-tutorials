-- Step 02 — Gated access (key required)
-- Problem: Anyone can use your teleporter, even if they haven't earned access yet
-- Solution: Check for a required attribute (like HasBlueKey) before allowing teleportation

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "Hey! Put this script inside a Part, not floating around loose.")

local COOLDOWN = 1.2
local SAFE_OFFSET = Vector3.new(0, 4, 0)
local REQUIRED_KEY = "HasBlueKey"     -- Change this to match your quest/key system

local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' and point it to your destination Part!")

portal.BrickColor = BrickColor.new("Cyan")
portal.Material = Enum.Material.Neon

local lastTeleportTime = {}

-- Check if this player has the required key and can teleport
local function canTeleport(player)
    -- First check: do they have the key?
    if player:GetAttribute(REQUIRED_KEY) ~= true then 
        return false 
    end
    
    -- Second check: are they still on cooldown?
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


