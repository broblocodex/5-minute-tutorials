-- Step 01 - Walking Patrol
-- What: NPC walks an endless patrol by pathing between waypoint Parts.
-- Why: Foundation for smarter behaviors (possession, following, commands).

local PathfindingService = game:GetService("PathfindingService")

local character = script.Parent
assert(character and character:IsA("Model"), "Script must be inside an NPC Model.")

local humanoid: Humanoid = character:WaitForChild("Humanoid")
assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Import the FBX as an R15 rig.")

local rootPart: BasePart = character:WaitForChild("HumanoidRootPart")

local CONFIG = {
        WAYPOINT_FOLDER = workspace:WaitForChild("PatrolWaypoints"),
        PAUSE_RANGE = NumberRange.new(1.5, 3), -- idle between waypoints (seconds)
        PATH_AGENT = {
                AgentRadius = 3,
                AgentHeight = 6,
                AgentCanJump = false,
        },
}

local DEFAULT_ANIMS = {
        Idle = "rbxassetid://507766666",
        Walk = "rbxassetid://507777826",
        Run  = "rbxassetid://507767714",
}

local tracks = {}

local function loadLoop(name: string, assetId: string)
        local anim = Instance.new("Animation")
        anim.Name = name .. "Animation"
        anim.AnimationId = assetId
        local ok, track = pcall(function()
                return humanoid:LoadAnimation(anim)
        end)
        anim:Destroy()
        if ok and track then
                track.Name = name
                track.Looped = true
                return track
        end
        warn(("[%s] Failed to load animation %s"):format(script.Name, name))
        return nil
end

tracks.Idle = loadLoop("Idle", DEFAULT_ANIMS.Idle)
tracks.Walk = loadLoop("Walk", DEFAULT_ANIMS.Walk)
tracks.Run  = loadLoop("Run", DEFAULT_ANIMS.Run)

local function play(track: AnimationTrack?, fade)
        if track and not track.IsPlaying then
                track:Play(fade or 0.2)
        end
end

local function stop(track: AnimationTrack?, fade)
        if track and track.IsPlaying then
                track:Stop(fade or 0.2)
        end
end

local function playIdle()
        play(tracks.Idle)
        stop(tracks.Walk)
        stop(tracks.Run)
end

local function playMove(speed: number)
        if speed > humanoid.WalkSpeed * 1.2 and tracks.Run then
                play(tracks.Run)
                stop(tracks.Walk)
                stop(tracks.Idle)
        elseif speed > 0.1 and tracks.Walk then
                play(tracks.Walk)
                stop(tracks.Idle)
                stop(tracks.Run)
        else
                playIdle()
        end
end

playIdle()

humanoid.Running:Connect(function(speed)
        playMove(speed)
end)

local path = PathfindingService:CreatePath(CONFIG.PATH_AGENT)

local WAYPOINTS: {BasePart} = {}
for _, inst in ipairs(CONFIG.WAYPOINT_FOLDER:GetChildren()) do
        if inst:IsA("BasePart") then
                table.insert(WAYPOINTS, inst)
        end
end
assert(#WAYPOINTS > 0, "Populate PatrolWaypoints with anchored, non-colliding Parts.")

local patrolState = {
        index = 0,
        token = 0,
}

local function getNextWaypoint()
        patrolState.index += 1
        if patrolState.index > #WAYPOINTS then
                patrolState.index = 1
        end
        return WAYPOINTS[patrolState.index]
end

local function computePath(goal: Vector3)
        path:ComputeAsync(rootPart.Position, goal)
        if path.Status == Enum.PathStatus.Success then
                return path:GetWaypoints()
        end
        warn(("[%s] Path failed (%s)"):format(script.Name, tostring(path.Status)))
        return nil
end

local function followPath(waypoints, token)
        if not waypoints then
                return
        end
        for i = 2, #waypoints do
                if patrolState.token ~= token then
                        return
                end
                local waypoint = waypoints[i]
                humanoid:MoveTo(waypoint.Position)
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoid.Jump = true
                end
                humanoid.MoveToFinished:Wait()
        end
end

local function startPatrol()
        patrolState.token += 1
        local token = patrolState.token
        task.spawn(function()
                while patrolState.token == token do
                        local waypointPart = getNextWaypoint()
                        local pathWaypoints = computePath(waypointPart.Position)
                        followPath(pathWaypoints, token)
                        if patrolState.token ~= token then
                                break
                        end
                        local pause = math.random() * (CONFIG.PAUSE_RANGE.Max - CONFIG.PAUSE_RANGE.Min) + CONFIG.PAUSE_RANGE.Min
                        task.wait(pause)
                end
        end)
end

startPatrol()

humanoid.Died:Once(function()
        patrolState.token += 1
        playIdle()
end)
