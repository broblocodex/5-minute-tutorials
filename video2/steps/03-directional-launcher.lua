-- Step 03 - Directional launcher (perpendicular to surface)
-- Problem: Basic jump pad only launches straight up. Sometimes you want to launch players in specific directions.
-- Solution: Use the pad's surface normal (UpVector) to launch players perpendicular to the pad surface

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local jumpPad = script.Parent
assert(jumpPad and jumpPad:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local LAUNCH_FORCE = 50
local CLEANUP_TIME = 0.5
local COOLDOWN = 0.8
local PERPENDICULAR_RATIO = 1.0 -- How much force perpendicular to surface
local UPWARD_RATIO = 0.7        -- Additional upward boost (helps with gravity)

jumpPad.BrickColor = BrickColor.new("Bright green")
jumpPad.Material = Enum.Material.Neon

local lastLaunchTime = {}

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

    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not canLaunch(player) then return end

    local root = humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)  -- Apply force in all directions
    
    -- Calculate launch direction: perpendicular to pad surface + slight upward
    local perpendicularForce = jumpPad.CFrame.UpVector * (LAUNCH_FORCE * PERPENDICULAR_RATIO)  -- Away from surface
    local upwardForce = Vector3.new(0, LAUNCH_FORCE * UPWARD_RATIO, 0)  -- Slight upward boost
    local totalVelocity = perpendicularForce + upwardForce
    
    bodyVelocity.Velocity = totalVelocity
    bodyVelocity.Parent = root

    Debris:AddItem(bodyVelocity, CLEANUP_TIME)
end

local touchConnection = jumpPad.Touched:Connect(launch)

jumpPad.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchConnection then
        touchConnection:Disconnect()
    end
end)
