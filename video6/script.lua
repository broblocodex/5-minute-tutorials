-- Step 01 - First Move (LocalScript in StarterPlayerScripts)
-- What: Trigger a single uploaded kick animation when the player presses a key.
-- Why: Smoke-test that your animation asset works in-game and feels responsive on input.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local character: Model? = nil
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local kickTrack: AnimationTrack? = nil

local CONFIG = {
        INPUT_ACTION = "RoundhouseKick",          -- Unique action name for ContextActionService
        INPUT_KEY = Enum.KeyCode.F,                -- Press F to kick
        KICK_ANIM_ID = "rbxassetid://KICK_ANIMATION_ID", -- Replace with your uploaded kick animation id
        PLAYBACK_SPEED = 1,                        -- Multiply animation speed (1 = original rate)
}

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

local function configureForCharacter(newCharacter: Model)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid") :: Humanoid
        animator = humanoid:WaitForChild("Animator") :: Animator

        if kickTrack then
                kickTrack:Destroy()
                kickTrack = nil
        end

        kickTrack = safeLoadAnimation(animator, CONFIG.KICK_ANIM_ID, false)
        if kickTrack then
                kickTrack.Priority = Enum.AnimationPriority.Action
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
