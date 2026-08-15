-- k3wlAIMBOT
-- For use in your own Roblox experience.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local FOV_RADIUS = 150
local AIM_ENABLED = true

--// UI
local gui = Instance.new("ScreenGui")
gui.Name = "k3wlAIMBOT"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Size = UDim2.fromOffset(220, 70)
background.Position = UDim2.new(0, 20, 0, 20)
background.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
background.BorderSizePixel = 0
background.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = background

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.55, 0)
title.BackgroundTransparency = 1
title.Text = "k3wlAIMBOT"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = background

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 0, 0.55, 0)
status.Size = UDim2.new(1, 0, 0.45, 0)
status.BackgroundTransparency = 1
status.Text = "AIM: ON"
status.TextColor3 = Color3.fromRGB(255, 220, 220)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = background

--// FOV circle
local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.BackgroundTransparency = 1
fov.BorderSizePixel = 0
fov.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fov

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 50, 50)
stroke.Thickness = 2
stroke.Transparency = 0.15
stroke.Parent = fov

--// Notification
task.spawn(function()
	StarterGui:SetCore("SendNotification", {
		Title = "k3wlAIMBOT",
		Text = "simple aimbot by k3wlkid, hope you like it.",
		Duration = 6
	})
end)

--// Team check
local function isEnemy(player)
	if player == LocalPlayer then
		return false
	end

	-- Don't target teammates.
	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		if LocalPlayer.Team == player.Team then
			return false
		end
	end

	return true
end

--// Find nearest enemy HumanoidRootPart inside FOV
local function getNearestTarget()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	local nearestRoot = nil
	local nearestDistance = FOV_RADIUS

	local mousePosition = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do
		if isEnemy(player) then
			local targetCharacter = player.Character

			if targetCharacter then
				local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
				local root = targetCharacter:FindFirstChild("HumanoidRootPart")

				if humanoid and root and humanoid.Health > 0 then
					local screenPosition, visible =
						Camera:WorldToViewportPoint(root.Position)

					if visible and screenPosition.Z > 0 then
						local distance = (
							Vector2.new(screenPosition.X, screenPosition.Y)
							- mousePosition
						).Magnitude

						if distance < nearestDistance then
							nearestDistance = distance
							nearestRoot = root
						end
					end
				end
			end
		end
	end

	return nearestRoot
end

--// Aim
RunService.RenderStepped:Connect(function()
	local viewport = Camera.ViewportSize

	fov.Position = UDim2.fromOffset(
		viewport.X / 2,
		viewport.Y / 2
	)

	if not AIM_ENABLED then
		return
	end

	local target = getNearestTarget()

	if target then
		-- Smoothly point the camera at the target.
		local cameraPosition = Camera.CFrame.Position
		local targetCFrame = CFrame.lookAt(
			cameraPosition,
			target.Position
		)

		Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.15)
	end
end)

--// Toggle with RightShift
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		AIM_ENABLED = not AIM_ENABLED
		status.Text = AIM_ENABLED and "AIM: ON" or "AIM: OFF"
		stroke.Color = AIM_ENABLED
			and Color3.fromRGB(255, 50, 50)
			or Color3.fromRGB(100, 100, 100)
	end
end)
