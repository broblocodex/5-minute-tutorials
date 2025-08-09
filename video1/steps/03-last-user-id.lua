-- Step 03 - Track LastUserId of the player who triggered
-- What: store `LastUserId` attribute pointing to the last player who changed the color.
-- Why: used by the Boost Pad use-case to boost only the last tapper.

local Players = game:GetService("Players")  -- Need this to identify players

local part = script.Parent
assert(part and part:IsA("BasePart"), "This script needs to live inside a Part, not floating around!")

local COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("Bright green"),
    BrickColor.new("Bright yellow")
}

local colorIndex = 1
part.BrickColor = COLORS[colorIndex]
part:SetAttribute("ColorIndex", colorIndex)

local function cycleColor(instigator)  -- Takes a player parameter
    colorIndex += 1
    if colorIndex > #COLORS then 
        colorIndex = 1
    end
    part.BrickColor = COLORS[colorIndex]
    part:SetAttribute("ColorIndex", colorIndex)
    
    if instigator then  -- Track who caused this change
        part:SetAttribute("LastUserId", instigator.UserId)
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
    
    local player = Players:GetPlayerFromCharacter(character)  -- Get player from character
    cycleColor(player)  -- Pass player to cycle function
end)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 24
clickDetector.Parent = part
clickDetector.MouseClick:Connect(function(player)  -- Click events already give us player
    cycleColor(player)  -- Pass player to cycle function
end)


