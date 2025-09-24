-- Step 03 - Combo Variety
-- LocalScript goes in StarterPlayerScripts, ServerScript in ServerScriptService.
-- Prerequisite: Upload/own additional animations (left kick, punch) with "Hit" markers.
-- Changes from Step 02:
--   * Promoted the single kick into a combo table with chaining rules and expiry timing.
--   * Added per-move animation loading, contact markers, and hitbox sizing/offset data.
--   * Sent detailed move payloads to the server so each attack can deal unique damage.
--   * Updated the server validator to honor combo ids, individual damage, and knockback.

---------------------------------------------------------------------
-- LocalScript: combo routing + per-move hitboxes
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character, humanoid, animator
local activeMove, activeTrack, heartbeatConn -- Track currently executing move
local hitboxPart, hitboxWeld, hitTargetsThisSwing
local contactWindowEnd = 0
local comboStep, comboExpireAt = 0, 0 -- Combo progression and timing
local currentSwingId
local remote = ReplicatedStorage:WaitForChild("MeleeStrike")

local CONFIG = {
        INPUT_ACTION = "ComboMelee",
        INPUT_KEY = Enum.KeyCode.F,
        PLAYBACK_SPEED = 1,
        COMBO_RESET = 0.7, -- Time before combo resets to first move
        DEFAULT_MARKER = "Hit",
}

-- Array of combo moves with individual configurations
local MOVES = {
        {
                id = "RightKick",
                animationId = "rbxassetid://RIGHT_KICK_ANIMATION_ID",
                limb = "RightFoot",
                offset = CFrame.new(0, -0.2, -1),
                size = Vector3.new(2.6, 2.4, 3),
                contactWindow = 0.2,
                marker = "Hit",
        },
        {
                id = "LeftKick",
                animationId = "rbxassetid://LEFT_KICK_ANIMATION_ID",
                limb = "LeftFoot",
                offset = CFrame.new(0, -0.2, -1),
                size = Vector3.new(2.6, 2.4, 3),
                contactWindow = 0.2,
                marker = "Hit",
        },
        {
                id = "StraightPunch",
                animationId = "rbxassetid://PUNCH_ANIMATION_ID",
                limb = "RightHand",
                offset = CFrame.new(0, -0.1, -1.1),
                size = Vector3.new(2.4, 2.2, 2.6),
                contactWindow = 0.15,
                marker = "Hit",
        },
}

local moveRuntime = {} -- Runtime data for each move (animations and marker connections)

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

-- Create hitbox sized and positioned for specific move
local function ensureHitbox(move)
        if not character then return end
        local limb = character:FindFirstChild(move.limb)
        if not limb then
                warn(string.format("[Melee] Limb '%s' missing for hitbox attachment", move.limb))
                return
        end

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

-- Send move-specific hit data to server
local function reportHit(move, targetHumanoid)
        if not remote or not currentSwingId then return end

        remote:FireServer({
                swing = currentSwingId,
                move = move.id,
                target = targetHumanoid,
                hitPosition = hitboxPart and hitboxPart.Position or nil,
        })
end

-- Check for targets using move-specific hitbox
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

-- Open contact window for specific move with timing validation
local function openContactWindow(move)
        if activeMove ~= move then return end

        hitTargetsThisSwing = {}
        contactWindowEnd = os.clock() + (move.contactWindow or 0.2)
        
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
        
        heartbeatConn = RunService.Heartbeat:Connect(function()
                if os.clock() > contactWindowEnd then
                        closeContactWindow()
                        return
                end
                checkForTargets(move)
        end)
end

-- Load all move animations and connect their marker events
local function loadMoves()
        if not animator then return end

        for _, move in ipairs(MOVES) do
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

-- Execute specific move with proper setup and tracking
local function startMove(move)
        local runtime = moveRuntime[move.id]
        if not runtime or not runtime.track then
                warn("[Melee] Missing animation for move", move.id)
                return
        end

        activeMove = move
        activeTrack = runtime.track
        currentSwingId = HttpService:GenerateGUID(false)

        closeContactWindow()
        ensureHitbox(move)

        activeTrack:Stop(0)
        activeTrack:Play(0.1, 1, CONFIG.PLAYBACK_SPEED)
end

local function onAction(actionName, inputState)
        if actionName ~= CONFIG.INPUT_ACTION or inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Pass
        end

        local now = os.clock()
        if now > comboExpireAt then
                comboStep = 1
        else
                comboStep += 1 -- Advance to next move in sequence
                if comboStep > #MOVES then comboStep = 1 end
        end
        comboExpireAt = now + CONFIG.COMBO_RESET

        local move = MOVES[comboStep]
        if move then startMove(move) end

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

        overlapParams.FilterDescendantsInstances = { character }
        loadMoves()
end

ContextActionService:BindActionAtPriority(CONFIG.INPUT_ACTION, onAction, false, 2000, CONFIG.INPUT_KEY)

player.CharacterAdded:Connect(configureForCharacter)
if player.Character then configureForCharacter(player.Character) end

---------------------------------------------------------------------
-- ServerScript: move-aware damage output
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorageServer = game:GetService("ReplicatedStorage")

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

-- Per-move damage and distance configuration
local MOVE_CONFIG = {
        RightKick = {damage = 25, maxDistance = 12},
        LeftKick = {damage = 25, maxDistance = 12},
        StraightPunch = {damage = 18, maxDistance = 10},
}

local recentSwings = {}

local function validateTarget(targetHumanoid)
        return targetHumanoid and targetHumanoid.Health > 0 and targetHumanoid.Parent and targetHumanoid.Parent:IsA("Model")
end

local function ensureSwingTable(player, swingId)
        local swings = recentSwings[player]
        if not swings then
                swings = {}
                recentSwings[player] = swings
        end
        local swing = swings[swingId]
        if not swing then
                swing = {}
                swings[swingId] = swing
        end
        return swing
end

remoteServer.OnServerEvent:Connect(function(attacker, payload)
        if typeof(payload) ~= "table" then return end

        local swingId = payload.swing
        local moveId = payload.move
        local targetHumanoid = payload.target
        local hitPosition = payload.hitPosition

        if typeof(swingId) ~= "string" or swingId == "" then return end
        if typeof(moveId) ~= "string" or moveId == "" then return end
        if typeof(targetHumanoid) ~= "Instance" or not targetHumanoid:IsA("Humanoid") then return end

        -- Validate move exists in configuration
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

        local swingHits = ensureSwingTable(attacker, swingId)
        if swingHits[targetHumanoid] then return end -- Already damaged this target
        swingHits[targetHumanoid] = true

        targetHumanoid:TakeDamage(moveConfig.damage or 20) -- Apply move-specific damage

        if hitPosition and typeof(hitPosition) == "Vector3" then
                print(string.format("[Melee] %s landed %s on %s", attacker.Name, moveId, targetHumanoid.Parent.Name))
        end
end)
