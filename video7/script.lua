-- Step 00 - Sealed Crate (smoke test)
-- What: Detect mouse clicks on a crate and play an impact sound.
-- Why: Verify click detection works before adding visual damage or deformation.

-- Where: Put this Script inside the crate MeshPart.

--// Crate
local crate = script.Parent
assert(crate and crate:IsA("MeshPart"), "Script must be inside a MeshPart (the crate).")

--// Services
local TweenService = game:GetService("TweenService")

--// Config
local CONFIG = {
	IMPACT_SOUND_ID = "rbxassetid://YOUR_IMPACT_SOUND_ID", -- Replace with your sound asset
	COOLDOWN        = 0.2,                                  -- Min time between hits (s)
	MAX_DISTANCE    = 15,                                   -- Max click distance (studs)
	SHAKE = {
		DURATION = 0.18,  -- Total shake time (s)
		STEPS = 4,        -- Number of micro-tweens
		POS_MAG = 0.12,   -- Studs
		ROT_MAG = 3,      -- Degrees
	},
}

--// State
local lastClickAt = 0
local isShaking = false

--// Feedback (shake)
local function shakeCrate()
	if isShaking then return end
	isShaking = true

	local originalCFrame = crate.CFrame
	local steps = math.max(1, CONFIG.SHAKE.STEPS)
	local stepDuration = CONFIG.SHAKE.DURATION / steps
	local tweenInfo = TweenInfo.new(stepDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _ = 1, steps do
		if not crate or not crate.Parent then break end

		local posMag = CONFIG.SHAKE.POS_MAG
		local rotMag = CONFIG.SHAKE.ROT_MAG

		local offset = Vector3.new(
			(math.random() - 0.5) * 2 * posMag,
			(math.random() - 0.5) * 2 * posMag,
			(math.random() - 0.5) * 2 * posMag
		)

		local rot = Vector3.new(
			math.rad((math.random() - 0.5) * 2 * rotMag),
			math.rad((math.random() - 0.5) * 2 * rotMag),
			math.rad((math.random() - 0.5) * 2 * rotMag)
		)

		local target = originalCFrame * CFrame.new(offset) * CFrame.Angles(rot.X, rot.Y, rot.Z)
		local tween = TweenService:Create(crate, tweenInfo, { CFrame = target })
		tween:Play()
		tween.Completed:Wait()
	end

	if crate and crate.Parent then
		local resetTween = TweenService:Create(crate, tweenInfo, { CFrame = originalCFrame })
		resetTween:Play()
		resetTween.Completed:Wait()
	end

	isShaking = false
end

--// Feedback (sound)
local impactSound = crate:FindFirstChild("ImpactSound") :: Sound
if not impactSound then
	impactSound = Instance.new("Sound")
	impactSound.Name = "ImpactSound"
	impactSound.Parent = crate
end
impactSound.SoundId = CONFIG.IMPACT_SOUND_ID
impactSound.Volume = 0.8
impactSound.RollOffMaxDistance = 50

--// Interaction
local clickDetector = crate:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
	clickDetector = Instance.new("ClickDetector")
	clickDetector.Parent = crate
end
clickDetector.MaxActivationDistance = CONFIG.MAX_DISTANCE


local function onMouseClick(_player: Player)
	local now = tick()
	if now - lastClickAt < CONFIG.COOLDOWN then return end
	lastClickAt = now
	
	impactSound:Play()
	
	task.spawn(shakeCrate)
end

clickDetector.MouseClick:Connect(onMouseClick)
