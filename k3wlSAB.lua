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
main.Size = UDim2.new(0, 330, 0, 215)
main.Position = UDim2.new(0.5, -165, 0.5, -107)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 75)
header.BackgroundColor3 = Color3.fromRGB(190, 0, 0)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 14)
headerCover.Position = UDim2.new(0, 0, 1, -14)
headerCover.BackgroundColor3 = Color3.fromRGB(190, 0, 0)
headerCover.BorderSizePixel = 0
headerCover.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 42)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "k3wlgui: SAB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
status.Position = UDim2.new(0, 15, 0, 88)
status.BackgroundTransparency = 1
status.Text = "Status: Ready"
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = main

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(1, -30, 0, 65)
startButton.Position = UDim2.new(0, 15, 0, 135)
startButton.BackgroundColor3 = Color3.fromRGB(215, 0, 0)
startButton.Text = "START STEAL LOOP"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextScaled = true
startButton.Font = Enum.Font.GothamBold
startButton.BorderSizePixel = 0
startButton.AutoButtonColor = true
startButton.Parent = main

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = startButton

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end

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
	if dragging then
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end
end)

local running = false
local MAX_LOOPS = 10

local function findNearestStealPrompt(root)
	local nearestPrompt = nil
	local nearestDistance = math.huge

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("ProximityPrompt") then
			local actionText = string.lower(object.ActionText or "")

			if string.find(actionText, "steal") then
				local targetPosition

				if object.Parent:IsA("BasePart") then
					targetPosition = object.Parent.Position
				elseif object.Parent:IsA("Attachment") then
					targetPosition = object.Parent.WorldPosition
				end

				if targetPosition then
					local distance = (root.Position - targetPosition).Magnitude

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

local function holdPromptUntilFinished(prompt)
	if not prompt or not prompt.Parent or not prompt.Enabled then
		return false
	end

	status.Text = "Status: Holding..."

	local holdDuration = prompt.HoldDuration

	prompt:InputHoldBegin()

	-- Keep holding for the complete required duration.
	task.wait(holdDuration)

	prompt:InputHoldEnd()

	-- Allow the interaction to finish processing.
	task.wait(0.1)

	return true
end

local function startStealLoop()
	if running then
		return
	end

	running = true
	startButton.Text = "RUNNING..."
	startButton.Active = false

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")

	-- Save the original position.
	local originalPosition = root.CFrame

	for i = 1, MAX_LOOPS do
		status.Text = "Status: Finding Steal " .. i .. "/" .. MAX_LOOPS

		local prompt = findNearestStealPrompt(root)

		if not prompt then
			status.Text = "Status: No Steal prompt found"
			break
		end

		character = player.Character or player.CharacterAdded:Wait()
		root = character:WaitForChild("HumanoidRootPart")

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

		-- Teleport to the nearest Steal prompt.
		root.CFrame = CFrame.new(
			targetPosition + Vector3.new(0, 2, 0)
		)

		task.wait()

		-- Hold until the full HoldDuration has elapsed.
		local completed = holdPromptUntilFinished(prompt)

		if not completed then
			status.Text = "Status: Steal failed"
			break
		end

		status.Text = "Status: Steal complete!"

		task.wait(0.1)

		character = player.Character or player.CharacterAdded:Wait()
		root = character:WaitForChild("HumanoidRootPart")

		-- Return to the original position only after releasing the prompt.
		root.CFrame = originalPosition

		task.wait(0.15)
	end

	running = false
	startButton.Active = true
	startButton.Text = "START STEAL LOOP"
	status.Text = "Status: Finished"
end

startButton.Activated:Connect(startStealLoop)
