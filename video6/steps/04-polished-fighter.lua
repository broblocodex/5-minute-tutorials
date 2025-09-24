-- Step 04 - Polished Fighter
-- LocalScript in StarterPlayerScripts, ServerScript in ServerScriptService.
-- No new assets beyond Step 03. Adds cooldowns, impact audio, and knockback.
-- Changes from Step 03:
--   * Layered in global/per-move cooldown tracking before allowing the next attack.
--   * Added reusable swing/impact sound hooks so each move plays matching audio.
--   * Extended payloads so the server can apply configurable knockback impulses.
--   * Hardened the server validator with cooldown enforcement and impact FX triggers.

---------------------------------------------------------------------
-- LocalScript: cooldown gates + feedback polish
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character, humanoid, animator
local activeMove, activeTrack, heartbeatConn
local hitboxPart, hitboxWeld, hitTargetsThisSwing
local contactWindowEnd, comboStep, comboExpireAt = 0, 0, 0
local currentSwingId
local nextGlobalReady, perMoveReady = 0, {} -- Cooldown tracking to prevent spam attacks
local remote = ReplicatedStorage:WaitForChild("MeleeStrike")

local CONFIG = {
        INPUT_ACTION = "ComboMelee",
        INPUT_KEY = Enum.KeyCode.F,
        PLAYBACK_SPEED = 1,
        COMBO_RESET = 0.7,
        GLOBAL_COOLDOWN = 0.45, -- Global cooldown prevents button mashing
        DEFAULT_MARKER = "Hit",
}

local MOVES = {
        {
                id = "RightKick",
                animationId = "rbxassetid://RIGHT_KICK_ANIMATION_ID",
                limb = "RightFoot",
                offset = CFrame.new(0, -0.2, -1),
                size = Vector3.new(2.6, 2.4, 3),
                contactWindow = 0.2,
                marker = "Hit",
                cooldown = 0.35, -- Individual move cooldown
                swingSoundId = "rbxassetid://KICK_WHOOSH_SOUND_ID", -- Audio feedback
                swingSoundVolume = 0.75,
        },
        {
                id = "LeftKick",
                animationId = "rbxassetid://LEFT_KICK_ANIMATION_ID",
                limb = "LeftFoot",
                offset = CFrame.new(0, -0.2, -1),
                size = Vector3.new(2.6, 2.4, 3),
                contactWindow = 0.2,
                marker = "Hit",
                cooldown = 0.35,
                swingSoundId = "rbxassetid://KICK_WHOOSH_SOUND_ID",
                swingSoundVolume = 0.75,
        },
        {
                id = "StraightPunch",
                animationId = "rbxassetid://PUNCH_ANIMATION_ID",
                limb = "RightHand",
                offset = CFrame.new(0, -0.1, -1.1),
                size = Vector3.new(2.4, 2.2, 2.6),
                contactWindow = 0.15,
                marker = "Hit",
                cooldown = 0.25,
                swingSoundId = "rbxassetid://PUNCH_WHOOSH_SOUND_ID",
                swingSoundVolume = 0.7,
        },
}

local moveRuntime = {}
local swingSounds = {} -- Cache sound instances per move to avoid recreating them

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function safeLoadAnimation(anim, id, looped)
        if not anim or not id or id == "" then return nil end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = id
        local ok, track = pcall(anim.LoadAnimation, anim, animation)
        animation:Destroy()
        
        if ok and track then
                track.Looped = looped or false
                return track
        end
        warn("[Melee] Failed to load animation", id)
end

local function teardownHitbox()
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
        if hitboxWeld then hitboxWeld:Destroy(); hitboxWeld = nil end
        if hitboxPart then hitboxPart:Destroy(); hitboxPart = nil end
end

