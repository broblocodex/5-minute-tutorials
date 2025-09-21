-- Step 04 - Reward + cleanup
-- What: Spawn loot or FX when the crate breaks and optionally reset it after a delay.
-- Why: Finish the loop so destruction feels rewarding and reusable.

-- Extends Step 03. New in Step 04:
-- * Adds helpers/config to resolve FX or loot templates referenced by name.
-- * Spawns optional rewards + break FX, with Debris cleanup for temporary instances.
-- * Introduces reset behaviour toggles so crates can respawn or stay destroyed.

local Debris = game:GetService("Debris")
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
        meshes = script:FindFirstChild("Meshes"),
        fx = script:FindFirstChild("FX") -- Step 04 addition: store loot/effect templates beside the script
}

-- Step 04 addition: helper resolves string config into concrete Instances from provided containers
local function resolveInstance(value, ...)
        if typeof(value) == "Instance" then
                return value
        elseif typeof(value) == "string" then
                local containers = table.pack(...)
                for i = 1, containers.n do
                        local container = containers[i]
                        if container then
                                local found = container:FindFirstChild(value, true)
                                if found then
                                        return found
                                end
                        end
                end
        end
        return nil
end

local CONFIG = {
        MAX_HEALTH          = 100,
        DAMAGE_PER_HIT      = 25,
        DAMAGE_COOLDOWN     = 0.15,
        ENABLE_TOUCH_DAMAGE = true,

        USE_TEXTURE_SWAPS   = true,
        TEXTURE_STAGES = {
                { threshold = 0.66, appearanceName = "CrateScuffed" },
                { threshold = 0.33, appearanceName = "CrateCracked" },
                { threshold = 0.15, appearanceName = "CrateDestroyed" },
        },

        USE_MESH_SWAPS      = true,
        MESH_STAGES = {
                { threshold = 0.66, meshName = "CrateDented" },
                { threshold = 0.33, meshName = "CrateBroken" },
                { threshold = 0.15, meshName = "CrateShattered" },
        },

        -- Step 04 addition: reward + reset knobs for the final polish pass
        RESET_MODE   = "None", -- "None" destroys, "Regen" auto resets after delay
        RESET_DELAY  = 8,

        REWARD_TEMPLATE = nil,  -- assign script:WaitForChild("Loot") or similar
        REWARD_OFFSET   = Vector3.new(0, 2, 0),
        REWARD_LIFETIME = 30,

        BREAK_EFFECT    = nil,  -- assign script.FX.BreakBurst, ParticleEmitter, etc.
        EFFECT_LIFETIME = 6,

        DESTROY_DELAY   = 2,
        WOBBLE_TWEEN    = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
}

local originalAnchored = primary.Anchored
local originalCanCollide = primary.CanCollide
local originalTransparency = primary.Transparency

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

-- Step 04 carries forward Step 03 visuals management
local function updateVisuals(health)
        local ratio = (CONFIG.MAX_HEALTH > 0) and (health / CONFIG.MAX_HEALTH) or 0
        local textureStage = stageForRatio(CONFIG.TEXTURE_STAGES, ratio)
        local meshStage = stageForRatio(CONFIG.MESH_STAGES, ratio)
        applyTextureStage(textureStage)
        applyMeshStage(meshStage)
end

-- Step 04 addition: spawn loot/collectibles when the crate breaks
local function spawnReward()
        local template = resolveInstance(CONFIG.REWARD_TEMPLATE, script, libraries.fx, crate)
        if typeof(template) == "Instance" then
                local reward = template:Clone()
                local pivot = primary:GetPivot()
                local offset = primary.CFrame:VectorToWorldSpace(CONFIG.REWARD_OFFSET)
                local targetCFrame = pivot + offset

                if reward:IsA("Model") then
                        reward.Parent = workspace
                        reward:PivotTo(targetCFrame)
                elseif reward:IsA("BasePart") then
                        reward.Parent = workspace
                        reward.CFrame = targetCFrame
                        reward.Anchored = false
                else
                        reward.Parent = primary
                        if reward:IsA("Attachment") then
                                reward.CFrame = targetCFrame
                        elseif reward:IsA("ParticleEmitter") then
                                reward.Enabled = true
                        elseif reward:IsA("Sound") then
                                reward:Play()
                        end
                end

                if CONFIG.REWARD_LIFETIME and CONFIG.REWARD_LIFETIME > 0 then
                        Debris:AddItem(reward, CONFIG.REWARD_LIFETIME)
                end
        end
end

