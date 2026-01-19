-- Step 03 - Damage System (Integrity-Driven Visuals)
-- What: Adds integrity tracking; crate breaks after 3 hits. Crack strength scales with damage.
-- Why: Creates progression where crate visibly degrades before breaking.

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
	-- Damage system
	MAX_HITS = 3,
	CRACK_STRENGTH_MIN = 0.8,
	CRACK_STRENGTH_MAX = 2.0,
	UI_DISPLAY_TIME = 3,
	UI_FADE_TIME = 0.5,
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

--// UI (world-space health bar)
local billboard = crate:FindFirstChild("DamageIndicator") or Instance.new("BillboardGui")
billboard.Name = "DamageIndicator"
billboard.Size = UDim2.new(6, 0, 1.5, 0)
billboard.StudsOffset = Vector3.new(0, crate.Size.Y / 2 + 1.5, 0)
billboard.AlwaysOnTop = true
billboard.Enabled = false
billboard.Parent = crate

local frame = billboard:FindFirstChild("Frame") or Instance.new("Frame")
frame.Name = "Frame"
frame.Size = UDim2.new(1, 0, 0.25, 0)
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = billboard

local healthBar = frame:FindFirstChild("HealthBar") or Instance.new("Frame")
healthBar.Name = "HealthBar"
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.Position = UDim2.new(0, 0, 0, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
healthBar.BorderSizePixel = 0
healthBar.Parent = frame

--// Damage state
local hitCount = 0
crate:SetAttribute("HitCount", hitCount)
crate:SetAttribute("MaxHits", CONFIG.MAX_HITS)
crate:SetAttribute("IsBroken", false)

local hideUITimer = nil

local function showDamageUI()
	billboard.Enabled = true
	frame.BackgroundTransparency = 0
	healthBar.BackgroundTransparency = 0
	
	if hideUITimer then
		task.cancel(hideUITimer)
	end
	
	hideUITimer = task.delay(CONFIG.UI_DISPLAY_TIME, function()
		local fadeInfo = TweenInfo.new(CONFIG.UI_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local frameTween = TweenService:Create(frame, fadeInfo, { BackgroundTransparency = 1 })
		local barTween = TweenService:Create(healthBar, fadeInfo, { BackgroundTransparency = 1 })
		
		frameTween:Play()
		barTween:Play()
		
		barTween.Completed:Wait()
		billboard.Enabled = false
	end)
end

-- 1.0 = full health, 0.0 = broken
local function getIntegrityRatio(): number
	return 1 - (hitCount / CONFIG.MAX_HITS)
end

local function updateDamageIndicator()
	local ratio = getIntegrityRatio()
	healthBar.Size = UDim2.new(ratio, 0, 1, 0)
	
	if ratio > 0.66 then
		healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
	elseif ratio > 0.33 then
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
	end
end

local function getCrackStrength(): number
	local ratio = getIntegrityRatio()
	return CONFIG.CRACK_STRENGTH_MIN + (CONFIG.CRACK_STRENGTH_MAX - CONFIG.CRACK_STRENGTH_MIN) * (1 - ratio)
end

local function applyDamage()
	hitCount += 1
	crate:SetAttribute("HitCount", hitCount)
	
	local ratio = getIntegrityRatio()
	dprint(string.format("Hit %d/%d (%.0f%% integrity)", hitCount, CONFIG.MAX_HITS, ratio * 100))
	
	updateDamageIndicator()
	showDamageUI()
	
	if hitCount >= CONFIG.MAX_HITS then
		crate:SetAttribute("IsBroken", true)
		if hideUITimer then
			task.cancel(hideUITimer)
		end
		billboard.Enabled = true
		frame.BackgroundTransparency = 0
		healthBar.BackgroundTransparency = 0
		dprint("CRATE BROKEN! (Breaking logic in Step 04)")
		return true
	end
	
	return false
end

local function onMouseClick(_player: Player)
	-- Ignore clicks after the crate is marked broken.
	if crate:GetAttribute("IsBroken") then
		dprint("Crate already broken, ignoring click")
		return
	end
	
	local now = tick()
	if now - lastClickAt < CONFIG.COOLDOWN then return end
	lastClickAt = now
	
	impactSound:Play()
	task.spawn(shakeCrate)
	
	local skinName = getNextSkinName()
	applySkinByName(skinName)
	
	-- Apply damage and check if broken
	local isBroken = applyDamage()
	
	if isBroken then
		return
	end
	
	local seed = math.random(1, 2^30)
	local axes = {"X", "Y", "Z"}
	local axis = axes[math.random(1, 3)]
	local sign = (math.random() < 0.5) and -1 or 1
	-- Send scaled crack strength to clients
	local crackStrength = getCrackStrength()
	
	deformEvent:FireAllClients(crate, axis, sign, seed, crackStrength)
end

clickDetector.MouseClick:Connect(onMouseClick)
