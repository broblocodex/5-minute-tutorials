-- Chameleon Block (the simple version)
-- Instructions: Drop this Script inside any Part. Touch or click to cycle colors.

local part = script.Parent
assert(part and part:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

-- Our color palette. Feel free to swap these out - just keep the BrickColor.new() format
local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
    BrickColor.new("Bright yellow"),
}

-- Start at color #1 and make sure the part shows it
local colorIndex = 1
part.BrickColor = COLORS[colorIndex]

-- The magic happens here: move to next color, loop back to start when we hit the end
local function cycleColor()
    colorIndex += 1
    if colorIndex > #COLORS then 
        colorIndex = 1  -- Loop back to the beginning
    end
    part.BrickColor = COLORS[colorIndex]
end

-- Listen for touches (when players walk into or jump on the part)
part.Touched:Connect(function(hit)
    -- Filter out random junk — we only care when actual players touch us
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    cycleColor()
end)

-- Bonus: let people click the part too
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24  -- How far away you can click from
clickDetector.Parent = part
clickDetector.MouseClick:Connect(cycleColor)