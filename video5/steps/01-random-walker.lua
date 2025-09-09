-- Step 01 - Random Walker (no jumps)
-- What: NPC walks between Parts under `workspace.Waypoints` with smooth rotation and ground snapping.
-- Why: Establish baseline locomotion and confirm rig/animations before adding jumps.

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
	WAYPOINTS       = workspace:WaitForChild("Waypoints"),    -- Folder of BaseParts used as navigation targets
	MOVE_SPEED      = 10,                                     -- Forward speed in studs/second
	TURN_SPEED_RAD  = math.rad(180),                          -- Max turn rate (radians/second) when lerping facing
	IDLE_MIN        = 2,                                      -- Min idle time (s) between legs
	IDLE_MAX        = 5,                                      -- Max idle time (s) between legs
	RAYCAST_UP      = 100,                                    -- How high above current pos to start ground raycast
	RAYCAST_DEPTH   = 300,                                    -- Extra downward distance (total cast = up + depth)
	FOOT_CLEARANCE  = 0.05,                                   -- Hover height above hit ground to avoid clipping
	STOP_DISTANCE   = 2.5,                                    -- Horizontal distance to consider a waypoint reached
	START_OFFSET    = Vector3.new(-5, 0, 0),                  -- Offset applied to path start to avoid local collisions
	WALK_ANIM_ID    = "rbxassetid://WALK_ANIMATION_ID",       -- Walk loop anim id (empty to disable)
	IDLE_ANIM_ID    = "rbxassetid://IDLE_ANIMATION_ID",       -- Idle loop anim id (empty to disable)
	AGENT = {                                                 -- Pathfinding agent settings
		AgentRadius  = 2,                                     -- Collision radius (studs)
		AgentHeight  = 3,                                     -- Agent height (studs)
		AgentCanJump = false,                                 -- Disallow jumps for ground-only paths
	}
}

local function primaryBottomOffset()
	local cf, size = character:GetBoundingBox()
	return character.PrimaryPart.Position.Y - (cf.Position.Y - size.Y/2)
end
-- Vertical offset from PrimaryPart to the model's bottom (used to place feet on ground)
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

local function playWalk()
	-- Crossfade to walk, stop idle if playing
	if walkTrack and not walkTrack.IsPlaying then walkTrack:Play(0.1) end
	if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.1) end
end

local function playIdle()
	-- Crossfade to idle, stop walk if playing
	if idleTrack and not idleTrack.IsPlaying then idleTrack:Play(0.1) end
	if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.1) end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { character } -- Ignore self in ground raycasts

do
	for _, inst in ipairs(character:GetDescendants()) do
	if inst:IsA("MeshPart") then
			inst.CanQuery = false
		end
	end
	if character.PrimaryPart then
		character.PrimaryPart.Anchored = true
	end
end

-- Reusable Path object configured with our agent settings
local path = PathfindingService:CreatePath(CONFIG.AGENT)

local function shuffle(t)
	-- Fisher–Yates shuffle for randomizing waypoint order
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

local WAYPOINT_PARTS = {}
do
	-- Collect all BaseParts under WAYPOINTS once at startup
	for _, inst in ipairs(CONFIG.WAYPOINTS:GetDescendants()) do
		if inst:IsA("BasePart") then
			table.insert(WAYPOINT_PARTS, inst)
		end
	end
end

local lastTargetPart: BasePart? = nil

local function pickWaypoint()
	-- Choose the first reachable waypoint that's not the last target
	if #WAYPOINT_PARTS == 0 then return end
	shuffle(WAYPOINT_PARTS)

	local start = character.PrimaryPart.Position + CONFIG.START_OFFSET

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

local function follow(waypoints, goalPos)
	local pp = character.PrimaryPart
	playWalk()

	local i = 1
	while character.Parent do
		local current = pp.Position
		local wp = waypoints[i]
		local target = (wp and wp.Position) or goalPos

		-- Horizontal (XZ) vector toward target and its distance
		local flat = Vector3.new(target.X - current.X, 0, target.Z - current.Z)
		local dist = flat.Magnitude

		if dist <= CONFIG.STOP_DISTANCE then
			-- Advance to next path waypoint when close enough
			i += 1
			if i > #waypoints then break end
		else

			local dt = RunService.Heartbeat:Wait()
			local step = math.min(dist, CONFIG.MOVE_SPEED * dt) -- Clamp to avoid overshoot
			local dir = (dist > 0) and flat.Unit or Vector3.zero
			local nx, nz = current.X + dir.X * step, current.Z + dir.Z * step

			-- Ground snap via vertical raycast (start above, cast downward)
			local origin = Vector3.new(nx, current.Y + CONFIG.RAYCAST_UP, nz)
			local cast = workspace:Raycast(origin, Vector3.new(0, -(CONFIG.RAYCAST_UP + CONFIG.RAYCAST_DEPTH), 0), rayParams)
			local gy = cast and cast.Position.Y or current.Y
			local ny = gy + PRIMARY_BOTTOM + CONFIG.FOOT_CLEARANCE -- Place feet just above ground

			-- Smoothly rotate to face target horizontally
			local face = CFrame.lookAt(current, Vector3.new(target.X, current.Y, target.Z))
			local rot = pp.CFrame.Rotation:Lerp(face.Rotation, math.clamp(CONFIG.TURN_SPEED_RAD * dt, 0, 1))

			pp.CFrame = CFrame.new(nx, ny, nz) * rot
		end
	end

	playIdle()
end

playIdle()

while character.Parent do
	-- Pick a reachable random waypoint, then follow its computed path
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