local function ensureHitbox(move)
        if not character then return end
        local limb = character:FindFirstChild(move.limb)
        if not limb then warn(string.format("[Melee] Limb '%s' missing for hitbox attachment", move.limb)); return end

        teardownHitbox()

        local part = Instance.new("Part")
        part.Name = move.id .. "Hitbox"
        part.Size = move.size
        part.Massless = true
        part.CanCollide = false
        part.CanTouch = false
        part.Transparency = 1
        part.Anchored = false
        part.CFrame = limb.CFrame * move.offset
        part.Parent = character

        local weld = Instance.new("Weld")
        weld.Part0 = part
        weld.Part1 = limb
        weld.C0 = CFrame.new()
        weld.C1 = move.offset
        weld.Parent = part

        hitboxPart = part
        hitboxWeld = weld
        overlapParams.FilterDescendantsInstances = { character }
end

local function closeContactWindow()
        contactWindowEnd = 0
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
end

-- Play swing sound effect for move
local function playSwingSound(move)
        if not move.swingSoundId or move.swingSoundId == "" then return end
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local sound = swingSounds[move.id]
        if not sound or sound.Parent ~= root then
                sound = Instance.new("Sound")
                sound.Name = move.id .. "Swing"
                sound.SoundId = move.swingSoundId
                sound.Volume = move.swingSoundVolume or 0.75
                sound.Looped = false
                sound.PlayOnRemove = false
                sound.Parent = root
                swingSounds[move.id] = sound
        end

        sound.TimePosition = 0
        sound:Play()
end

local function reportHit(move, targetHumanoid)
        if not remote or not currentSwingId then return end

        remote:FireServer({
                swing = currentSwingId,
                move = move.id,
                target = targetHumanoid,
                hitPosition = hitboxPart and hitboxPart.Position or nil,
        })
end

local function checkForTargets(move)
        if not hitboxPart then return end

        local parts = workspace:GetPartBoundsInBox(hitboxPart.CFrame, hitboxPart.Size, overlapParams)
        for _, part in ipairs(parts) do
                local model = part:FindFirstAncestorOfClass("Model")
                if model and model ~= character then
                        local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
                        if targetHumanoid and hitTargetsThisSwing and not hitTargetsThisSwing[targetHumanoid] then
                                hitTargetsThisSwing[targetHumanoid] = true
                                reportHit(move, targetHumanoid)
                        end
                end
        end
end

local function openContactWindow(move)
        if activeMove ~= move then return end

        hitTargetsThisSwing = {}
        contactWindowEnd = os.clock() + (move.contactWindow or 0.2)
        
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
        
        heartbeatConn = RunService.Heartbeat:Connect(function()
                if os.clock() > contactWindowEnd then closeContactWindow(); return end
                checkForTargets(move)
        end)
end

local function loadMoves()
        if not animator then return end

        for _, move in ipairs(MOVES) do
                perMoveReady[move.id] = 0 -- Initialize cooldown timer for each move
                local runtime = moveRuntime[move.id]
                if runtime then
                        if runtime.markerConn then runtime.markerConn:Disconnect() end
                        if runtime.track then runtime.track:Destroy() end
                end
                moveRuntime[move.id] = {track = nil, markerConn = nil}

                local track = safeLoadAnimation(animator, move.animationId, false)
                if track then
                        track.Priority = Enum.AnimationPriority.Action
                        moveRuntime[move.id].track = track
                        local success, signal = pcall(function()
                                return track:GetMarkerReachedSignal(move.marker or CONFIG.DEFAULT_MARKER)
                        end)
                        if success and signal then
                                moveRuntime[move.id].markerConn = signal:Connect(function()
                                        openContactWindow(move)
                                end)
                        else
                                warn(string.format("[Melee] Add a marker named '%s' to animation %s", move.marker or CONFIG.DEFAULT_MARKER, move.animationId))
                        end
                end
        end
end

local function startMove(move)
        local runtime = moveRuntime[move.id]
        if not runtime or not runtime.track then warn("[Melee] Missing animation for move", move.id); return end

        activeMove = move
        activeTrack = runtime.track
        currentSwingId = HttpService:GenerateGUID(false)

        closeContactWindow()
        ensureHitbox(move)
        playSwingSound(move) -- Play swing sound when move starts

        activeTrack:Stop(0)
        activeTrack:Play(0.1, 1, CONFIG.PLAYBACK_SPEED)
