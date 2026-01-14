-- Step 01 - Texture Modification (SurfaceAppearance Cycler)
-- What: Cycle through SurfaceAppearance skins on click, with shake and sound feedback.
-- Why: Server-authoritative texture swapping using pre-configured SurfaceAppearance templates.

local crate = script.Parent
assert(crate and crate:IsA("MeshPart"), "Script must be inside a MeshPart (the crate).")

local TweenService = game:GetService("TweenService")
-- Step 01: Add ReplicatedStorage for skin templates
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONFIG = {
	IMPACT_SOUND_ID = "rbxassetid://YOUR_IMPACT_SOUND_ID",
	COOLDOWN        = 0.2,
	MAX_DISTANCE    = 15,
	SHAKE = {
		DURATION = 0.18,
		STEPS = 4,
		POS_MAG = 0.12,
		ROT_MAG = 3,
	},
	-- Step 01: Define available skin names and debug mode
	SKIN_NAMES = { "Skin1", "Skin2", "Skin3" },
	DEBUG = true,
}

local lastHitTime = 0
local isShaking = false
-- Step 01: Track current skin index for cycling
local currentSkinIndex = 2

-- Step 01: Debug print helper
local function dprint(...)
	if CONFIG.DEBUG then
		print("[Crate]", ...)
	end
end

-- Step 01: Reference to skins folder in ReplicatedStorage
local skinsFolder = ReplicatedStorage:FindFirstChild("CrateSkins")
assert(
	skinsFolder and skinsFolder:IsA("Folder"),
	"Create ReplicatedStorage/CrateSkins with SurfaceAppearance objects named Skin1, Skin2, Skin3"
)

-- Step 01: Get the next skin name in rotation
local function getNextSkinName(): string
	if #CONFIG.SKIN_NAMES == 0 then
		warn("[Crate] SKIN_NAMES is empty!")
		return ""
	end

	local name = CONFIG.SKIN_NAMES[currentSkinIndex]
	currentSkinIndex += 1
	if currentSkinIndex > #CONFIG.SKIN_NAMES then
		currentSkinIndex = 1
	end

	return name
end

-- Step 01: Apply a skin to the crate by cloning from ReplicatedStorage
local function applySkinByName(skinName: string)
	if skinName == "" then return end

	local template = skinsFolder:FindFirstChild(skinName)
	if not template then
		warn("[Crate] Missing skin template:", skinName)
		return
	end
	if not template:IsA("SurfaceAppearance") then
		warn("[Crate] Template is not SurfaceAppearance:", template.ClassName)
		return
	end

	local existing = crate:FindFirstChildOfClass("SurfaceAppearance")
	if existing then
		existing:Destroy()
	end

	local clone = template:Clone()
	clone.Parent = crate

	dprint("Applied skin:", skinName)
end

-- Step 01: Initialize crate with first valid skin if none exists
do
	local existing = crate:FindFirstChildOfClass("SurfaceAppearance")
	if not existing then
		local firstValid = ""
		for _, skinName in ipairs(CONFIG.SKIN_NAMES) do
			local candidate = skinsFolder:FindFirstChild(skinName)
			if candidate and candidate:IsA("SurfaceAppearance") then
				firstValid = skinName
				break
			end
		end

		assert(firstValid ~= "", "No valid SurfaceAppearance found in ReplicatedStorage/CrateSkins for SKIN_NAMES")
		applySkinByName(firstValid)
	end
end

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

local impactSound = crate:FindFirstChild("ImpactSound") :: Sound
if not impactSound then
	impactSound = Instance.new("Sound")
	impactSound.Name = "ImpactSound"
	impactSound.Parent = crate
end
impactSound.SoundId = CONFIG.IMPACT_SOUND_ID
impactSound.Volume = 0.8
impactSound.RollOffMaxDistance = 50

local clickDetector = crate:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
	clickDetector = Instance.new("ClickDetector")
	clickDetector.Parent = crate
end
clickDetector.MaxActivationDistance = CONFIG.MAX_DISTANCE

local function onMouseClick(player: Player)
	local now = tick()
	if now - lastHitTime < CONFIG.COOLDOWN then return end
	lastHitTime = now
	
	impactSound:Play()
	task.spawn(shakeCrate)
	
	-- Step 01: Cycle to next skin and apply it
	local skinName = getNextSkinName()
	applySkinByName(skinName)
end

clickDetector.MouseClick:Connect(onMouseClick)
