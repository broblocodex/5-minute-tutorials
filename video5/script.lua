-- Step 00 - Idle Animation (smoke test)
-- What: Play and loop an idle animation on the NPC using AnimationController -> Animator.
-- Why: Verify rig and animation asset IDs before adding walking/jumping behavior.

-- Character
local character = script.Parent
assert(character and character:IsA("Model"), "Script must be in an NPC Model.")

-- Animator
local animator = character:FindFirstChildOfClass("AnimationController")
	and character.AnimationController:FindFirstChildOfClass("Animator")
	or character:WaitForChild("AnimationController"):WaitForChild("Animator")

-- Config
local CONFIG = {
	IDLE_ANIM_ID = "rbxassetid://IDLE_ANIMATION_ID" -- replace with your idle/standing anim id
}

-- Unified animation loader; looped defaults to true unless explicitly set to false
local function safeLoadAnimation(anim, id, looped)
	if not id or id == "" then return nil end
	local a = Instance.new("Animation")
	a.AnimationId = id
	local ok, t = pcall(function()
		return anim:LoadAnimation(a)
	end)
	a:Destroy()
	if ok and t then
		t.Looped = (looped ~= false)
		return t
	end
	return nil
end

-- Tracks
local idleTrack = safeLoadAnimation(animator, CONFIG.IDLE_ANIM_ID, true)
if idleTrack then
	idleTrack:Play()
end
