-- Step 03 - Mesh damage
-- What: Swap MeshPart variants alongside textures as health falls.
-- Why: Sell damage silhouette changes for hero crates.

-- Continues from Step 02. New in Step 03:
-- * Adds a MeshPart library + MESH_STAGES config so geometry can deform with damage.
-- * Captures original mesh + collision fidelity for proper reset behaviour.
-- * Extends updateVisuals to apply both texture and mesh swaps in sync.

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
        surfaces = script:FindFirstChild("SurfaceAppearances"),
        meshes = script:FindFirstChild("Meshes") -- Step 03 addition: optional damaged MeshParts stored under the script
}

local CONFIG = {
        MAX_HEALTH          = 100,
        DAMAGE_PER_HIT      = 25,
        DAMAGE_COOLDOWN     = 0.15,
        ENABLE_TOUCH_DAMAGE = true,
        DESTROY_ON_ZERO     = false,

        USE_TEXTURE_SWAPS   = true,
        TEXTURE_STAGES = {
                { threshold = 0.66, appearanceName = "CrateScuffed" },
                { threshold = 0.33, appearanceName = "CrateCracked" },
                { threshold = 0.15, appearanceName = "CrateDestroyed" },
        },

        -- Step 03 addition: mesh swap toggle + stages for silhouette changes
        USE_MESH_SWAPS      = true,
        MESH_STAGES = {
                { threshold = 0.66, meshName = "CrateDented" },
                { threshold = 0.33, meshName = "CrateBroken" },
                { threshold = 0.15, meshName = "CrateShattered" },
        }
}

local originalAnchored = primary.Anchored
local originalCanCollide = primary.CanCollide
local originalTransparency = primary.Transparency

-- Step 03 addition: remember original mesh + collision info for resets
local originalAppearance = nil
local originalTextureId = nil
local originalMaterialVariant = nil
local originalMeshId = nil
local originalCollisionFidelity = nil

if primary:IsA("MeshPart") then
        originalTextureId = primary.TextureID
        originalMaterialVariant = primary.MaterialVariant
        originalMeshId = primary.MeshId
        originalCollisionFidelity = primary.CollisionFidelity
end

for _, child in ipairs(primary:GetChildren()) do
        if child:IsA("SurfaceAppearance") then
                originalAppearance = originalAppearance or child:Clone()
        end
end

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
sortStages(CONFIG.MESH_STAGES)

local activeAppearance: SurfaceAppearance? = nil

local function cloneSurface(container, name)
        if not container or not name then return nil end
        local child = container:FindFirstChild(name)
        if child and child:IsA("SurfaceAppearance") then
                return child:Clone()
        end
        return nil
end

-- Step 03 addition: helpers for staged mesh swapping
local function cloneMesh(container, name)
        if not container or not name then return nil end
        local child = container:FindFirstChild(name)
        if child and child:IsA("MeshPart") then
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
                        appearance = cloneSurface(libraries.surfaces, stage.appearanceName)
                        if not appearance then
                                appearance = cloneSurface(crate, stage.appearanceName)
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

local function applyMeshStage(stage)
        if not CONFIG.USE_MESH_SWAPS or not primary:IsA("MeshPart") then
                return
        end

        if stage then
                if stage.meshId and stage.meshId ~= "" then
                        primary.MeshId = stage.meshId
                elseif stage.meshName then
                        local clone = cloneMesh(libraries.meshes, stage.meshName)
                        if not clone then
                                clone = cloneMesh(crate, stage.meshName)
                        end
                        if clone then
                                primary.MeshId = clone.MeshId
                                primary.TextureID = clone.TextureID
                                primary.Size = clone.Size
                        end
                end
                if stage.collisionFidelity then
                        local fidelity = stage.collisionFidelity
                        if type(fidelity) == "string" then
                                fidelity = Enum.CollisionFidelity[fidelity] or Enum.CollisionFidelity.Default
                        end
                        primary.CollisionFidelity = fidelity
                end
        else
                primary.MeshId = originalMeshId or primary.MeshId
                primary.TextureID = originalTextureId or primary.TextureID
                if originalCollisionFidelity then
                        primary.CollisionFidelity = originalCollisionFidelity
                end
        end
end

-- Step 03 addition: combine texture + mesh thresholds for cohesive feedback
local function updateVisuals(health)
        local ratio = (CONFIG.MAX_HEALTH > 0) and (health / CONFIG.MAX_HEALTH) or 0
        local textureStage = stageForRatio(CONFIG.TEXTURE_STAGES, ratio)
        local meshStage = stageForRatio(CONFIG.MESH_STAGES, ratio)
        applyTextureStage(textureStage)
        applyMeshStage(meshStage) -- Step 03 addition: mesh swaps accompany texture wear
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

        updateVisuals(currentHealth) -- Step 03 addition: keep texture + mesh stages aligned with health
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
        if primary:IsA("MeshPart") then
                primary.MeshId = originalMeshId or primary.MeshId
                primary.TextureID = originalTextureId or primary.TextureID
                primary.MaterialVariant = originalMaterialVariant or ""
                if originalCollisionFidelity then
                        primary.CollisionFidelity = originalCollisionFidelity
                end
        end
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
updateVisuals(currentHealth) -- Step 03 addition: initialise both texture and mesh visuals
