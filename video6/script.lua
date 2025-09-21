-- Step 00 - Damage-ready crate (baseline health + visuals config)
-- What: Track health on a crate, react to damage, and expose events/config for later upgrades.
-- Why: Establish a single script that designers can reuse, toggle texture/mesh swaps, and hook reward logic into.

-- Services
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Root (MeshPart or Model with PrimaryPart)
local crate = script.Parent
assert(crate, "Script must be parented to a MeshPart or Model crate")

local primary: BasePart
if crate:IsA("Model") then
        primary = crate.PrimaryPart or crate:FindFirstChildWhichIsA("BasePart")
        assert(primary, "Model crate needs a PrimaryPart or BasePart child")
else
        assert(crate:IsA("BasePart"), "Parent must be a BasePart or Model")
        primary = crate
end

-- Optional libraries under the script (SurfaceAppearances, MeshParts, FX)
local libraries = {
        surfaces = script:FindFirstChild("SurfaceAppearances"),
        meshes   = script:FindFirstChild("Meshes"),
        fx       = script:FindFirstChild("FX")
}

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
        MAX_HEALTH         = 100,
        DAMAGE_PER_HIT     = 25,
        DAMAGE_COOLDOWN    = 0.15, -- seconds between touch hits
        ENABLE_TOUCH_DAMAGE = true, -- set false if you only drive damage from weapons/projectiles

        USE_TEXTURE_SWAPS  = true,
        USE_MESH_SWAPS     = false,

        TEXTURE_STAGES = {
                -- threshold is health ratio (0-1). When health/max <= threshold, apply this stage.
                { threshold = 0.66, appearanceName = "CrateScuffed" },
                { threshold = 0.33, appearanceName = "CrateCracked" },
                { threshold = 0.15, appearanceName = "CrateDestroyed" },
        },

        MESH_STAGES = {
                -- Same ordering as textures. Use meshId or meshName pointing to a child MeshPart under script.Meshes
                { threshold = 0.66, meshName = "CrateDented" },
                { threshold = 0.33, meshName = "CrateBroken" },
                { threshold = 0.15, meshName = "CrateShattered" },
        },

        RESET_MODE   = "None", -- "None" (destroy), "Regen" (auto reset), "Manual" (wait for event)
        RESET_DELAY  = 8,       -- seconds before regen when RESET_MODE == "Regen"

        REWARD_TEMPLATE = nil,  -- assign e.g. script:WaitForChild("Loot")
        REWARD_OFFSET   = Vector3.new(0, 2, 0),
        REWARD_LIFETIME = 30,

        BREAK_EFFECT    = nil,  -- assign e.g. script:WaitForChild("FX"):WaitForChild("BreakBurst")
        EFFECT_LIFETIME = 6,

        DESTROY_DELAY   = 2,    -- time after break before removing crate (if not resetting)
        WOBBLE_TWEEN    = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
}

-- Preserve baseline visuals so we can restore when resetting
local originalAppearance = nil
local originalTextureId = nil
local originalMaterialVariant = nil
local originalMeshId = nil
local originalCollisionFidelity = nil
local originalAnchored = primary.Anchored
local originalTransparency = primary.Transparency
local originalCanCollide = primary.CanCollide

if primary:IsA("MeshPart") then
        originalTextureId = primary.TextureID
        originalMeshId = primary.MeshId
        originalMaterialVariant = primary.MaterialVariant
        originalCollisionFidelity = primary.CollisionFidelity
end

for _, child in ipairs(primary:GetChildren()) do
        if child:IsA("SurfaceAppearance") then
                originalAppearance = originalAppearance or child:Clone()
        end
end

local currentHealth = CONFIG.MAX_HEALTH
local destroyed = false
local lastTouchTime = 0

-- Events exposed to designers (BindableEvents live under the script)
local damageEvent = Instance.new("BindableEvent")
damageEvent.Name = "CrateDamaged"
damageEvent.Parent = script

local destroyedEvent = Instance.new("BindableEvent")
destroyedEvent.Name = "CrateDestroyed"
destroyedEvent.Parent = script

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

-- Utility: sort stages once so threshold evaluation is predictable
local function sortStages(stages)
        if not stages then return end
        table.sort(stages, function(a, b)
                return (a.threshold or 0) < (b.threshold or 0)
        end)
end

sortStages(CONFIG.TEXTURE_STAGES)
sortStages(CONFIG.MESH_STAGES)

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

local activeAppearance: SurfaceAppearance? = nil

