-- Speed Boost Strip (extended)
-- Adds Attributes, per-player cooldown, RemoteEvent broadcast, and live tweak support.
-- Place this Script inside the boost Part. Optionally add a Sound named "BoostSound".
-- Server Script.

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")
local Players = game:GetService("Players")

-- Attribute helpers ---------------------------------------------------------
local function ensureAttr(name, value)
    if part:GetAttribute(name) == nil then
        part:SetAttribute(name, value)
    end
end

ensureAttr("BoostSpeed", 50)         -- WalkSpeed applied during boost
ensureAttr("BoostDuration", 8)       -- Seconds boost lasts
ensureAttr("Cooldown", 5)            -- Seconds before same player can re-trigger
ensureAttr("LastUserId", 0)          -- For UI hooks
ensureAttr("LastBoostAt", 0)         -- os.time() of last successful boost (any player)

-- RemoteEvent (SpeedBoost) --------------------------------------------------
local event = part:FindFirstChild("SpeedBoost")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "SpeedBoost"
    event.Parent = part
end

-- State ---------------------------------------------------------------------
local active = {}   -- player -> { hum = Humanoid, original = number, until = tick }
local lastTrigger = {} -- player.UserId -> time when boost started (for cooldown)

local BoostSound = part:FindFirstChild("BoostSound")

-- Internal ------------------------------------------------------------------
local function applyBoost(player)
    local char = player.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

    local now = tick()
    local cd = part:GetAttribute("Cooldown") or 5
    if lastTrigger[player.UserId] and now - lastTrigger[player.UserId] < cd then
        return -- still cooling down
    end

    -- If currently boosted, refresh end time only
    local duration = part:GetAttribute("BoostDuration") or 8
    local speed = part:GetAttribute("BoostSpeed") or 50

    if not active[player] then
        active[player] = {
            hum = hum,
            original = hum.WalkSpeed,
            untilTime = now + duration,
        }
        hum.WalkSpeed = speed
        if BoostSound and BoostSound:IsA("Sound") then BoostSound:Play() end
        part:SetAttribute("LastUserId", player.UserId)
        part:SetAttribute("LastBoostAt", os.time())
        event:FireAllClients(player, speed, duration)
    else
        active[player].untilTime = now + duration -- extend
    end

    lastTrigger[player.UserId] = now
end

-- Restore logic loop --------------------------------------------------------
local function monitor()
    while part.Parent do
        local now = tick()
        for player, data in pairs(active) do
            if now >= data.untilTime then
                if data.hum.Parent then
                    data.hum.WalkSpeed = data.original or 16
                end
                active[player] = nil
            end
        end
        task.wait(0.25)
    end
end

-- Live attribute tweak: adjust current boost speeds immediately -------------
part:GetAttributeChangedSignal("BoostSpeed"):Connect(function()
    local speed = part:GetAttribute("BoostSpeed") or 50
    for _, data in pairs(active) do
        if data.hum.Parent then
            data.hum.WalkSpeed = speed
        end
    end
end)

-- Touch trigger -------------------------------------------------------------
part.Touched:Connect(function(hit)
    local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local player = Players:GetPlayerFromCharacter(hum.Parent)
    if not player then return end
    applyBoost(player)
end)

-- Cleanup when player leaves (restore speed if needed) ----------------------
Players.PlayerRemoving:Connect(function(player)
    local data = active[player]
    if data then
        if data.hum.Parent then
            data.hum.WalkSpeed = data.original or 16
        end
        active[player] = nil
    end
    lastTrigger[player.UserId] = nil
end)

-- Kick off monitor
coroutine.wrap(monitor)()
