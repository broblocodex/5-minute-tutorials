-- Instant Teleporter (the simple version)
-- Instructions: Drop this Script inside any Part. Set up a Target ObjectValue. Step on it to teleport!

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "Hey! Put this script inside a Part, not floating around loose.")

-- Height offset so players don't get stuck in floors
local SAFE_OFFSET = Vector3.new(0, 4, 0)

-- Make it look like a portal (glowy and mysterious)
portal.Material = Enum.Material.Neon
portal.BrickColor = BrickColor.new("Cyan")

-- Where should this portal take people?
local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' and point it to your destination Part!")

-- The magic: instantly move players to the target location
local function teleportPlayer(player)
    local character = player.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local destination = targetValue.Value
    if not destination or not destination:IsA("BasePart") then return end

    -- Teleport them to the destination (with safe height offset)
    root.CFrame = destination.CFrame + SAFE_OFFSET
end

-- Listen for players stepping on the portal
portal.Touched:Connect(function(hit)
    -- Filter out random junk — we only want real players
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player then return end
    
    teleportPlayer(player)
end)