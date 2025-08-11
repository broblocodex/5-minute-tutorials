-- Step 01 - Gated access (key required)
-- Problem: Anyone can use your teleporter, even if they haven't earned access yet
-- Solution: Check for a required attribute (like HasBlueKey) before allowing teleportation

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local FRONT_DISTANCE = 8
local HEIGHT_OFFSET = 2
local REQUIRED_KEY = "HasBlueKey"     -- Change this to match your quest/key system

portal.Material = Enum.Material.Neon
portal.BrickColor = BrickColor.new("Cyan")

local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' and point it to your destination Part!")

-- Check if this player has the required key
local function hasRequiredAccess(player)
    return player:GetAttribute(REQUIRED_KEY) == true
end

local function teleportPlayer(player)
    local character = player.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local destination = targetValue.Value
    if not destination or not destination:IsA("BasePart") then return end

    local frontOffset = destination.CFrame.LookVector * FRONT_DISTANCE
    local heightOffset = Vector3.new(0, HEIGHT_OFFSET, 0)
    local finalPosition = destination.CFrame.Position + frontOffset + heightOffset
    
    root.CFrame = CFrame.lookAt(finalPosition, finalPosition + destination.CFrame.LookVector)
end

portal.Touched:Connect(function(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player then return end
    
    -- New: Check if they have the required access before teleporting
    if not hasRequiredAccess(player) then 
        -- Optional: You could add a message here like "You need the Blue Key!"
        return 
    end
    
    teleportPlayer(player)
end)