local function cloneFromLibrary(container, name, className)
        if not container or not name then return nil end
        local child = container:FindFirstChild(name)
        if child and (not className or child:IsA(className)) then
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
        if not CONFIG.USE_TEXTURE_SWAPS or not primary then return end

        clearSurfaceAppearances()
        activeAppearance = nil

        if stage then
                local newAppearance: SurfaceAppearance? = nil
                if stage.appearanceName then
                        newAppearance = cloneFromLibrary(libraries.surfaces, stage.appearanceName, "SurfaceAppearance")
                        if not newAppearance then
                                newAppearance = cloneFromLibrary(crate, stage.appearanceName, "SurfaceAppearance")
                        end
                end

                if stage.appearanceId and stage.appearanceId ~= "" then
                        newAppearance = Instance.new("SurfaceAppearance")
                        newAppearance.ColorMap = stage.appearanceId
                        if stage.metalnessMap then newAppearance.MetalnessMap = stage.metalnessMap end
                        if stage.normalMap then newAppearance.NormalMap = stage.normalMap end
                        if stage.roughnessMap then newAppearance.RoughnessMap = stage.roughnessMap end
                end

                if newAppearance then
                        newAppearance.Name = "DamageStageAppearance"
                        newAppearance.Parent = primary
                        activeAppearance = newAppearance
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
                -- Restore defaults
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
                        local clone = cloneFromLibrary(libraries.meshes, stage.meshName, "MeshPart")
                        if not clone then
                                clone = cloneFromLibrary(crate, stage.meshName, "MeshPart")
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

local lastStageKey = ""
local function updateVisualState()
        local ratio = (CONFIG.MAX_HEALTH > 0) and (currentHealth / CONFIG.MAX_HEALTH) or 0
        local textureStage = stageForRatio(CONFIG.TEXTURE_STAGES, ratio)
        local meshStage = stageForRatio(CONFIG.MESH_STAGES, ratio)

        local stageKey = string.format("T:%s|M:%s",
                textureStage and tostring(textureStage.threshold) or "",
                meshStage and tostring(meshStage.threshold) or ""
        )

        if stageKey ~= lastStageKey then
                applyTextureStage(textureStage)
                applyMeshStage(meshStage)
                lastStageKey = stageKey
        end
end

local function wobble()
        if not primary then return end
        local goal = { Size = primary.Size * Vector3.new(1.03, 0.97, 1.03) }
        local tween = TweenService:Create(primary, CONFIG.WOBBLE_TWEEN, goal)
        tween:Play()
end

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
                        end
                end
                if CONFIG.EFFECT_LIFETIME and CONFIG.EFFECT_LIFETIME > 0 then
                        Debris:AddItem(fx, CONFIG.EFFECT_LIFETIME)
                end
        end
end

local regenTask: thread? = nil
local cleanupTask: thread? = nil

local function setHealth(newHealth, source)
        local oldHealth = currentHealth
        currentHealth = math.clamp(newHealth, 0, CONFIG.MAX_HEALTH)
        crate:SetAttribute("MaxHealth", CONFIG.MAX_HEALTH)
        crate:SetAttribute("Health", currentHealth)

        if currentHealth < oldHealth then
                wobble()
        end

        updateVisualState()
        damageEvent:Fire(crate, currentHealth, CONFIG.MAX_HEALTH, source)

        if currentHealth <= 0 and not destroyed then
                destroyed = true
                destroyedEvent:Fire(crate, source)
                playBreakEffect()
                spawnReward()
                primary.CanCollide = false
                primary.Anchored = true
                primary.Transparency = 1

                if CONFIG.RESET_MODE == "Regen" then
                        if regenTask then
                                task.cancel(regenTask)
                        end
                        regenTask = task.delay(CONFIG.RESET_DELAY, function()
                                regenTask = nil
                                resetEvent:Fire(crate, "Auto")
                                setHealth(CONFIG.MAX_HEALTH)
                                destroyed = false
                                primary.Anchored = originalAnchored
                                primary.CanCollide = originalCanCollide
                                primary.Transparency = originalTransparency
                        end)
                elseif CONFIG.RESET_MODE == "Manual" then
                        -- Wait for external script to fire resetEvent or call resetFn
                else
                        if cleanupTask then
                                task.cancel(cleanupTask)
                                cleanupTask = nil
                        end
                        cleanupTask = task.delay(CONFIG.DESTROY_DELAY, function()
                                if crate.Parent then
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
        setHealth(CONFIG.MAX_HEALTH)
        if primary:IsA("MeshPart") then
                primary.MeshId = originalMeshId or primary.MeshId
                primary.TextureID = originalTextureId or primary.TextureID
                primary.MaterialVariant = originalMaterialVariant or ""
                if originalCollisionFidelity then
                        primary.CollisionFidelity = originalCollisionFidelity
                end
        end
        if CONFIG.USE_TEXTURE_SWAPS then
                applyTextureStage(stageForRatio(CONFIG.TEXTURE_STAGES, 1))
        end
        resetEvent:Fire(crate, "Manual")
end

applyDamageEvent.Event:Connect(function(amount, source)
        applyDamage(amount, source)
end)

takeDamageFn.OnInvoke = function(amount, source)
        return applyDamage(amount, source)
end

resetFn.OnInvoke = function()
        resetCrate()
        return currentHealth
end

resetEvent.Event:Connect(function(_, reason)
        if reason == "ManualSignal" then
                resetCrate()
        end
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
updateVisualState()