-- Step 04 addition: optional particles/sound when the crate breaks
local function playBreakEffect()
        local template = resolveInstance(CONFIG.BREAK_EFFECT, libraries.fx, script, crate)
        if typeof(template) == "Instance" then
                local fx = template:Clone()
                local pivot = primary:GetPivot()
                if fx:IsA("Model") then
                        fx.Parent = workspace
                        fx:PivotTo(pivot)
                else
                        fx.Parent = primary
                        if fx:IsA("BasePart") then
                                fx.CFrame = pivot
                        elseif fx:IsA("ParticleEmitter") then
                                fx.Enabled = true
                        elseif fx:IsA("Sound") then
                                fx:Play()
                        end
                end
                if CONFIG.EFFECT_LIFETIME and CONFIG.EFFECT_LIFETIME > 0 then
                        Debris:AddItem(fx, CONFIG.EFFECT_LIFETIME)
                end
        end
end

local currentHealth = CONFIG.MAX_HEALTH
local destroyed = false
local lastTouchTime = 0
local regenTask: thread? = nil
local cleanupTask: thread? = nil

local damageEvent = Instance.new("BindableEvent")
damageEvent.Name = "CrateDamaged"
damageEvent.Parent = script

local destroyedEvent = Instance.new("BindableEvent")
destroyedEvent.Name = "CrateDestroyed"
destroyedEvent.Parent = script

-- Step 04 addition: designers can listen for when the crate comes back
local resetEvent = Instance.new("BindableEvent")
resetEvent.Name = "CrateReset"
resetEvent.Parent = script

local applyDamageEvent = Instance.new("BindableEvent")
applyDamageEvent.Name = "Damage"
applyDamageEvent.Parent = script

local takeDamageFn = Instance.new("BindableFunction")
takeDamageFn.Name = "TakeDamage"
takeDamageFn.Parent = script

local resetFn = Instance.new("BindableFunction")
resetFn.Name = "Reset"
resetFn.Parent = script

local wobbleTween = CONFIG.WOBBLE_TWEEN

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

        updateVisuals(currentHealth) -- Step 04 addition: drive visuals before reward/effect logic
        damageEvent:Fire(crate, currentHealth, CONFIG.MAX_HEALTH, source)
        print(string.format("[Crate] Health: %d/%d", currentHealth, CONFIG.MAX_HEALTH))

        if currentHealth <= 0 and not destroyed then
                destroyed = true
                destroyedEvent:Fire(crate, source)
                playBreakEffect() -- Step 04 addition: trigger optional break FX
                spawnReward()     -- Step 04 addition: drop loot or other reward prefabs
                primary.CanCollide = false
                primary.Anchored = true
                primary.Transparency = 1

                if CONFIG.RESET_MODE == "Regen" then -- Step 04 addition: regen flow restores crate automatically
                        if regenTask then
                                task.cancel(regenTask)
                        end
                        regenTask = task.delay(CONFIG.RESET_DELAY, function()
                                regenTask = nil
                                destroyed = false
                                primary.Anchored = originalAnchored
                                primary.CanCollide = originalCanCollide
                                primary.Transparency = originalTransparency
                                setHealth(CONFIG.MAX_HEALTH)
                        end)
                else -- Step 04 addition: destroy or clean up without auto-regen
                        if cleanupTask then
                                task.cancel(cleanupTask)
                                cleanupTask = nil
                        end
                        cleanupTask = task.delay(CONFIG.DESTROY_DELAY, function()
                                if crate.Parent and CONFIG.RESET_MODE == "None" then
                                        crate:Destroy()
                                end
                                cleanupTask = nil
                        end)
                end
        elseif currentHealth > 0 then
                destroyed = false
                primary.Anchored = originalAnchored
                primary.CanCollide = originalCanCollide
                primary.Transparency = originalTransparency
                if cleanupTask then
                        task.cancel(cleanupTask)
                        cleanupTask = nil
                end
        end

        return currentHealth
end

local function applyDamage(amount, source)
        if destroyed and CONFIG.RESET_MODE == "None" then
                return currentHealth
        end
        amount = amount or CONFIG.DAMAGE_PER_HIT
        if not amount or amount <= 0 then
                return currentHealth
        end
        return setHealth(currentHealth - amount, source)
end

local function resetCrate()
        if regenTask then
                task.cancel(regenTask)
                regenTask = nil
        end
        if cleanupTask then
                task.cancel(cleanupTask)
                cleanupTask = nil
        end
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
        setHealth(CONFIG.MAX_HEALTH)
        resetEvent:Fire(crate)
        return currentHealth
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

resetEvent.Event:Connect(function()
        -- Designers can listen and respawn props or chain logic here
end)

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
updateVisuals(currentHealth) -- Step 04 addition: start with the correct texture/mesh stage
