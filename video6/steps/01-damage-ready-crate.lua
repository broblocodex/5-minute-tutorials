-- Step 01 - Damage-ready crate
-- What: Track health, react to hits, and expose damage/destruction events.
-- Why: Establish a reusable destructible prop foundation before layering visuals or rewards.

local TweenService = game:GetService("TweenService")

local crate = script.Parent
assert(crate, "Script must be parented to a MeshPart or Model")

local primary: BasePart
if crate:IsA("Model") then
        primary = crate.PrimaryPart or crate:FindFirstChildWhichIsA("BasePart")
        assert(primary, "Model crate needs a PrimaryPart or BasePart child")
else
        assert(crate:IsA("BasePart"), "Parent must be a BasePart or Model")
        primary = crate
end

local CONFIG = {
        MAX_HEALTH          = 100,
        DAMAGE_PER_HIT      = 25,
        DAMAGE_COOLDOWN     = 0.15, -- seconds between touch hits
        ENABLE_TOUCH_DAMAGE = true, -- turn off when driving damage via weapons/projectiles only
        DESTROY_ON_ZERO     = false -- set true if you want the crate removed when health hits zero
}

local originalAnchored = primary.Anchored
local originalCanCollide = primary.CanCollide
local originalTransparency = primary.Transparency

local currentHealth = CONFIG.MAX_HEALTH
local destroyed = false
local lastTouchTime = 0

local damageEvent = Instance.new("BindableEvent")
damageEvent.Name = "CrateDamaged"
damageEvent.Parent = script

local destroyedEvent = Instance.new("BindableEvent")
destroyedEvent.Name = "CrateDestroyed"
destroyedEvent.Parent = script

local applyDamageEvent = Instance.new("BindableEvent")
applyDamageEvent.Name = "Damage"
applyDamageEvent.Parent = script

local takeDamageFn = Instance.new("BindableFunction")
takeDamageFn.Name = "TakeDamage"
takeDamageFn.Parent = script

local resetFn = Instance.new("BindableFunction")
resetFn.Name = "Reset"
resetFn.Parent = script

local wobbleTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

local function wobble()
        if not primary then return end
        local goal = { Size = primary.Size * Vector3.new(1.03, 0.97, 1.03) }
        local tween = TweenService:Create(primary, wobbleTween, goal)
        tween:Play()
end

local function setHealth(value, source)
        local old = currentHealth
        currentHealth = math.clamp(value, 0, CONFIG.MAX_HEALTH)
        crate:SetAttribute("MaxHealth", CONFIG.MAX_HEALTH)
        crate:SetAttribute("Health", currentHealth)

        if currentHealth < old then
                wobble()
        end

        damageEvent:Fire(crate, currentHealth, CONFIG.MAX_HEALTH, source)
        print(string.format("[Crate] Health: %d/%d", currentHealth, CONFIG.MAX_HEALTH))

        if currentHealth <= 0 and not destroyed then
                destroyed = true
                destroyedEvent:Fire(crate, source)
                primary.CanCollide = false
                primary.Anchored = true
                primary.Transparency = 0.35
                if CONFIG.DESTROY_ON_ZERO then
                        task.delay(1.5, function()
                                if crate.Parent then
                                        crate:Destroy()
                                end
                        end)
                end
        elseif currentHealth > 0 then
                destroyed = false
                primary.Anchored = originalAnchored
                primary.CanCollide = originalCanCollide
                primary.Transparency = originalTransparency
        end

        return currentHealth
end

local function applyDamage(amount, source)
        if destroyed and CONFIG.DESTROY_ON_ZERO then
                return currentHealth
        end
        amount = amount or CONFIG.DAMAGE_PER_HIT
        if not amount or amount <= 0 then
                return currentHealth
        end
        return setHealth(currentHealth - amount, source)
end

local function resetCrate()
        destroyed = false
        primary.Anchored = originalAnchored
        primary.CanCollide = originalCanCollide
        primary.Transparency = originalTransparency
        return setHealth(CONFIG.MAX_HEALTH)
end

applyDamageEvent.Event:Connect(function(amount, source)
        applyDamage(amount, source)
end)

takeDamageFn.OnInvoke = function(amount, source)
        return applyDamage(amount, source)
end

resetFn.OnInvoke = function()
        return resetCrate()
end

if CONFIG.ENABLE_TOUCH_DAMAGE then
        primary.Touched:Connect(function(hit)
                local now = os.clock()
                if now - lastTouchTime < CONFIG.DAMAGE_COOLDOWN then
                        return
                end
                lastTouchTime = now
                applyDamage(CONFIG.DAMAGE_PER_HIT, hit)
        end)
end

crate:SetAttribute("MaxHealth", CONFIG.MAX_HEALTH)
crate:SetAttribute("Health", currentHealth)
