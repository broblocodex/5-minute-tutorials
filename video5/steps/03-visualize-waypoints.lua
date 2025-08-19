-- Step 03 - Visualize Waypoints (tracing)
-- What: Utility to draw path waypoints/goals as neon spheres (and optional beams) under the NPC.
-- Why: Debug which waypoints the pathfinder produced; tune speed/turn/stop/jump with visual feedback.

local function renderPathWaypoints(character: Model, waypoints, goalPos: Vector3?, opts)
	assert(character and character:IsA("Model"), "renderPathWaypoints: character Model required")

	-- Defaults (override via opts)
	local config = {
		enabled = true,
		yOffset = 0.15,
		size = Vector3.new(0.35, 0.35, 0.35),
		colorMove = Color3.fromRGB(120, 220, 255),
		colorJump = Color3.fromRGB(255, 160, 80),
		colorGoal = Color3.fromRGB(120, 255, 140),
		material = Enum.Material.Neon,
		connectBeams = true,
		beamWidth = 0.02,
		clearFirst = true,      -- clear previous markers each call
		folderName = "PathViz" -- where markers live under the character
	}
	if typeof(opts) == "table" then
		for k, v in pairs(opts) do config[k] = v end
	end

	if not config.enabled then return end

	-- Ensure/clear container
	local folder = character:FindFirstChild(config.folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = config.folderName
		folder.Parent = character
	end
	if config.clearFirst then
		for _, c in ipairs(folder:GetChildren()) do c:Destroy() end
	end

	-- Small helpers (scoped inside for copy-paste simplicity)
	local function makeSphere(position: Vector3, color: Color3)
		local p = Instance.new("Part")
		p.Size = config.size
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = config.material
		p.Color = color
		p.Name = "PathPoint"
		p.CFrame = CFrame.new(position + Vector3.new(0, config.yOffset, 0))
		p.Parent = folder
		return p
	end

	local function connectWithBeam(a: BasePart, b: BasePart, width: number, color: Color3)
		local att0 = Instance.new("Attachment")
		att0.Name = "A0"
		att0.Parent = a
		local att1 = Instance.new("Attachment")
		att1.Name = "A1"
		att1.Parent = b

		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Width0 = width
		beam.Width1 = width
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(color)
		beam.Transparency = NumberSequence.new(0.1)
		beam.Name = "PathBeam"
		beam.Parent = a
		return beam
	end

	-- Render all waypoints
	local lastPart: BasePart? = nil
	for _, wp in ipairs(waypoints or {}) do
		local color = (wp.Action == Enum.PathWaypointAction.Jump) and config.colorJump or config.colorMove
		local sphere = makeSphere(wp.Position, color)
		if config.connectBeams and lastPart then
			connectWithBeam(lastPart, sphere, config.beamWidth, color)
		end
		lastPart = sphere
	end

	-- Optional goal marker (if not nearly identical to last waypoint)
	if goalPos then
		local last = waypoints and waypoints[#waypoints]
		if not last or (last and (last.Position - goalPos).Magnitude > 0.05) then
			local goal = makeSphere(goalPos, config.colorGoal)
			if config.connectBeams and lastPart then
				connectWithBeam(lastPart, goal, config.beamWidth, config.colorGoal)
			end
		end
	end
end