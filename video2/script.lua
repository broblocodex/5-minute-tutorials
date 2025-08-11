-- Magic Jump Pad (the simple version)
-- Instructions: Drop this Script inside any Part. Step on it to get launched upward!

local Debris = game:GetService("Debris")

local jumpPad = script.Parent
assert(jumpPad and jumpPad:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

-- Tweak these numbers until it feels right for your game
local LAUNCH_FORCE = 50   -- How much upward speed to add
local CLEANUP_TIME = 0.5  -- How long the BodyVelocity lasts before cleanup

-- Make it look like a jump pad (bright and glowy)
jumpPad.BrickColor = BrickColor.new("Bright yellow")
jumpPad.Material = Enum.Material.Neon

-- Apply upward velocity to launched players
local function launch(hit)
    -- Filter out random junk — we only want real players
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local root = humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Create a BodyVelocity to shoot them upward
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)  -- Only apply upward force
    bodyVelocity.Velocity = Vector3.new(0, LAUNCH_FORCE, 0)  -- Straight up
    bodyVelocity.Parent = root

    -- Auto-cleanup after half a second (prevents weird physics)
    Debris:AddItem(bodyVelocity, CLEANUP_TIME)

    print("Launched player:", humanoid.Parent.Name)
end

-- Listen for players stepping on the pad
local touchConnection = jumpPad.Touched:Connect(launch)

-- Clean up the connection if the pad gets deleted
jumpPad.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchConnection then
        touchConnection:Disconnect()
    end
end)