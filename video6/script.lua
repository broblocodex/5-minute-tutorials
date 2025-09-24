local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local character, humanoid, animator, kickTrack

-- Configuration for the melee combat system
local CONFIG = {
        INPUT_ACTION = "RoundhouseKick",                        -- Action name for input binding
        INPUT_KEY = Enum.KeyCode.F,                             -- Key to trigger the kick
        KICK_ANIM_ID = "rbxassetid://KICK_ANIMATION_ID",        -- Animation asset ID
        PLAYBACK_SPEED = 1,                                     -- Animation playback speed multiplier
}

-- Safely loads an animation with error handling
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

-- Sets up animation components when character spawns
local function configureForCharacter(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        animator = humanoid:WaitForChild("Animator")
        
        if kickTrack then kickTrack:Destroy() end
        
        kickTrack = safeLoadAnimation(animator, CONFIG.KICK_ANIM_ID, false)
        if kickTrack then kickTrack.Priority = Enum.AnimationPriority.Action end
end

-- Handles input action and triggers kick animation
local function onAction(actionName, inputState)
        if actionName ~= CONFIG.INPUT_ACTION or inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Pass
        end
        
        if kickTrack then
                kickTrack:Stop(0)
                kickTrack:Play(0.1, 1, CONFIG.PLAYBACK_SPEED)
        else
                warn("[Melee] Kick animation missing - replace KICK_ANIM_ID with your asset id")
        end
        
        return Enum.ContextActionResult.Sink
end

-- Bind input action and set up character connections
ContextActionService:BindActionAtPriority(CONFIG.INPUT_ACTION, onAction, false, 2000, CONFIG.INPUT_KEY)

player.CharacterAdded:Connect(configureForCharacter)
if player.Character then configureForCharacter(player.Character) end
