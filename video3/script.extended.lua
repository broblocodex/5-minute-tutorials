-- Teleporter (extended variations)
-- Adds: per-player cooldown, orientation option, optional sound, RemoteEvent, Attributes.

local Players = game:GetService("Players")

local portal = script.Parent
assert(portal and portal:IsA("BasePart"), "Place this script inside a Part")

-- Config
local COOLDOWN = 1.2           -- seconds per player
local SAFE_OFFSET = Vector3.new(0, 4, 0)
local PRESERVE_ORIENTATION = true -- keep facing direction when arriving
local ENABLE_SOUND = false
local CLICK_RANGE = 28
local SET_ATTRIBUTES = true

-- Optional attachments
local arriveSound = portal:FindFirstChildOfClass("Sound")
local remote = portal:FindFirstChild("Teleported") -- RemoteEvent optional. Contract: FireAllClients(portal, player, destinationPart)

-- Destination reference
local targetValue = portal:FindFirstChild("Target")
assert(targetValue and targetValue:IsA("ObjectValue"), "Add an ObjectValue named 'Target' under the portal and point it to the destination Part")

-- State
local last = {} -- UserId -> os.clock()

-- Helpers
local function canUse(player)
    local t = os.clock()
    local prev = last[player.UserId]
    if prev and (t - prev) < COOLDOWN then return false end
    last[player.UserId] = t
    return true
end

local function computeArrivalCFrame(root, destPart)
    local base = destPart.CFrame + SAFE_OFFSET
    if not PRESERVE_ORIENTATION then return base end
    -- Keep current rotation, move to destination position
    local current = root.CFrame
    return CFrame.new(base.Position) * (current - current.Position)
end

local function teleport(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local destPart = targetValue.Value
    if not destPart or not destPart:IsA("BasePart") then return end

    root.CFrame = computeArrivalCFrame(root, destPart)

    if ENABLE_SOUND and arriveSound then arriveSound:Play() end
    if SET_ATTRIBUTES then
        portal:SetAttribute("LastUserId", player.UserId)
        portal:SetAttribute("LastDestinationName", destPart.Name)
    end
    if remote then remote:FireAllClients(portal, player, destPart) end

    -- Tiny color pulse feedback
    local original = portal.BrickColor
    portal.BrickColor = BrickColor.new("White")
    task.delay(0.08, function()
        if portal.Parent then portal.BrickColor = original end
    end)
end

-- Touch handler
local function onTouched(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if not player or not canUse(player) then return end
    teleport(player)
end

portal.BrickColor = BrickColor.new("Cyan")
portal.Material = Enum.Material.Neon

local touchedConn = portal.Touched:Connect(onTouched)
portal.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchedConn then touchedConn:Disconnect() end
end)

-- Optional: click to test
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 28
clickDetector.Parent = portal
clickDetector.MouseClick:Connect(function(player)
    if not canUse(player) then return end
    teleport(player)
end)
