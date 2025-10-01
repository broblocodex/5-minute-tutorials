-- Step 00 - Imported Character Idle/Walk Harness
-- What: Attach Roblox's default idle + walk animations to an imported R15 humanoid.
-- Why: Smoke test your Meshy NPC before layering patrol logic or remote control.

local character = script.Parent
assert(character and character:IsA("Model"), "Script must be parented to an NPC Model.")

local humanoid: Humanoid = character:WaitForChild("Humanoid")
assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Import the FBX as an R15 rig.")

-- Default Roblox animation asset ids for R15 rigs
local DEFAULT_ANIMS = {
        Idle = "rbxassetid://507766666",
        Walk = "rbxassetid://507777826",
        Run  = "rbxassetid://507767714",
}

local tracks = {}

local function loadLoop(name: string, assetId: string)
        if assetId == "" then
                return nil
        end
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

humanoid.Died:Once(function()
        for _, track in pairs(tracks) do
                stop(track, 0)
        end
end)
