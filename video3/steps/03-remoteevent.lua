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

local remote = portal:FindFirstChild("Teleported") -- RemoteEvent (optional)

portal.BrickColor = BrickColor.new("Cyan")
portal.Material = Enum.Material.Neon

local lastUseAtByUserId = {}

local function canUse(player)
    local now = os.clock()
    local prev = lastUseAtByUserId[player.UserId]
    if prev and (now - prev) < COOLDOWN then return false end
    lastUseAtByUserId[player.UserId] = now
    return true
end

local function teleport(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local destPart = targetValue.Value
    if not destPart or not destPart:IsA("BasePart") then return end

    root.CFrame = destPart.CFrame + SAFE_OFFSET

    if remote then
        remote:FireAllClients(portal, player, destPart)
    end
end

portal.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if not player or not canUse(player) then return end
    teleport(player)
end)


