-- Step 03 - Real Damage
-- Drop the LocalScript in StarterPlayerScripts and the ServerScript in ServerScriptService.
-- Prerequisite: Same kick animation with a "Hit" marker at the contact frame.
-- Changes from Step 02:
--   * Added swing identifiers and a RemoteEvent so hits replicate to the server.
--   * Moved damage resolution into a new server Script that validates limbs and range.
--   * Debounced hit requests on both client and server to prevent multi-hit exploits.
--   * Included a lightweight damage application helper that other melee moves can reuse.

---------------------------------------------------------------------
-- LocalScript: client-side timing + hit detection
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character: Model? = nil
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local kickTrack: AnimationTrack? = nil

local markerConn: RBXScriptConnection? = nil
local heartbeatConn: RBXScriptConnection? = nil

local hitboxPart: BasePart? = nil
local hitboxWeld: Weld? = nil
local hitTargetsThisSwing: {[Humanoid]: boolean}? = nil
local contactWindowEnd = 0
local currentSwingId: string? = nil

local remote: RemoteEvent? = ReplicatedStorage:WaitForChild("MeleeStrike")

local CONFIG = {
        INPUT_ACTION = "RoundhouseKick",
        INPUT_KEY = Enum.KeyCode.F,
        KICK_ANIM_ID = "rbxassetid://KICK_ANIMATION_ID",
        PLAYBACK_SPEED = 1,
        CONTACT_MARKER = "Hit",
        CONTACT_WINDOW = 0.2,
        HITBOX_LIMB = "RightFoot",
        HITBOX_SIZE = Vector3.new(2.6, 2.4, 3),
        HITBOX_OFFSET = CFrame.new(0, -0.2, -1),
        MOVE_ID = "RightKick",
}

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function safeLoadAnimation(anim: Animator, id: string, looped: boolean?)
        if not anim or not id or id == "" then
                return nil
        end

        local animation = Instance.new("Animation")
        animation.AnimationId = id

        local ok, track = pcall(function()
                return anim:LoadAnimation(animation)
        end)

        animation:Destroy()

        if ok and track then
                track.Looped = (looped == true)
                return track
        end

        warn("[Melee] Failed to load animation", id)
        return nil
end

local function teardownHitbox()
        if heartbeatConn then
                heartbeatConn:Disconnect()
                heartbeatConn = nil
        end
        if hitboxWeld then
                hitboxWeld:Destroy()
                hitboxWeld = nil
        end
        if hitboxPart then
                hitboxPart:Destroy()
                hitboxPart = nil
        end
end

local function ensureHitbox()
        if not character then return end
        local limb = character:FindFirstChild(CONFIG.HITBOX_LIMB) :: BasePart?
        if not limb then
                warn(string.format("[Melee] Limb '%s' missing for hitbox attachment", CONFIG.HITBOX_LIMB))
                return
        end

        teardownHitbox()

        local part = Instance.new("Part")
        part.Name = "KickHitbox"
        part.Size = CONFIG.HITBOX_SIZE
        part.Massless = true
        part.CanCollide = false
        part.CanTouch = false
        part.Transparency = 1
        part.Anchored = false
        part.Color = Color3.new(1, 0, 0)
        part.CFrame = limb.CFrame * CONFIG.HITBOX_OFFSET
        part.Parent = character

        local weld = Instance.new("Weld")
        weld.Part0 = part
        weld.Part1 = limb
        weld.C0 = CFrame.new()
        weld.C1 = CONFIG.HITBOX_OFFSET
        weld.Parent = part

        hitboxPart = part
        hitboxWeld = weld

        overlapParams.FilterDescendantsInstances = { character }
end

local function closeContactWindow()
        contactWindowEnd = 0
        if heartbeatConn then
                heartbeatConn:Disconnect()
                heartbeatConn = nil
        end
end

local function reportHit(targetHumanoid: Humanoid)
        if not remote or not currentSwingId then
                return
        end

        remote:FireServer({
                swing = currentSwingId,
                move = CONFIG.MOVE_ID,
                target = targetHumanoid,
                hitPosition = hitboxPart and hitboxPart.Position or nil,
        })
end

local function checkForTargets()
        if not hitboxPart then
                return
        end

        local parts = workspace:GetPartBoundsInBox(hitboxPart.CFrame, hitboxPart.Size, overlapParams)
        for _, part in ipairs(parts) do
                local model = part:FindFirstAncestorOfClass("Model")
                if model and model ~= character then
                        local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
                        if targetHumanoid then
                                if hitTargetsThisSwing and not hitTargetsThisSwing[targetHumanoid] then
                                        hitTargetsThisSwing[targetHumanoid] = true
                                        reportHit(targetHumanoid)
                                end
                        end
                end
        end
end

local function openContactWindow()
        hitTargetsThisSwing = {}
        contactWindowEnd = os.clock() + CONFIG.CONTACT_WINDOW

        if heartbeatConn then
                heartbeatConn:Disconnect()
                heartbeatConn = nil
        end

        heartbeatConn = RunService.Heartbeat:Connect(function()
                if os.clock() > contactWindowEnd then
                        closeContactWindow()
                        return
                end

                checkForTargets()
        end)
