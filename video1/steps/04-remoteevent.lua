-- Step 04 — Broadcast via RemoteEvent (ColorChanged)
-- What: fire an optional `RemoteEvent` named `ColorChanged` under the Part on every change.
-- Why: lets clients mirror color or update UI (Lamp sync, Claimable nameplate use‑cases).

local Players = game:GetService("Players")

local part = script.Parent
assert(part and part:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
    BrickColor.new("Bright yellow"),
}

local remote = part:FindFirstChild("ColorChanged")  -- Look for optional RemoteEvent

local colorIndex = 1
part.BrickColor = COLORS[colorIndex]
part:SetAttribute("ColorIndex", colorIndex)

local function cycleColor(instigator)
    colorIndex += 1
    if colorIndex > #COLORS then 
        colorIndex = 1
    end
    part.BrickColor = COLORS[colorIndex]
    part:SetAttribute("ColorIndex", colorIndex)
    
    if instigator then
        part:SetAttribute("LastUserId", instigator.UserId)
    end

    if remote then  -- Broadcast to all clients when color changes
        remote:FireAllClients(part, colorIndex)
    end
end

local lastTouchTime = 0
local TOUCH_COOLDOWN = 0.15

part.Touched:Connect(function(hit)
    local character = hit.Parent
    local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local now = os.clock()
    if now - lastTouchTime < TOUCH_COOLDOWN then 
        return
    end
    
    local player = Players:GetPlayerFromCharacter(character)
    cycleColor(player)
end)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 32
clickDetector.Parent = part
clickDetector.MouseClick:Connect(function(player)
    cycleColor(player)
end)


