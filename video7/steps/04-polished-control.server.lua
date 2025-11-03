-- Step 04 (Server) - Polished Control
-- What: Broadcast behavior changes, color the NPC, and emit light SFX/VFX cues for Patrol/Possess/Follow.
-- Why: Makes the mode toggles obvious to players and ties into the client UI.

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
                Mode = "SetMode",
                Broadcast = "ModeBroadcast",
        },
        PAUSE_RANGE = NumberRange.new(1.5, 3.5),
        PATH_AGENT = {
                AgentRadius = 3,
                AgentHeight = 6,
                AgentCanJump = false,
        },
        FOLLOW_DISTANCE = 6,
        FOLLOW_REPATH = 0.45,
        FOLLOW_OFFSET = Vector3.new(0, 0, 6),
        MODE_COLORS = {
                PATROL = Color3.fromRGB(50, 181, 255),
                POSSESSED = Color3.fromRGB(255, 202, 40),
                FOLLOW = Color3.fromRGB(120, 255, 120),
        },
        MODE_SOUND_ID = "rbxassetid://9118823101", -- replace with your own UI blip
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
local modeEvent = ensureRemote(remoteFolder, CONFIG.EVENTS.Mode)
local broadcastEvent = ensureRemote(remoteFolder, CONFIG.EVENTS.Broadcast)

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
        mode = "PATROL", -- PATROL | POSSESSED | FOLLOW
        index = 0,
        token = 0,
}

local controller: Player? = nil
local followTarget: Player? = nil

local highlight = character:FindFirstChildWhichIsA("Highlight")
if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ModeHighlight"
        highlight.Parent = character
end
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.FillTransparency = 0.7
highlight.Enabled = true

local fxAttachment = rootPart:FindFirstChild("ModeFX")
if not fxAttachment then
        fxAttachment = Instance.new("Attachment")
        fxAttachment.Name = "ModeFX"
        fxAttachment.Parent = rootPart
end

local sparkle = fxAttachment:FindFirstChild("ModeSparkle")
if not sparkle then
        sparkle = Instance.new("ParticleEmitter")
        sparkle.Name = "ModeSparkle"
        sparkle.Texture = "rbxassetid://258128463" -- subtle sparkle texture
        sparkle.Speed = NumberRange.new(4, 7)
        sparkle.Lifetime = NumberRange.new(0.3, 0.55)
        sparkle.Rate = 0
        sparkle.SpreadAngle = Vector2.new(45, 45)
        sparkle.Parent = fxAttachment
end

local modeSound = rootPart:FindFirstChild("ModeBlip")
if not modeSound then
        modeSound = Instance.new("Sound")
        modeSound.Name = "ModeBlip"
        modeSound.Volume = 0.5
        modeSound.SoundId = CONFIG.MODE_SOUND_ID
        modeSound.Parent = rootPart
end

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

local function followPathOnce(waypoints, token)
        if not waypoints then
                return
        end
        for i = 2, #waypoints do
                if behavior.token ~= token or behavior.mode ~= "FOLLOW" then
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

local function signalMode(modeName: string)
        behavior.mode = modeName
        local color = CONFIG.MODE_COLORS[modeName]
        if color then
                highlight.FillColor = color
                highlight.OutlineColor = color
        end
        sparkle:Emit(10)
        local ok = pcall(function()
                modeSound:Play()
        end)
        if not ok then
                -- ignore play failures (e.g., sound not loaded)
        end
        broadcastEvent:FireAllClients(character, modeName)
end

local function startPatrol()
        stopBehavior()
        followTarget = nil
        signalMode("PATROL")
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
        followTarget = nil
        controller = player
        setNetworkOwner(player)
        humanoid:Move(Vector3.zero, false)
        signalMode("POSSESSED")
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

local function followPlayer(targetPlayer: Player)
        stopBehavior()
        followTarget = targetPlayer
        signalMode("FOLLOW")
        local token = behavior.token
        task.spawn(function()
                while behavior.token == token and behavior.mode == "FOLLOW" do
                        local targetCharacter = targetPlayer.Character
                        local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
                        if not targetRoot then
                                task.wait(CONFIG.FOLLOW_REPATH)
                                continue
                        end
                        local offsetCF = targetRoot.CFrame * CFrame.new(CONFIG.FOLLOW_OFFSET)
                        local goalPosition = offsetCF.Position
                        local distance = (goalPosition - rootPart.Position).Magnitude
                        if distance > CONFIG.FOLLOW_DISTANCE then
                                local waypoints = computePath(goalPosition)
                                if behavior.mode ~= "FOLLOW" or behavior.token ~= token then
                                        return
                                end
                                followPathOnce(waypoints, token)
                        end
                        task.wait(CONFIG.FOLLOW_REPATH)
                end
        end)
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

modeEvent.OnServerEvent:Connect(function(player, target, mode)
        if target ~= character then
                return
        end
        if behavior.mode == "POSSESSED" and player ~= controller then
                return
        end
        if mode == "Patrol" then
                startPatrol()
        elseif mode == "Follow" then
                followPlayer(player)
        end
end)

humanoid.Died:Connect(function()
        stopBehavior()
        if controller then
                endPossession()
        end
        followTarget = nil
        playIdle()
        signalMode("PATROL")
end)

Players.PlayerAdded:Connect(function(player)
        broadcastEvent:FireClient(player, character, behavior.mode)
end)

Players.PlayerRemoving:Connect(function(player)
        if player == controller then
                endPossession()
        elseif player == followTarget then
                startPatrol()
        end
end)
