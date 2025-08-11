-- Step 02 - Forward launch mode (realistic jumping)
-- Problem: Always launching straight up doesn't feel natural for movement pads
-- Solution: Launch players in the direction they're facing (forward + upward)

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local jumpPad = script.Parent
assert(jumpPad and jumpPad:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local LAUNCH_FORCE = 50
local CLEANUP_TIME = 0.5
local COOLDOWN = 0.8
local FORWARD_RATIO = 1.0    -- Forward momentum (100% of launch force)
local UPWARD_RATIO = 0.7     -- Upward lift (70% of launch force)

jumpPad.BrickColor = BrickColor.new("Bright red")
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

    -- Calculate forward + upward launch direction
    local lookDirection = root.CFrame.LookVector  -- Direction player is facing
    local forwardForce = lookDirection * (LAUNCH_FORCE * FORWARD_RATIO)  -- Horizontal momentum
    local upwardForce = Vector3.new(0, LAUNCH_FORCE * UPWARD_RATIO, 0)  -- Upward lift
    local totalVelocity = forwardForce + upwardForce  -- Combine them

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, math.huge, 4000)  -- Allow horizontal force
    bodyVelocity.Velocity = totalVelocity  -- Forward + upward direction
    bodyVelocity.Parent = root

    Debris:AddItem(bodyVelocity, CLEANUP_TIME)
end

local touchConnection = jumpPad.Touched:Connect(launch)

jumpPad.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchConnection then
        touchConnection:Disconnect()
    end
end)


