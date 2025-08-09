-- Step 02 — RemoteEvent (SpeedBoost)
-- What: fire a RemoteEvent named "SpeedBoost" when a boost starts or refreshes.
-- Why: clients can show UI (meter), VFX, or analytics.

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")
local Players = game:GetService("Players")

local function ensureAttr(name, value)
    if part:GetAttribute(name) == nil then part:SetAttribute(name, value) end
end

ensureAttr("BoostSpeed", 50)
ensureAttr("BoostDuration", 8)
ensureAttr("Cooldown", 5)
ensureAttr("LastUserId", 0)
ensureAttr("LastBoostAt", 0)

local event = part:FindFirstChild("SpeedBoost")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "SpeedBoost"
    event.Parent = part
end

local active = {}
local lastTrigger = {}

local function applyBoost(player)
    local char = player.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

    local now = tick()
    local cd = part:GetAttribute("Cooldown") or 5
    if lastTrigger[player.UserId] and now - lastTrigger[player.UserId] < cd then return end

    local duration = part:GetAttribute("BoostDuration") or 8
    local speed = part:GetAttribute("BoostSpeed") or 50

    if not active[player] then
        active[player] = { hum = hum, original = hum.WalkSpeed, untilTime = now + duration }
        hum.WalkSpeed = speed
        part:SetAttribute("LastUserId", player.UserId)
        part:SetAttribute("LastBoostAt", os.time())
        event:FireAllClients(player, speed, duration)
    else
        active[player].untilTime = now + duration
        event:FireAllClients(player, speed, duration)
    end

    lastTrigger[player.UserId] = now
end

local function monitor()
    while part.Parent do
        local now = tick()
        for player, data in pairs(active) do
            if now >= data.untilTime then
                if data.hum.Parent then data.hum.WalkSpeed = data.original or 16 end
                active[player] = nil
            end
        end
        task.wait(0.25)
    end
end

part.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if not player then return end
    applyBoost(player)
end)

coroutine.wrap(monitor)()


