-- Magic Jump Pad (simple)
-- How to use: put this Script inside a Part. Touch or click to launch characters upward.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local jumpPad = script.Parent
assert(jumpPad and jumpPad:IsA("BasePart"), "Place this script inside a Part")

-- Tweak these numbers to taste
local LAUNCH_FORCE = 50   -- upward speed added to the character
local CLEANUP_TIME = 0.5  -- seconds to keep the BodyVelocity before cleaning up

jumpPad.BrickColor = BrickColor.new("Bright yellow")
jumpPad.Material = Enum.Material.Neon

-- Apply a short BodyVelocity to the character's root to pop them up
local function launch(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local root = hum.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Velocity = Vector3.new(0, LAUNCH_FORCE, 0)
    bv.Parent = root
    Debris:AddItem(bv, CLEANUP_TIME)

    -- Quick color pulse as feedback
    jumpPad.BrickColor = BrickColor.new("Lime green")
    task.wait(0.1)
    jumpPad.BrickColor = BrickColor.new("Bright yellow")
end

local touchedConn = jumpPad.Touched:Connect(launch)

jumpPad.AncestryChanged:Connect(function(_, parent)
    if parent == nil and touchedConn then touchedConn:Disconnect() end
end)

-- Optional: click to self‑test the pad without stepping on it
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24
clickDetector.Parent = jumpPad
clickDetector.MouseClick:Connect(function(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then launch(root) end
end)