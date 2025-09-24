-- Step 03 (Client) - Follow command companion
-- Drop in StarterPlayerScripts. Adds keybinds for Follow/Patrol commands while keeping possession controls.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remoteFolder = ReplicatedStorage:WaitForChild("NPCControl")
local requestEvent = remoteFolder:WaitForChild("RequestPossess")
local releaseEvent = remoteFolder:WaitForChild("ReleasePossess")
local inputEvent = remoteFolder:WaitForChild("MoveInput")
local cameraEvent = remoteFolder:WaitForChild("CameraSwap")
local modeEvent = remoteFolder:WaitForChild("SetMode")

local controllingModel: Model? = nil
local controllingHumanoid: Humanoid? = nil
local pendingJump = false
local moveState = {
        Forward = 0,
        Right = 0,
}

local function setCameraSubject(subject)
        local camera = workspace.CurrentCamera
        if camera then
                camera.CameraSubject = subject
        end
end

local function getDefaultSubject()
        local char = player.Character
        if char then
                return char:FindFirstChildOfClass("Humanoid")
        end
end

local function resolveNPCModel(target: Instance?): Model?
        if not target then
                return nil
        end
        local model = target:FindFirstAncestorWhichIsA("Model")
        if model and model:FindFirstChildOfClass("Humanoid") then
                return model
        end
        return nil
end

local function moveVector(): Vector3
        local camera = workspace.CurrentCamera
        if not camera then
                return Vector3.zero
        end
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        forward = Vector3.new(forward.X, 0, forward.Z)
        right = Vector3.new(right.X, 0, right.Z)
        if forward.Magnitude < 1e-4 then
                forward = Vector3.new(0, 0, -1)
        end
        if right.Magnitude < 1e-4 then
                right = Vector3.new(1, 0, 0)
        end
        forward = forward.Unit
        right = right.Unit

        local dir = forward * moveState.Forward + right * moveState.Right
        if dir.Magnitude > 1 then
                dir = dir.Unit
        end
        return dir
end

RunService.RenderStepped:Connect(function()
        if controllingModel and controllingHumanoid then
                inputEvent:FireServer(controllingModel, moveVector(), pendingJump)
                pendingJump = false
        end
end)

local PRESS_TO_VALUE = {
        [Enum.KeyCode.W] = {axis = "Forward", value = 1},
        [Enum.KeyCode.S] = {axis = "Forward", value = -1},
        [Enum.KeyCode.D] = {axis = "Right", value = 1},
        [Enum.KeyCode.A] = {axis = "Right", value = -1},
}

local function sendMode(modeName: string)
        local targetModel = resolveNPCModel(mouse.Target)
        if targetModel then
                modeEvent:FireServer(targetModel, modeName)
        end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
                return
        end
        local mapping = PRESS_TO_VALUE[input.KeyCode]
        if mapping then
                moveState[mapping.axis] += mapping.value
        elseif input.KeyCode == Enum.KeyCode.Space then
                if controllingModel then
                        pendingJump = true
                end
        elseif input.KeyCode == Enum.KeyCode.Q then
                if controllingModel then
                        releaseEvent:FireServer(controllingModel)
                end
        elseif input.KeyCode == Enum.KeyCode.F then
                sendMode("Follow")
        elseif input.KeyCode == Enum.KeyCode.E then
                sendMode("Patrol")
        end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
        local mapping = PRESS_TO_VALUE[input.KeyCode]
        if mapping then
                moveState[mapping.axis] -= mapping.value
        end
end)

mouse.Button1Down:Connect(function()
        if controllingModel then
                return
        end
        local targetModel = resolveNPCModel(mouse.Target)
        if targetModel then
                requestEvent:FireServer(targetModel)
        end
end)

cameraEvent.OnClientEvent:Connect(function(targetModel: Model?, state: string?)
        controllingModel = targetModel
        if targetModel then
                controllingHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
                if controllingHumanoid then
                        setCameraSubject(controllingHumanoid)
                end
        else
                controllingHumanoid = nil
                setCameraSubject(getDefaultSubject())
        end
end)

player.CharacterAdded:Connect(function()
        if not controllingModel then
                setCameraSubject(getDefaultSubject())
        end
end)
