-- Step 04 (Client) - Polished Control companion
-- Drop in StarterPlayerScripts. Builds a mini UI and keybinds for Patrol / Possess / Follow plus camera swaps.

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
local broadcastEvent = remoteFolder:WaitForChild("ModeBroadcast")

local controllingModel: Model? = nil
local controllingHumanoid: Humanoid? = nil
local pendingJump = false
local moveState = {
        Forward = 0,
        Right = 0,
}

local selectedModel: Model? = nil
local modeCache = {}

local gui = Instance.new("ScreenGui")
gui.Name = "NPCControlGui"
gui.ResetOnSpawn = false

local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Toolbar"
frame.AnchorPoint = Vector2.new(0.5, 1)
frame.Position = UDim2.new(0.5, 0, 1, -24)
frame.Size = UDim2.fromScale(0.35, 0.12)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
frame.BackgroundTransparency = 0.25
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.55
stroke.Thickness = 1.6
stroke.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = frame

local buttonRow = Instance.new("Frame")
buttonRow.Name = "ButtonRow"
buttonRow.AnchorPoint = Vector2.new(0.5, 1)
buttonRow.Position = UDim2.new(0.5, 0, 1, -8)
buttonRow.Size = UDim2.new(1, -24, 0, 44)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 12)
listLayout.Parent = buttonRow

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 24)
title.Position = UDim2.new(0, 12, 0, 0)
title.AnchorPoint = Vector2.new(0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function createButton(labelText: string)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.3, 0, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        button.TextColor3 = Color3.fromRGB(230, 230, 230)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = button

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Thickness = 1.4
        btnStroke.Transparency = 0.35
        btnStroke.Parent = button

        button.Text = labelText
        button.Parent = buttonRow
        return button
end

local possessButton = createButton("Possess (1)")
local followButton = createButton("Follow (2)")
local patrolButton = createButton("Patrol (3)")

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

local function updateButtonStates(currentMode: string?)
        local mode = currentMode or (selectedModel and modeCache[selectedModel])
        possessButton.Text = controllingModel and controllingModel == selectedModel and "Release (1)" or "Possess (1)"

        local followActive = mode == "FOLLOW"
        local patrolActive = mode == "PATROL"

        followButton.BackgroundColor3 = followActive and Color3.fromRGB(0, 170, 85) or Color3.fromRGB(35, 35, 40)
        patrolButton.BackgroundColor3 = patrolActive and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(35, 35, 40)
end

local function updateTitle()
        if not selectedModel then
                title.Text = ""
                frame.Visible = false
                return
        end
        local mode = modeCache[selectedModel] or "?"
        if typeof(mode) == "string" and #mode > 0 then
                mode = mode:sub(1, 1) .. mode:sub(2):lower()
        end
        title.Text = string.format("%s • %s", selectedModel.Name, mode)
        frame.Visible = true
end

local function setSelectedModel(model: Model?)
        if model == selectedModel then
                return
        end
        selectedModel = model
        local cachedMode = nil
        if model then
                cachedMode = modeCache[model]
        end
        updateButtonStates(cachedMode)
        updateTitle()
end

local function requestPossess()
        if not selectedModel then
                return
        end
        if controllingModel and controllingModel == selectedModel then
                releaseEvent:FireServer(selectedModel)
        else
                requestEvent:FireServer(selectedModel)
        end
end

local function requestFollow()
        if selectedModel then
                modeEvent:FireServer(selectedModel, "Follow")
        end
end

local function requestPatrol()
        if selectedModel then
                modeEvent:FireServer(selectedModel, "Patrol")
        end
end

possessButton.Activated:Connect(requestPossess)
followButton.Activated:Connect(requestFollow)
patrolButton.Activated:Connect(requestPatrol)

RunService.RenderStepped:Connect(function()
        if controllingModel and controllingHumanoid then
                inputEvent:FireServer(controllingModel, moveVector(), pendingJump)
                pendingJump = false
        end
        setSelectedModel(resolveNPCModel(mouse.Target))
end)

local PRESS_TO_VALUE = {
        [Enum.KeyCode.W] = {axis = "Forward", value = 1},
        [Enum.KeyCode.S] = {axis = "Forward", value = -1},
        [Enum.KeyCode.D] = {axis = "Right", value = 1},
        [Enum.KeyCode.A] = {axis = "Right", value = -1},
}

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
        elseif input.KeyCode == Enum.KeyCode.One then
                requestPossess()
        elseif input.KeyCode == Enum.KeyCode.Two then
                requestFollow()
        elseif input.KeyCode == Enum.KeyCode.Three then
                requestPatrol()
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
        if selectedModel then
                requestEvent:FireServer(selectedModel)
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
        updateButtonStates()
end)

broadcastEvent.OnClientEvent:Connect(function(model: Model, mode: string)
        modeCache[model] = mode
        if model == selectedModel then
                updateTitle()
                updateButtonStates(mode)
        end
end)

player.CharacterAdded:Connect(function()
        if gui.Parent ~= playerGui then
                gui.Parent = playerGui
        end
        if not controllingModel then
                setCameraSubject(getDefaultSubject())
        end
end)

if player.Character then
        setCameraSubject(getDefaultSubject())
else
        player.CharacterAdded:Wait()
        setCameraSubject(getDefaultSubject())
end
