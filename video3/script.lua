-- Teleporter (simple)
-- How to use: put this Script inside a portal Part.
-- Create an ObjectValue under the Part named "Target" and set it to the destination Part.

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "Place this script inside a Part")

-- Height offset to reduce getting stuck in the floor
local SAFE_OFFSET = Vector3.new(0, 4, 0)

-- Optional visual
portal.Material = Enum.Material.Neon
portal.BrickColor = BrickColor.new("Cyan")

-- Where to go next
local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' under the portal and point it to the destination Part")

local function teleportToTarget(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local destPart = targetValue.Value
    if not destPart or not destPart:IsA("BasePart") then return end

    root.CFrame = destPart.CFrame + SAFE_OFFSET
end

portal.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if not player then return end
    teleportToTarget(player)
end)