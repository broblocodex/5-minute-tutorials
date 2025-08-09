-- Step 01 — Stop the Touch Spam
-- Problem: BasePart.Touched fires multiple times per contact (seriously, like 5-10 times)
-- Solution: Add a tiny cooldown so we only react once per actual touch

local part = script.Parent
assert(part and part:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
    BrickColor.new("Bright yellow"),
}

local colorIndex = 1
part.BrickColor = COLORS[colorIndex]

local function cycleColor()
    colorIndex += 1
    if colorIndex > #COLORS then 
        colorIndex = 1
    end
    part.BrickColor = COLORS[colorIndex]
end

-- Here's the debounce magic
local lastTouchTime = 0
local TOUCH_COOLDOWN = 0.15  -- 150ms between touches (adjust if needed)

part.Touched:Connect(function(hit)
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Check if enough time has passed
    local now = os.clock()
    if now - lastTouchTime < TOUCH_COOLDOWN then 
        return  -- Too soon, ignore this touch
    end
    
    lastTouchTime = now  -- Remember when this happened
    cycleColor()
end)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24
clickDetector.Parent = part
clickDetector.MouseClick:Connect(cycleColor)


