-- k3wlAIMBOT Mobile UI
-- LocalScript → StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local AIMBOT_ENABLED = false
local FOV_RADIUS = 150
local AIM_SMOOTHNESS = 0.18

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "k3wlAIMBOT"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(190, 105)
main.Position = UDim2.new(1, -205, 1, -125)
main.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 38)
title.BackgroundTransparency = 1
title.Text = "k3wlAIMBOT"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.Parent = main

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 45)
toggle.Position = UDim2.fromOffset(10, 48)
toggle.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
toggle.Text = "AIMBOT: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 17
toggle.Font = Enum.Font.GothamBold
toggle.AutoButtonColor = true
toggle.Parent = main

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 9)
toggleCorner.Parent = toggle

-- FOV circle
local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.Position = UDim2.fromScale(0.5, 0.5)
fov.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
fov.BackgroundTransparency = 1
fov.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fov

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 2
stroke.Transparency = 0.25
stroke.Parent = fov

-- Mobile toggle
toggle.Activated:Connect(function()
	AIMBOT_ENABLED = not AIMBOT_ENABLED

	if AIMBOT_ENABLED then
		toggle.Text = "AIMBOT: ON"
		toggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	else
		toggle.Text = "AIMBOT: OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	end
end)

-- Find nearest HumanoidRootPart
local function getNearestTarget()
	local screenCenter = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local nearestRoot = nil
	local nearestDistance = FOV_RADIUS

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			local character = targetPlayer.Character

			if character then
				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				local root =
					character:FindFirstChild("HumanoidRootPart")

				if humanoid and root and humanoid.Health > 0 then
					local screenPos, visible =
						camera:WorldToViewportPoint(root.Position)

					if visible and screenPos.Z > 0 then
						local distance = (
							Vector2.new(screenPos.X, screenPos.Y)
							- screenCenter
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

-- Aim
RunService.RenderStepped:Connect(function()
	if not AIMBOT_ENABLED then
		return
	end

	local targetRoot = getNearestTarget()

	if targetRoot then
		local desiredCFrame = CFrame.lookAt(
			camera.CFrame.Position,
			targetRoot.Position
		)

		camera.CFrame = camera.CFrame:Lerp(
			desiredCFrame,
			AIM_SMOOTHNESS
		)
	end
end)
