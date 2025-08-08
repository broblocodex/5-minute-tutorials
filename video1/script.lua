-- Chameleon Block (simple)
-- How to use: put this Script inside a Part. Touch or click the Part to cycle colors.

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Small, friendly palette (add or replace colors as you like)
local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
}

-- Current color index; set initial color so the part matches the palette
local i = 1
part.BrickColor = COLORS[i]

-- Move to the next color and wrap around
local function cycle()
    i += 1
    if i > #COLORS then i = 1 end
    part.BrickColor = COLORS[i]
end

part.Touched:Connect(function(hit)
    -- Only react to character touches (ignore tools/loose parts)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    cycle()
end)

-- Optional: click support for easy testing
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24
clickDetector.Parent = part
clickDetector.MouseClick:Connect(cycle)