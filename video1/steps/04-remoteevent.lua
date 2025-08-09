-- Step 04 — Broadcast via RemoteEvent (ColorChanged)
-- What: fire an optional `RemoteEvent` named `ColorChanged` under the Part on every change.
-- Why: lets clients mirror color or update UI (Lamp sync, Claimable nameplate use‑cases).

local Players = game:GetService("Players")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
    BrickColor.new("Bright yellow"),
}

local remote = part:FindFirstChild("ColorChanged")

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
    if remote then
        remote:FireAllClients(part, colorIndex)
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
clickDetector.MaxActivationDistance = 32
clickDetector.Parent = part
clickDetector.MouseClick:Connect(function(player)
    cycle(player)
end)


