-- Step 01 — Debounce touch spam
-- What: add a small global debounce to avoid multiple triggers per single contact.
-- Why: BasePart.Touched can fire several times quickly; this keeps UX smooth while staying simple.

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
}

local colorIndex = 1
part.BrickColor = COLORS[colorIndex]

local function cycle()
    colorIndex += 1
    if colorIndex > #COLORS then colorIndex = 1 end
    part.BrickColor = COLORS[colorIndex]
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


