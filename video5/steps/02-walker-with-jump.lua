-- Step 02 - Walker with Jump
-- What: Same as Step 01 but triggers a small hop at jump waypoints; optional jump animation.
-- Why: Handle paths that require elevation changes while keeping movement simple and readable.

-- Services
local RunService         = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local character = script.Parent
assert(character and character:IsA("Model"), "Script must be in an NPC Model.")
assert(character.PrimaryPart, "Set a PrimaryPart for the character model!")

local animator = character:FindFirstChildOfClass("AnimationController")
	and character.AnimationController:FindFirstChildOfClass("Animator")
	or character:WaitForChild("AnimationController"):WaitForChild("Animator")

local CONFIG = {
	WAYPOINTS        = workspace:WaitForChild("Waypoints"),
	MOVE_SPEED       = 10,
	TURN_SPEED_RAD   = math.rad(180),
	IDLE_MIN         = 2,
	IDLE_MAX         = 5,
	RAYCAST_UP       = 100,
	RAYCAST_DEPTH    = 300,
	FOOT_CLEARANCE   = 0.05,
	STOP_DISTANCE    = 2.5,
	START_OFFSET     = Vector3.new(-5, 0, 0),
	WALK_ANIM_ID     = "rbxassetid://WALK_ANIMATION_ID",
	IDLE_ANIM_ID     = "rbxassetid://IDLE_ANIMATION_ID",
	JUMP_ANIM_ID     = "rbxassetid://JUMP_ANIMATION_ID", 	-- Jump animation
	JUMP_TRIGGER_DIST= 4.0,									-- Hop/jump behavior tuning
	JUMP_STRENGTH    = 35,                                  -- Jump impulse strength (studs)
	JUMP_DURATION    = 0.18,								-- Trigger a bit before the jump point (studs)
	JUMP_LEAD        = 1.0, 								-- Agent settings (02 differs: allows jumping)
	AGENT = {
		AgentRadius  = 2,
		AgentHeight  = 3,
		AgentCanJump = true,
	}
}

local function primaryBottomOffset()
	local cf, size = character:GetBoundingBox()
	return character.PrimaryPart.Position.Y - (cf.Position.Y - size.Y/2)
end
local PRIMARY_BOTTOM = primaryBottomOffset()

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

local walkTrack = safeLoadAnimation(animator, CONFIG.WALK_ANIM_ID, true)
local idleTrack = safeLoadAnimation(animator, CONFIG.IDLE_ANIM_ID, true)
-- Optional jump track (non-looping)
local jumpTrack = safeLoadAnimation(animator, CONFIG.JUMP_ANIM_ID, false)

local function playWalk()
	if walkTrack and not walkTrack.IsPlaying then walkTrack:Play(0.1) end
	if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.1) end
end

local function playIdle()
	if idleTrack and not idleTrack.IsPlaying then idleTrack:Play(0.1) end
	if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.1) end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { character }

do
	for _, inst in ipairs(character:GetDescendants()) do
	if inst:IsA("MeshPart") then
			inst.CanQuery = false
			inst.CanTouch = false
			inst.CanCollide = false
		end
	end
	if character.PrimaryPart then
		character.PrimaryPart.Anchored = true
	end
end

local path = PathfindingService:CreatePath(CONFIG.AGENT)

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

local WAYPOINT_PARTS = {}
do
	for _, inst in ipairs(CONFIG.WAYPOINTS:GetDescendants()) do
		if inst:IsA("BasePart") then
			table.insert(WAYPOINT_PARTS, inst)
		end
	end
end

local lastTargetPart: BasePart? = nil

local function pickWaypoint()
	if #WAYPOINT_PARTS == 0 then return end
	shuffle(WAYPOINT_PARTS)

	-- Offset start a bit to avoid degenerate paths starting inside the agent
	local startOffset = CONFIG.START_OFFSET or Vector3.new(-5, 0, 0) -- match step 01 default
	local start = character.PrimaryPart.Position + startOffset

	-- avoid the last target if possible
	for _, part in ipairs(WAYPOINT_PARTS) do
		if part and part.Parent and part ~= lastTargetPart then
			path:ComputeAsync(start, part.Position)
			if path.Status == Enum.PathStatus.Success then
				lastTargetPart = part
				return part, path:GetWaypoints()
			end
		end
	end
end

