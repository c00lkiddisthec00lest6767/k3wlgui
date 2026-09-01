```lua
--// AIM ASSIST UI
--// For your own Roblox Studio game
--// Put this LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// SETTINGS
local AimbotEnabled = false
local FOV = 250
local Smoothness = 0.15
local MaxDistance = 300

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 210)
Main.Position = UDim2.new(0.5, -140, 0.5, -105)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

--// TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "🎯 AIM ASSIST"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--// STATUS
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -30, 0, 25)
Status.Position = UDim2.new(0, 15, 0, 45)
Status.BackgroundTransparency = 1
Status.Text = "Status: OFF"
Status.TextColor3 = Color3.fromRGB(255, 80, 80)
Status.TextSize = 16
Status.Font = Enum.Font.Gotham
Status.Parent = Main

--// TOGGLE
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -30, 0, 45)
Toggle.Position = UDim2.new(0, 15, 0, 80)
Toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Toggle.Text = "AIMBOT: OFF"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 18
Toggle.Font = Enum.Font.GothamBold
Toggle.BorderSizePixel = 0
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

Toggle.MouseButton1Click:Connect(function()
	AimbotEnabled = not AimbotEnabled

	if AimbotEnabled then
		Toggle.Text = "AIMBOT: ON"
		Toggle.BackgroundColor3 = Color3.fromRGB(45, 150, 70)
		Status.Text = "Status: ON"
		Status.TextColor3 = Color3.fromRGB(80, 255, 100)
	else
		Toggle.Text = "AIMBOT: OFF"
		Toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		Status.Text = "Status: OFF"
		Status.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

--// FOV TEXT
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -30, 0, 25)
FOVLabel.Position = UDim2.new(0, 15, 0, 135)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV: 250"
FOVLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
FOVLabel.TextSize = 15
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Parent = Main

--// FOV SLIDER
local Slider = Instance.new("TextButton")
Slider.Size = UDim2.new(1, -30, 0, 15)
Slider.Position = UDim2.new(0, 15, 0, 165)
Slider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
Slider.Text = ""
Slider.BorderSizePixel = 0
Slider.AutoButtonColor = false
Slider.Parent = Main

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(1, 0)
SliderCorner.Parent = Slider

local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(FOV / 500, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
Fill.BorderSizePixel = 0
Fill.Parent = Slider

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = Fill

local function updateFOV(inputX)
	local relative = math.clamp(
		(inputX - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X,
		0,
		1
	)

	FOV = math.floor(50 + relative * 450)

	Fill.Size = UDim2.new(FOV / 500, 0, 1, 0)
	FOVLabel.Text = "FOV: " .. FOV
end

Slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		updateFOV(input.Position.X)
	end
end)

Slider.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			updateFOV(input.Position.X)
		end
	end
end)

--// FIND TARGET
local function getClosestTarget()
	local closestPlayer = nil
	local closestDistance = FOV

	local mousePosition = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then

			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local root = player.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and root and humanoid.Health > 0 then

				local distance =
					(Camera.CFrame.Position - root.Position).Magnitude

				if distance <= MaxDistance then

					local screenPosition, visible =
						Camera:WorldToViewportPoint(root.Position)

					if visible and screenPosition.Z > 0 then

						local screenDistance = (
							Vector2.new(screenPosition.X, screenPosition.Y)
							- mousePosition
						).Magnitude

						if screenDistance < closestDistance then
							closestDistance = screenDistance
							closestPlayer = player
						end
					end
				end
			end
		end
	end

	return closestPlayer
end

--// AIM
RunService.RenderStepped:Connect(function()

	if not AimbotEnabled then
		return
	end

	local target = getClosestTarget()

	if target and target.Character then

		local root =
			target.Character:FindFirstChild("HumanoidRootPart")

		if root then

			local cameraPosition = Camera.CFrame.Position

			local targetCFrame =
				CFrame.lookAt(cameraPosition, root.Position)

			Camera.CFrame =
				Camera.CFrame:Lerp(
					targetCFrame,
					Smoothness
				)
		end
	end
end)

--// DRAGGING
local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = false
	end
end)
```