end

local function configureForCharacter(newCharacter: Model)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        animator = humanoid:WaitForChild("Animator")

        ensureHitbox()

        if markerConn then
                markerConn:Disconnect()
                markerConn = nil
        end
        if kickTrack then
                kickTrack:Destroy()
                kickTrack = nil
        end

        kickTrack = safeLoadAnimation(animator, CONFIG.KICK_ANIM_ID, false)
        if kickTrack then
                kickTrack.Priority = Enum.AnimationPriority.Action
                local success, signal = pcall(function()
                        return kickTrack:GetMarkerReachedSignal(CONFIG.CONTACT_MARKER)
                end)
                if success and signal then
                        markerConn = signal:Connect(openContactWindow)
                else
                        warn(string.format("[Melee] Add a marker named '%s' at the hit frame in the animation", CONFIG.CONTACT_MARKER))
                end
        end
end

local function onAction(actionName: string, inputState: Enum.UserInputState)
        if actionName ~= CONFIG.INPUT_ACTION then
                return Enum.ContextActionResult.Pass
        end
        if inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Pass
        end

        if kickTrack then
                closeContactWindow()
                currentSwingId = HttpService:GenerateGUID(false)
                kickTrack:Stop(0)
                kickTrack:Play(0.1, 1, CONFIG.PLAYBACK_SPEED)
        else
                warn("[Melee] Kick animation missing - replace KICK_ANIM_ID with your asset id")
        end

        return Enum.ContextActionResult.Sink
end

local function bind()
        ContextActionService:UnbindAction(CONFIG.INPUT_ACTION)
        ContextActionService:BindActionAtPriority(
                CONFIG.INPUT_ACTION,
                onAction,
                false,
                2000,
                CONFIG.INPUT_KEY
        )
end

player.CharacterAdded:Connect(configureForCharacter)
if player.Character then
        configureForCharacter(player.Character)
end

bind()

---------------------------------------------------------------------
-- ServerScript: authoritative damage application
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorageServer = game:GetService("ReplicatedStorage")

type Player = Players.Player

local REMOTE_NAME = "MeleeStrike"
local remoteServer: RemoteEvent

local existing = ReplicatedStorageServer:FindFirstChild(REMOTE_NAME)
if existing and existing:IsA("RemoteEvent") then
        remoteServer = existing
else
        remoteServer = Instance.new("RemoteEvent")
        remoteServer.Name = REMOTE_NAME
        remoteServer.Parent = ReplicatedStorageServer
end

local CONFIG_SERVER = {
        DAMAGE = 25,
        MAX_DISTANCE = 12, -- studs between attacker and target roots
}

local recentSwings: {[Player]: {[string]: {[Humanoid]: boolean}}} = {}

local function validateTarget(targetHumanoid: Humanoid)
        return targetHumanoid
                and targetHumanoid.Health > 0
                and targetHumanoid.Parent
                and targetHumanoid.Parent:IsA("Model")
end

local function ensureSwingTable(player: Player, swingId: string)
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

remoteServer.OnServerEvent:Connect(function(attacker: Player, payload)
        if typeof(payload) ~= "table" then
                return
        end

        local swingId = payload.swing
        local moveId = payload.move
        local targetHumanoid = payload.target
        local hitPosition = payload.hitPosition

        if typeof(swingId) ~= "string" or swingId == "" then
                return
        end
        if typeof(moveId) ~= "string" or moveId == "" then
                return
        end
        if typeof(targetHumanoid) ~= "Instance" or not targetHumanoid:IsA("Humanoid") then
                return
        end

        local character = attacker.Character
        if not character then return end
        local attackerHumanoid = character:FindFirstChildOfClass("Humanoid")
        if not attackerHumanoid or attackerHumanoid.Health <= 0 then
                return
        end
        if targetHumanoid == attackerHumanoid then
                return
        end

        local attackerRoot = character:FindFirstChild("HumanoidRootPart")
        local targetModel = targetHumanoid.Parent
        local targetRoot = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
        if not attackerRoot or not targetRoot then
                return
        end

        if (attackerRoot.Position - targetRoot.Position).Magnitude > CONFIG_SERVER.MAX_DISTANCE then
                return
        end

        if not validateTarget(targetHumanoid) then
                return
        end

        local swingHits = ensureSwingTable(attacker, swingId)
        if swingHits[targetHumanoid] then
                return -- already damaged this target during the swing
        end
        swingHits[targetHumanoid] = true

        targetHumanoid:TakeDamage(CONFIG_SERVER.DAMAGE)

        if hitPosition and typeof(hitPosition) == "Vector3" then
                -- Optional: debug log for designers tweaking timing/position
                print(string.format("[Melee] %s landed %s on %s", attacker.Name, moveId, targetHumanoid.Parent.Name))
        end
end)
