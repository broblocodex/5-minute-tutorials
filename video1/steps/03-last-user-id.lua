-- Step 03 — Track LastUserId of the player who triggered
-- What: store `LastUserId` attribute pointing to the last player who changed the color.
-- Why: used by the Boost Pad use‑case to boost only the last tapper.

local Players = game:GetService("Players")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
}

local colorIndex = 1
part.BrickColor = COLORS[colorIndex]
part:SetAttribute("ColorIndex", colorIndex)

local function cycle(instigator)
    colorIndex += 1
    if colorIndex > #COLORS then colorIndex = 1 end
    part.BrickColor = COLORS[colorIndex]
    part:SetAttribute("ColorIndex", colorIndex)
    if instigator then
        part:SetAttribute("LastUserId", instigator.UserId)
    end
end

local lastTouchTime = 0
local GAP = 0.15

part.Touched:Connect(function(hit)
    local character = hit.Parent
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local now = os.clock()
    if now - lastTouchTime < GAP then return end
    lastTouchTime = now

    local player = Players:GetPlayerFromCharacter(character)
    cycle(player)
end)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24
clickDetector.Parent = part
clickDetector.MouseClick:Connect(function(player)
    cycle(player)
end)


