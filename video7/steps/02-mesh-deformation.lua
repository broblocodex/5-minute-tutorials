-- Step 02 - Mesh Deformation (Client-Server Architecture)
-- Goal: Server handles clicks/skins/shake; client performs mesh deformation via RemoteEvent.
-- Where: Put this Script inside the crate MeshPart.

local crate = script.Parent
assert(crate and crate:IsA("MeshPart"), "Script must be inside a MeshPart (the crate).")

--// Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Config
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
	SKIN_NAMES = { "Skin1", "Skin2", "Skin3" },
	DEBUG = true,
}

--// State
local lastClickAt = 0
local isShaking = false

-- Start at 2 so the first click applies Skin2 (assuming Skin1 is the initial/default skin).
local nextSkinIndex = 2

local function dprint(...)
	if CONFIG.DEBUG then
		print("[Crate]", ...)
	end
end

--// Networking
-- Creates the RemoteEvent once in ReplicatedStorage. Clients listen for it (see client step).
local deformEvent = ReplicatedStorage:FindFirstChild("CrateDeform")
if not deformEvent then
	deformEvent = Instance.new("RemoteEvent")
	deformEvent.Name = "CrateDeform"
	deformEvent.Parent = ReplicatedStorage
	dprint("Created RemoteEvent: CrateDeform")
end

--// Preconditions
local skinsFolder = ReplicatedStorage:FindFirstChild("CrateSkins")
assert(
	skinsFolder and skinsFolder:IsA("Folder"),
	"Create ReplicatedStorage/CrateSkins with SurfaceAppearance objects named Skin1, Skin2, Skin3"
)

local function getNextSkinName(): string
	if #CONFIG.SKIN_NAMES == 0 then
		warn("[Crate] SKIN_NAMES is empty!")
		return ""
	end

	local name = CONFIG.SKIN_NAMES[nextSkinIndex]
	nextSkinIndex += 1
	if nextSkinIndex > #CONFIG.SKIN_NAMES then
		nextSkinIndex = 1
	end

	return name
end

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
	
	local skinName = getNextSkinName()
	applySkinByName(skinName)
	
	-- Tell all clients to apply a crack on a random side.
	local seed = math.random(1, 2^30)
	local axes = {"X", "Y", "Z"}
	local axis = axes[math.random(1, 3)]
	local sign = (math.random() < 0.5) and -1 or 1
	
	deformEvent:FireAllClients(crate, axis, sign, seed)
end

clickDetector.MouseClick:Connect(onMouseClick)
