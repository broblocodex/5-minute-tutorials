-- Step 02 — Publish ColorIndex via Attributes
-- What: write and update `ColorIndex` on the Part whenever the color changes.
-- Why: lets other scripts react to color without editing this script (e.g., Secret Portal use‑case).

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
    BrickColor.new("Bright yellow")
}

local colorIndex = 1
part.BrickColor = COLORS[colorIndex]
part:SetAttribute("ColorIndex", colorIndex)  -- Expose state to other scripts

local function cycle()
    colorIndex += 1
    if colorIndex > #COLORS then colorIndex = 1 end
    part.BrickColor = COLORS[colorIndex]
    part:SetAttribute("ColorIndex", colorIndex)  -- Update attribute on every change
end

local lastTouchTime = 0
local GAP = 0.15

part.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local now = os.clock()
    if now - lastTouchTime < GAP then return end
    lastTouchTime = now
    cycle()
end)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24
clickDetector.Parent = part
clickDetector.MouseClick:Connect(cycle)


