local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "k3wlgui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Scale = UserInputService.TouchEnabled and 1.15 or 1
scale.Parent = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 260)
main.Position = UDim2.new(0.5, -170, 0.5, -130)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 75)
header.BackgroundColor3 = Color3.fromRGB(190, 0, 0)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 42)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "k3wlgui: SAB"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = header

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1, -20, 0, 20)
credit.Position = UDim2.new(0, 10, 0, 48)
credit.BackgroundTransparency = 1
credit.Text = "by k3wlkid"
credit.TextColor3 = Color3.fromRGB(230, 230, 230)
credit.TextScaled = true
credit.Font = Enum.Font.Gotham
credit.Parent = header

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 35)
status.Position = UDim2.new(0, 15, 0, 87)
status.BackgroundTransparency = 1
status.Text = "Status: Ready"
status.TextColor3 = Color3.new(1, 1, 1)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = main

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(1, -30, 0, 55)
startButton.Position = UDim2.new(0, 15, 0, 125)
startButton.BackgroundColor3 = Color3.fromRGB(215, 0, 0)
startButton.Text = "START STEAL LOOP"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextScaled = true
startButton.Font = Enum.Font.GothamBold
startButton.BorderSizePixel = 0
startButton.Parent = main

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 10)
startCorner.Parent = startButton

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(1, -30, 0, 55)
stopButton.Position = UDim2.new(0, 15, 0, 190)
stopButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
stopButton.Text = "STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextScaled = true
stopButton.Font = Enum.Font.GothamBold
stopButton.BorderSizePixel = 0
stopButton.Parent = main

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 10)
stopCorner.Parent = stopButton

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

local running = false
local stopRequested = false
local currentPrompt = nil

local MAX_LOOPS = 10
local HOLD_TIME = 5

local function findNearestStealPrompt(root)

	local nearestPrompt = nil
	local nearestDistance = math.huge

	for _, object in ipairs(workspace:GetDescendants()) do

		if object:IsA("ProximityPrompt")
			and object.Enabled then

			local text = string.lower(object.ActionText or "")

			if string.find(text, "steal") then

				local position

				if object.Parent:IsA("BasePart") then
					position = object.Parent.Position

				elseif object.Parent:IsA("Attachment") then
					position = object.Parent.WorldPosition
				end

				if position then

					local distance =
						(root.Position - position).Magnitude

					if distance < nearestDistance then
						nearestDistance = distance
						nearestPrompt = object
					end
				end
			end
		end
	end

	return nearestPrompt
end

local function startHold(prompt)

	if not prompt
		or not prompt.Parent
		or not prompt.Enabled then

		return false
	end

	currentPrompt = prompt

	status.Text = "Status: Holding for 5 seconds..."

	prompt:InputHoldBegin()

	local startTime = os.clock()

	while os.clock() - startTime < HOLD_TIME do

		if stopRequested then
			prompt:InputHoldEnd()
			currentPrompt = nil
			return false
		end

		if not prompt.Parent then
			currentPrompt = nil
			return false
		end

		task.wait(0.01)
	end

	prompt:InputHoldEnd()

	currentPrompt = nil

	task.wait(0.15)

	return true
end

local function startLoop()

	if running then
		return
	end

	running = true
	stopRequested = false

	startButton.Text = "RUNNING..."
	startButton.Active = false

	local character =
		player.Character or player.CharacterAdded:Wait()

	local root =
		character:WaitForChild("HumanoidRootPart")

	local originalPosition = root.CFrame

	for i = 1, MAX_LOOPS do

		if stopRequested then
			break
		end

		status.Text =
			"Status: Finding Steal " ..
			i .. "/" .. MAX_LOOPS

		local prompt =
			findNearestStealPrompt(root)

		if not prompt then
			status.Text = "Status: No Steal prompt found"
			break
		end

		character =
			player.Character or player.CharacterAdded:Wait()

		root =
			character:WaitForChild("HumanoidRootPart")

		local targetPosition

		if prompt.Parent:IsA("BasePart") then
			targetPosition = prompt.Parent.Position

		elseif prompt.Parent:IsA("Attachment") then
			targetPosition = prompt.Parent.WorldPosition
		end

		if not targetPosition then
			status.Text = "Status: Invalid prompt"
			break
		end

		-- Teleport to prompt
		root.CFrame =
			CFrame.new(
				targetPosition + Vector3.new(0, 2, 0)
			)

		-- Fully zoom camera out
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 128

		task.wait(0.15)

		if stopRequested then
			break
		end

		-- Hold for exactly 5 seconds
		local completed =
			startHold(prompt)

		if not completed then
			break
		end

		if stopRequested then
			break
		end

		status.Text = "Status: Steal complete!"

		task.wait(0.15)

		character =
			player.Character or player.CharacterAdded:Wait()

		root =
			character:WaitForChild("HumanoidRootPart")

		-- Return to original position
		root.CFrame = originalPosition

		task.wait(0.2)
	end

	if currentPrompt then
		pcall(function()
			currentPrompt:InputHoldEnd()
		end)
	end

	currentPrompt = nil
	running = false
	stopRequested = false

	startButton.Text = "START STEAL LOOP"
	startButton.Active = true

	status.Text = "Status: Finished"
end

startButton.Activated:Connect(function()
	task.spawn(startLoop)
end)

stopButton.Activated:Connect(function()

	if not running then
		status.Text = "Status: Not running"
		return
	end

	stopRequested = true

	if currentPrompt then
		pcall(function()
			currentPrompt:InputHoldEnd()
		end)
	end

	status.Text = "Status: Stopping..."
end)