-- Variables for lightweight hop
local root = character.PrimaryPart
local rootAttachment = root:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", root)

-- Lightweight hop using LinearVelocity
local function hop(strength, duration)
	local wasPlaying = walkTrack and walkTrack.IsPlaying
	if wasPlaying and walkTrack then walkTrack:AdjustSpeed(0.8) end
	if jumpTrack then jumpTrack:Play(0.05) end

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = rootAttachment
	lv.MaxForce = 1e6
	lv.VectorVelocity = Vector3.new(0, strength, 0)
	lv.Parent = root
	
	task.delay(duration, function()
		if lv then lv:Destroy() end
		if wasPlaying and walkTrack then walkTrack:AdjustSpeed(1.0) end
	end)
end

local function follow(waypoints, goalPos)
	local pp = character.PrimaryPart
	local hopped = {}
	-- During this window we keep physics-driven Y and reduce air control
	local jumpUntil = 0

	playWalk()

	local i = 1
	while character.Parent do
		local current = pp.Position
		local wp = waypoints[i]
		local target = (wp and wp.Position) or goalPos

		local flat = Vector3.new(target.X - current.X, 0, target.Z - current.Z)
		local dist = flat.Magnitude

		if dist <= CONFIG.STOP_DISTANCE then
			i += 1
			if i > #waypoints then break end
		else
			local dt = RunService.Heartbeat:Wait()

			-- Simple early jump trigger: distance to current or next jump waypoint
			local triggerRadius = (CONFIG.JUMP_TRIGGER_DIST or 4.0) + (CONFIG.JUMP_LEAD or 0)
			local current2D = Vector3.new(current.X, 0, current.Z)
			if wp and wp.Action == Enum.PathWaypointAction.Jump and not hopped[i] then
				local c = Vector3.new(wp.Position.X, 0, wp.Position.Z)
				if (c - current2D).Magnitude <= triggerRadius then
					hopped[i] = true
					hop(CONFIG.JUMP_STRENGTH, CONFIG.JUMP_DURATION)
					jumpUntil = time() + CONFIG.JUMP_DURATION
				end
			elseif waypoints[i+1] and waypoints[i+1].Action == Enum.PathWaypointAction.Jump and not hopped[i+1] then
				local c = Vector3.new(waypoints[i+1].Position.X, 0, waypoints[i+1].Position.Z)
				if (c - current2D).Magnitude <= triggerRadius then
					hopped[i+1] = true
					hop(CONFIG.JUMP_STRENGTH, CONFIG.JUMP_DURATION)
					jumpUntil = time() + CONFIG.JUMP_DURATION
				end
			end

			-- Proceed movement (no air-control scaling)
			local inAir = time() < jumpUntil
			local step = math.min(dist, CONFIG.MOVE_SPEED * dt)
			local dir = (dist > 0) and flat.Unit or Vector3.zero
			local nx, nz = current.X + dir.X * step, current.Z + dir.Z * step


			-- Y handling: if jumping, keep physics-driven Y; otherwise snap to ground
			local ny
			if inAir then
				-- keep current physics Y to avoid fighting LinearVelocity
				ny = current.Y
			else
				local origin = Vector3.new(nx, current.Y + CONFIG.RAYCAST_UP, nz)
				local cast = workspace:Raycast(origin, Vector3.new(0, -(CONFIG.RAYCAST_UP + CONFIG.RAYCAST_DEPTH), 0), rayParams)
				local gy = cast and cast.Position.Y or current.Y
				ny = gy + PRIMARY_BOTTOM + CONFIG.FOOT_CLEARANCE
			end

			local face = CFrame.lookAt(current, Vector3.new(target.X, current.Y, target.Z))
			local rot = pp.CFrame.Rotation:Lerp(face.Rotation, math.clamp(CONFIG.TURN_SPEED_RAD * dt, 0, 1))

			pp.CFrame = CFrame.new(nx, ny, nz) * rot
		end
	end

	playIdle()
end

while character.Parent do
	local part, waypoints = pickWaypoint()
	if not part or not waypoints then
		warn("No reachable waypoints in workspace.Waypoints")
		playIdle()
		task.wait(2)
	else
		follow(waypoints, part.Position)
		playIdle()
		task.wait(math.random(CONFIG.IDLE_MIN, CONFIG.IDLE_MAX))
	end
end
