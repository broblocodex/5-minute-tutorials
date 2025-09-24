-- Step 02 (Server) - Possession Swap
-- What: Toggle between autonomous patrol and player-driven control using RemoteEvents.
-- Why: Lets designers click an NPC to possess it, then release to resume patrol.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = script.Parent
assert(character and character:IsA("Model"), "Script must be inside an NPC Model.")

local humanoid: Humanoid = character:WaitForChild("Humanoid")
assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Import the FBX as an R15 rig.")

local rootPart: BasePart = character:WaitForChild("HumanoidRootPart")

local CONFIG = {
        WAYPOINT_FOLDER = workspace:WaitForChild("PatrolWaypoints"),
        REMOTE_FOLDER = "NPCControl",
        EVENTS = {
                Request = "RequestPossess",
                Release = "ReleasePossess",
                Input = "MoveInput",
                Camera = "CameraSwap",
        },
        PAUSE_RANGE = NumberRange.new(1.5, 3.5),
        PATH_AGENT = {
                AgentRadius = 3,
                AgentHeight = 6,
                AgentCanJump = false,
        },
}

local function ensureRemote(folder: Instance, name: string)
        local event = folder:FindFirstChild(name)
        if not event then
                event = Instance.new("RemoteEvent")
                event.Name = name
                event.Parent = folder
        end
        return event :: RemoteEvent
end

local remoteFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_FOLDER)
if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = CONFIG.REMOTE_FOLDER
        remoteFolder.Parent = ReplicatedStorage
end

local requestEvent = ensureRemote(remoteFolder, CONFIG.EVENTS.Request)
local releaseEvent = ensureRemote(remoteFolder, CONFIG.EVENTS.Release)
local inputEvent = ensureRemote(remoteFolder, CONFIG.EVENTS.Input)
local cameraEvent = ensureRemote(remoteFolder, CONFIG.EVENTS.Camera)

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

local behavior = {
        mode = "PATROL", -- PATROL | POSSESSED
        index = 0,
        token = 0,
}

local controller: Player? = nil

local function setNetworkOwner(owner: Player?)
        if rootPart then
                local ok, err = pcall(function()
                        rootPart:SetNetworkOwner(owner)
                end)
                if not ok then
                        warn("Network ownership change failed:", err)
                end
        end
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
                if behavior.token ~= token or behavior.mode ~= "PATROL" then
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

local function nextWaypoint()
        behavior.index += 1
        if behavior.index > #WAYPOINTS then
                behavior.index = 1
        end
        return WAYPOINTS[behavior.index]
end

local function stopBehavior()
        behavior.token += 1
        humanoid:Move(Vector3.zero, false)
end

local function startPatrol()
        stopBehavior()
        behavior.mode = "PATROL"
        local token = behavior.token
        task.spawn(function()
                while behavior.token == token and behavior.mode == "PATROL" do
                        local waypoint = nextWaypoint()
                        local pathWaypoints = computePath(waypoint.Position)
                        followPath(pathWaypoints, token)
                        if behavior.token ~= token or behavior.mode ~= "PATROL" then
                                break
                        end
                        local pause = math.random() * (CONFIG.PAUSE_RANGE.Max - CONFIG.PAUSE_RANGE.Min) + CONFIG.PAUSE_RANGE.Min
                        task.wait(pause)
                end
        end)
end

local function beginPossession(player: Player)
        stopBehavior()
        behavior.mode = "POSSESSED"
        controller = player
        setNetworkOwner(player)
        humanoid.AutoRotate = true
        humanoid:Move(Vector3.zero, false)
        cameraEvent:FireClient(player, character, "Possess")
end

local function endPossession()
        if controller then
                cameraEvent:FireClient(controller, nil, "Release")
        end
        controller = nil
        setNetworkOwner(nil)
        startPatrol()
end

startPatrol()

requestEvent.OnServerEvent:Connect(function(player, target)
        if target ~= character then
                return
        end
        if behavior.mode == "POSSESSED" then
                cameraEvent:FireClient(player, nil, "Busy")
                return
        end
        beginPossession(player)
end)

releaseEvent.OnServerEvent:Connect(function(player, target)
        if player ~= controller or target ~= character then
                return
        end
        endPossession()
end)

inputEvent.OnServerEvent:Connect(function(player, target, moveDir: Vector3?, jumpRequested: boolean?)
        if player ~= controller or target ~= character then
                return
        end
        if typeof(moveDir) == "Vector3" then
                humanoid:Move(moveDir, false)
        end
        if jumpRequested then
                humanoid.Jump = true
        end
end)

humanoid.Died:Connect(function()
        stopBehavior()
        if controller then
                endPossession()
        end
        playIdle()
end)

Players.PlayerRemoving:Connect(function(player)
        if player == controller then
                endPossession()
        end
end)
