-- Step 01 — Per-player cooldown (anti-spam)
-- Problem: Players can spam the jump pad, causing chaos in lobbies and spawn areas
-- Solution: Add a personal cooldown timer so each player can only launch once every 0.8 seconds

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local jumpPad = script.Parent
assert(jumpPad and jumpPad:IsA("BasePart"), "Hey! Put this script inside a Part, not floating around loose.")

local LAUNCH_FORCE = 50
local CLEANUP_TIME = 0.5
local COOLDOWN = 0.8      -- Seconds between launches per player (anti-spam)

jumpPad.BrickColor = BrickColor.new("Bright yellow")
jumpPad.Material = Enum.Material.Neon

-- Track when each player last used the pad
local lastLaunchTime = {}

-- Check if this player can launch right now (cooldown logic)
local function canLaunch(player)
    if not player then return false end
    local now = os.clock()
    local lastTime = lastLaunchTime[player.UserId]
    if lastTime and (now - lastTime) < COOLDOWN then
        return false
    end
    lastLaunchTime[player.UserId] = now
    return true
end

local function launch(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    -- Get the player and check their cooldown
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not canLaunch(player) then return end
    
    local root = humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, LAUNCH_FORCE, 0)
    bodyVelocity.Parent = root
    
    Debris:AddItem(bodyVelocity, CLEANUP_TIME)
end

local touchConnection = jumpPad.Touched:Connect(launch)

jumpPad.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchConnection then 
        touchConnection:Disconnect() 
    end
end)


