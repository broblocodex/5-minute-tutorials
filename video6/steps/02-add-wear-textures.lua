-- Step 02 - Texture wear
-- What: Swap textures/SurfaceAppearances as health drops using thresholds.
-- Why: Give instant visual feedback without changing mesh or physics.

-- Builds directly on Step 01. New in Step 02:
-- * Adds optional SurfaceAppearance library support for designer-provided variants.
-- * Introduces TEXTURE_STAGES configuration + helpers that pick textures per health threshold.
-- * Stores the original texture/material state so reset paths return the crate to pristine visuals.

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

local libraries = {
        surfaces = script:FindFirstChild("SurfaceAppearances") -- Step 02 addition: folder of wear textures under the script
}

local CONFIG = {
        MAX_HEALTH          = 100,
        DAMAGE_PER_HIT      = 25,
        DAMAGE_COOLDOWN     = 0.15,
        ENABLE_TOUCH_DAMAGE = true,
        DESTROY_ON_ZERO     = false,

        -- Step 02 addition: toggle + texture stages that control cosmetic wear
        USE_TEXTURE_SWAPS   = true,
        TEXTURE_STAGES = {
                { threshold = 0.66, appearanceName = "CrateScuffed" },
                { threshold = 0.33, appearanceName = "CrateCracked" },
                { threshold = 0.15, appearanceName = "CrateDestroyed" },
        }
}

local originalAnchored = primary.Anchored
local originalCanCollide = primary.CanCollide
local originalTransparency = primary.Transparency

-- Step 02 addition: preserve original surface data so reset restores the clean crate
local originalAppearance = nil
local originalTextureId = nil
local originalMaterialVariant = nil

if primary:IsA("MeshPart") then
        originalTextureId = primary.TextureID
        originalMaterialVariant = primary.MaterialVariant
end

for _, child in ipairs(primary:GetChildren()) do
        if child:IsA("SurfaceAppearance") then
                originalAppearance = originalAppearance or child:Clone()
        end
end

-- Step 02 addition: helper utilities that drive texture stage selection
local function sortStages(stages)
        if not stages then return end
        table.sort(stages, function(a, b)
                return (a.threshold or 0) < (b.threshold or 0)
        end)
end

local function stageForRatio(stages, ratio)
        if not stages then return nil end
        local chosen = nil
        for _, stage in ipairs(stages) do
                if ratio <= stage.threshold then
                        chosen = stage
                end
        end
        return chosen
end

sortStages(CONFIG.TEXTURE_STAGES)

local activeAppearance: SurfaceAppearance? = nil

local function cloneFromLibrary(container, name)
        if not container or not name then return nil end
        local child = container:FindFirstChild(name)
        if child and child:IsA("SurfaceAppearance") then
                return child:Clone()
        end
        return nil
end

local function clearSurfaceAppearances()
        for _, inst in ipairs(primary:GetChildren()) do
                if inst:IsA("SurfaceAppearance") then
                        inst:Destroy()
                end
        end
end

local function applyTextureStage(stage)
        if not CONFIG.USE_TEXTURE_SWAPS then return end

        clearSurfaceAppearances()
        activeAppearance = nil

        if stage then
                local appearance: SurfaceAppearance? = nil
                if stage.appearanceName then
                        appearance = cloneFromLibrary(libraries.surfaces, stage.appearanceName)
                        if not appearance then
                                appearance = cloneFromLibrary(crate, stage.appearanceName)
                        end
                end
                if stage.appearanceId and stage.appearanceId ~= "" then
                        appearance = Instance.new("SurfaceAppearance")
                        appearance.ColorMap = stage.appearanceId
                        if stage.normalMap then appearance.NormalMap = stage.normalMap end
                        if stage.roughnessMap then appearance.RoughnessMap = stage.roughnessMap end
                end
                if appearance then
                        appearance.Name = "DamageStageAppearance"
                        appearance.Parent = primary
                        activeAppearance = appearance
                end
                if primary:IsA("MeshPart") then
                        if stage.textureId then
                                primary.TextureID = stage.textureId
                        end
                        if stage.materialVariant then
                                primary.MaterialVariant = stage.materialVariant
                        end
                end
        else
                if primary:IsA("MeshPart") then
                        primary.TextureID = originalTextureId or ""
                        primary.MaterialVariant = originalMaterialVariant or ""
                end
                if originalAppearance then
                        local restored = originalAppearance:Clone()
                        restored.Parent = primary
                        activeAppearance = restored
                end
        end
end

-- Step 02 addition: main entry point that swaps SurfaceAppearances for the active damage stage
local function updateVisuals(health)
        local ratio = (CONFIG.MAX_HEALTH > 0) and (health / CONFIG.MAX_HEALTH) or 0
        local stage = stageForRatio(CONFIG.TEXTURE_STAGES, ratio)
        applyTextureStage(stage)
end

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
        TweenService:Create(primary, wobbleTween, goal):Play()
end

local function setHealth(value, source)
        local old = currentHealth
        currentHealth = math.clamp(value, 0, CONFIG.MAX_HEALTH)
        crate:SetAttribute("MaxHealth", CONFIG.MAX_HEALTH)
        crate:SetAttribute("Health", currentHealth)

        if currentHealth < old then
                wobble()
        end

        updateVisuals(currentHealth) -- Step 02 addition: refresh cosmetic wear every time health changes
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
updateVisuals(currentHealth) -- Step 02 addition: ensure the correct wear stage is shown on start
