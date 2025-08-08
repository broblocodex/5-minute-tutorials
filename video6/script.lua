-- Speed Boost Strip (simple)
-- Put this Script inside a Part. Touch to gain speed for a few seconds.

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Tweak these
local BOOST_SPEED = 50
local BOOST_DURATION = 8 -- seconds
local NORMAL_SPEED = 16

local boosted = {} -- player -> true while active

local function boost(player)
    if boosted[player] then return end
    local char = player.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

    boosted[player] = true
    local original = hum.WalkSpeed
    hum.WalkSpeed = BOOST_SPEED
    local oldColor = part.Color; part.Color = Color3.fromRGB(0,255,0)

    task.delay(BOOST_DURATION, function()
        if hum.Parent then
            hum.WalkSpeed = original or NORMAL_SPEED
        end
        boosted[player] = nil
        part.Color = oldColor
    end)
end

part.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = game.Players:GetPlayerFromCharacter(hum.Parent)
    if player then boost(player) end
end)