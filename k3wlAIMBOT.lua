-- k3wlAIMBOT
-- LocalScript - put in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Settings
local FOV_RADIUS = 150
local AIM_ENABLED = true
local AIM_SMOOTHNESS = 0.15

--==================================================
-- UI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "k3wlAIMBOT"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local background = Instance.new("Frame")
background.Size = UDim2.fromOffset(220, 70)
background.Position = UDim2.fromOffset(20, 20)
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

--==================================================
-- FOV Circle
--==================================================

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

--==================================================
-- Team Check
--==================================================

local function isEnemy(player)
	if player == LocalPlayer then
		return false
	end

	-- If both players have teams, don't target teammates.
	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		if LocalPlayer.Team == player.Team then
			return false
		end
	end

	return true
end

--==================================================
-- Find Closest HRP Inside FOV
--==================================================

local function getNearestTarget(camera)
	local closestRoot = nil
	local closestDistance = FOV_RADIUS

	local viewportSize = camera.ViewportSize

	local screenCenter = Vector2.new(
		viewportSize.X * 0.5,
		viewportSize.Y * 0.5
	)

	for _, player in ipairs(Players:GetPlayers()) do

		if isEnemy(player) then

			local character = player.Character

			if character then

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")

				if humanoid
					and humanoid.Health > 0
					and root
					and root:IsDescendantOf(workspace)
				then

					local screenPosition, onScreen =
						camera:WorldToViewportPoint(root.Position)

					if onScreen and screenPosition.Z > 0 then

						local targetPosition = Vector2.new(
							screenPosition.X,
							screenPosition.Y
						)

						local distance =
							(targetPosition - screenCenter).Magnitude

						if distance <= closestDistance then
							closestDistance = distance
							closestRoot = root
						end
					end
				end
			end
		end
	end

	return closestRoot
end

--==================================================
-- Main
--==================================================

RunService:BindToRenderStep(
	"k3wlAIMBOT",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		-- Keep FOV circle centered on the actual viewport.
		fov.Position = UDim2.fromOffset(
			camera.ViewportSize.X * 0.5,
			camera.ViewportSize.Y * 0.5
		)

		if not AIM_ENABLED then
			return
		end

		local target = getNearestTarget(camera)

		if target then
			local cameraPosition = camera.CFrame.Position

			local targetCFrame = CFrame.lookAt(
				cameraPosition,
				target.Position
			)

			camera.CFrame = camera.CFrame:Lerp(
				targetCFrame,
				AIM_SMOOTHNESS
			)
		end
	end
)

--==================================================
-- Toggle
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		AIM_ENABLED = not AIM_ENABLED

		status.Text = AIM_ENABLED
			and "AIM: ON"
			or "AIM: OFF"

		stroke.Color = AIM_ENABLED
			and Color3.fromRGB(255, 50, 50)
			or Color3.fromRGB(100, 100, 100)
	end
end)
