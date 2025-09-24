-- Step 01 - Contact Moment (LocalScript in StarterPlayerScripts)
-- What: Time the damaging portion of the kick using an animation marker.
-- Why: Only allow the hitbox to register during the correct keyframe window.
-- Changes from Step 00 (script.lua):
--   * Added marker and heartbeat tracking so the kick only connects during a short window.
--   * Spawned a welded hitbox part that follows the kicking limb during contact.
--   * Reused the existing animation helper but now listens for keyframe marker events.
--   * Tracked per-swing targets to avoid double hits while the contact window is open.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character, humanoid, animator, kickTrack
local markerConn, heartbeatConn
local hitboxPart, hitboxWeld, hitTargetsThisSwing
local contactWindowEnd = 0

local CONFIG = {
        INPUT_ACTION = "RoundhouseKick",
        INPUT_KEY = Enum.KeyCode.F,
        KICK_ANIM_ID = "rbxassetid://KICK_ANIMATION_ID",
        PLAYBACK_SPEED = 1,
        CONTACT_MARKER = "Hit",                                 -- Animation marker for hit timing
        CONTACT_WINDOW = 0.2,                                   -- Active hitbox duration (seconds)
        HITBOX_LIMB = "RightFoot",                              -- Limb to attach hitbox to
        HITBOX_SIZE = Vector3.new(2.6, 2.4, 3),                 -- Hitbox dimensions
        HITBOX_OFFSET = CFrame.new(0, -0.2, -1),                -- Hitbox position offset
}

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

-- Cleans up hitbox components and connections
local function teardownHitbox()
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
        if hitboxWeld then hitboxWeld:Destroy(); hitboxWeld = nil end
        if hitboxPart then hitboxPart:Destroy(); hitboxPart = nil end
end

-- Creates and welds hitbox part to specified limb
local function ensureHitbox()
        if not character then return end
        local limb = character:FindFirstChild(CONFIG.HITBOX_LIMB)
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

-- Closes the active contact window and stops hit detection
local function closeContactWindow()
        contactWindowEnd = 0
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
end

-- Checks for targets within hitbox and registers hits
local function checkForTargets()
        if not hitboxPart then return end

        local parts = workspace:GetPartBoundsInBox(hitboxPart.CFrame, hitboxPart.Size, overlapParams)
        for _, part in ipairs(parts) do
                local model = part:FindFirstAncestorOfClass("Model")
                if model and model ~= character then
                        local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
                        if targetHumanoid and hitTargetsThisSwing and not hitTargetsThisSwing[targetHumanoid] then
                                hitTargetsThisSwing[targetHumanoid] = true
                                print(string.format("[Melee] Contact window active → would hit %s", model.Name))
                        end
                end
        end
end

-- Opens contact window and starts hit detection loop
local function openContactWindow()
        hitTargetsThisSwing = {}
        contactWindowEnd = os.clock() + CONFIG.CONTACT_WINDOW
        
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
        
        heartbeatConn = RunService.Heartbeat:Connect(function()
                if os.clock() > contactWindowEnd then
                        closeContactWindow()
                        return
                end
                checkForTargets()
        end)
end

-- Sets up hitbox and animation marker detection
local function configureForCharacter(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        animator = humanoid:WaitForChild("Animator")
        
        ensureHitbox()
        
        if markerConn then markerConn:Disconnect(); markerConn = nil end
        if kickTrack then kickTrack:Destroy(); kickTrack = nil end
        
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

local function onAction(actionName, inputState)
        if actionName ~= CONFIG.INPUT_ACTION or inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Pass
        end
        
        if kickTrack then
                closeContactWindow()
                kickTrack:Stop(0)
                kickTrack:Play(0.1, 1, CONFIG.PLAYBACK_SPEED)
        else
                warn("[Melee] Kick animation missing - replace KICK_ANIM_ID with your asset id")
        end
        
        return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(CONFIG.INPUT_ACTION, onAction, false, 2000, CONFIG.INPUT_KEY)

player.CharacterAdded:Connect(configureForCharacter)
if player.Character then configureForCharacter(player.Character) end