end

local function onAction(actionName, inputState)
        if actionName ~= CONFIG.INPUT_ACTION or inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Pass
        end

        local now = os.clock()
        if now < nextGlobalReady then return Enum.ContextActionResult.Sink end -- Check global cooldown

        local nextStep
        if now > comboExpireAt then
                nextStep = 1
        else
                nextStep = comboStep % #MOVES + 1
        end

        local move = MOVES[nextStep]
        if not move then return Enum.ContextActionResult.Sink end

        local readyAt = perMoveReady[move.id] or 0 -- Check individual move cooldown
        if now < readyAt then
                comboStep = 0
                comboExpireAt = now
                return Enum.ContextActionResult.Sink
        end

        comboStep = nextStep
        comboExpireAt = now + CONFIG.COMBO_RESET

        startMove(move)

        -- Set cooldown timers for this move and globally
        nextGlobalReady = now + CONFIG.GLOBAL_COOLDOWN
        perMoveReady[move.id] = now + (move.cooldown or CONFIG.GLOBAL_COOLDOWN)

        return Enum.ContextActionResult.Sink
end

local function configureForCharacter(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        animator = humanoid:WaitForChild("Animator")

        comboStep = 0
        comboExpireAt = 0
        activeMove = nil
        closeContactWindow()
        teardownHitbox()
        nextGlobalReady = 0 -- Reset cooldown timers on character spawn
        perMoveReady = {}
        swingSounds = {}

        overlapParams.FilterDescendantsInstances = { character }
        loadMoves()
end

ContextActionService:BindActionAtPriority(CONFIG.INPUT_ACTION, onAction, false, 2000, CONFIG.INPUT_KEY)

player.CharacterAdded:Connect(configureForCharacter)
if player.Character then configureForCharacter(player.Character) end

---------------------------------------------------------------------
-- ServerScript: authoritative cooldown + knockback
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorageServer = game:GetService("ReplicatedStorage")
local DebrisServer = game:GetService("Debris") -- Auto-cleanup of temporary objects

local REMOTE_NAME = "MeleeStrike"
local remoteServer

local existing = ReplicatedStorageServer:FindFirstChild(REMOTE_NAME)
if existing and existing:IsA("RemoteEvent") then
        remoteServer = existing
else
        remoteServer = Instance.new("RemoteEvent")
        remoteServer.Name = REMOTE_NAME
        remoteServer.Parent = ReplicatedStorageServer
end

local GLOBAL_COOLDOWN = 0.45 -- Server-enforced global cooldown to prevent exploits

-- Extended move configs with knockback and impact audio
local MOVE_CONFIG = {
        RightKick = {
                damage = 25,
                maxDistance = 12,
                cooldown = 0.35,
                knockback = 700, -- Knockback and impact sound configuration
                knockbackUp = 200,
                soundId = "rbxassetid://KICK_IMPACT_SOUND_ID",
                soundVolume = 1,
        },
        LeftKick = {
                damage = 25,
                maxDistance = 12,
                cooldown = 0.35,
                knockback = 700,
                knockbackUp = 200,
                soundId = "rbxassetid://KICK_IMPACT_SOUND_ID",
                soundVolume = 1,
        },
        StraightPunch = {
                damage = 18,
                maxDistance = 10,
                cooldown = 0.3,
                knockback = 500,
                knockbackUp = 150,
                soundId = "rbxassetid://PUNCH_IMPACT_SOUND_ID",
                soundVolume = 0.9,
        },
}

local recentSwings = {}
local cooldowns = {} -- Server-side cooldown tracking per player

local function validateTarget(targetHumanoid)
        return targetHumanoid and targetHumanoid.Health > 0 and targetHumanoid.Parent and targetHumanoid.Parent:IsA("Model")
end

local function ensureSwingTable(player, swingId)
        local swings = recentSwings[player]
        if not swings then swings = {}; recentSwings[player] = swings end
        local swing = swings[swingId]
        if not swing then swing = {}; swings[swingId] = swing end
        return swing
end

local function getCooldownState(player) -- Get or create cooldown tracking state for player
        local state = cooldowns[player]
        if not state then state = {global = 0, moves = {}}; cooldowns[player] = state end
        return state
end

local function isOnCooldown(player, moveId, now) -- Check if player is still on cooldown for move or globally
        local state = getCooldownState(player)
        if now < state.global then return true end
        local readyAt = state.moves[moveId] or 0
        if now < readyAt then return true end
        return false
end

local function applyCooldown(player, moveId, now, moveConfig) -- Apply cooldowns after successful attack
        local state = getCooldownState(player)
        state.global = math.max(state.global, now + GLOBAL_COOLDOWN)
        state.moves[moveId] = math.max(state.moves[moveId] or 0, now + (moveConfig.cooldown or GLOBAL_COOLDOWN))
end

local function applyKnockback(attackerRoot, targetRoot, moveConfig) -- Apply physics knockback to target based on move config
        local horizontal = targetRoot.Position - attackerRoot.Position
        horizontal = Vector3.new(horizontal.X, 0, horizontal.Z)
        local direction
        if horizontal.Magnitude < 0.01 then
                direction = attackerRoot.CFrame.LookVector
        else
                direction = horizontal.Unit
        end

        local power = moveConfig.knockback or 0
        local upward = moveConfig.knockbackUp or 0
        if power <= 0 and upward <= 0 then return end

        local impulse = direction * power + Vector3.new(0, upward, 0)
        targetRoot:ApplyImpulse(impulse * targetRoot.AssemblyMass)
end

local function playImpactSound(targetRoot, moveConfig) -- Play impact sound effect at hit location
        local soundId = moveConfig.soundId
        if not soundId or soundId == "" then return end
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = moveConfig.soundVolume or 1
        sound.RollOffMaxDistance = 60
        sound.RollOffMinDistance = 5
        sound.PlayOnRemove = false
        sound.Looped = false
        sound.Parent = targetRoot
        sound:Play()
        DebrisServer:AddItem(sound, 2)
end

remoteServer.OnServerEvent:Connect(function(attacker, payload)
        if typeof(payload) ~= "table" then
                return
        end
        local swingId = payload.swing
        local moveId = payload.move
        local targetHumanoid = payload.target
        local hitPosition = payload.hitPosition

        if typeof(swingId) ~= "string" or swingId == "" then return end
        if typeof(moveId) ~= "string" or moveId == "" then return end
        if typeof(targetHumanoid) ~= "Instance" or not targetHumanoid:IsA("Humanoid") then return end

        local moveConfig = MOVE_CONFIG[moveId]
        if not moveConfig then return end

        local character = attacker.Character
        if not character then return end
        local attackerHumanoid = character:FindFirstChildOfClass("Humanoid")
        if not attackerHumanoid or attackerHumanoid.Health <= 0 then return end
        if targetHumanoid == attackerHumanoid then return end

        local attackerRoot = character:FindFirstChild("HumanoidRootPart")
        local targetModel = targetHumanoid.Parent
        local targetRoot = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
        if not attackerRoot or not targetRoot then return end

        if (attackerRoot.Position - targetRoot.Position).Magnitude > (moveConfig.maxDistance or 12) then return end

        if not validateTarget(targetHumanoid) then return end

        local now = os.clock() -- Server-side cooldown validation  
        if isOnCooldown(attacker, moveId, now) then return end

        local swingHits = ensureSwingTable(attacker, swingId)
        if swingHits[targetHumanoid] then return end
        swingHits[targetHumanoid] = true

        targetHumanoid:TakeDamage(moveConfig.damage or 20)
        applyKnockback(attackerRoot, targetRoot, moveConfig) -- Apply knockback and sound effects
        playImpactSound(targetRoot, moveConfig)
        applyCooldown(attacker, moveId, now, moveConfig)

        if hitPosition and typeof(hitPosition) == "Vector3" then
                print(string.format("[Melee] %s landed %s on %s", attacker.Name, moveId, targetHumanoid.Parent.Name))
        end
end)
