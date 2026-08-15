-- Mobile FOV Aim Assist
-- Put in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SETTINGS = {
	Enabled = true,
	FOV = 150,
	Smoothness = 0.15,
	MaxDistance = 500,
	AimPart = "Head"
}

-- Mobile UI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- FOV circle
local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.Size = UDim2.fromOffset(SETTINGS.FOV * 2, SETTINGS.FOV * 2)
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.Position = UDim2.fromScale(0.5, 0.5)
fov.BackgroundTransparency = 1
fov.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = fov

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2
stroke.Transparency = 0.25
stroke.Parent = fov

-- Aim button
local button = Instance.new("TextButton")
button.Name = "AimButton"
button.Size = UDim2.fromOffset(90, 90)
button.Position = UDim2.new(1, -115, 1, -140)
button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
button.BackgroundTransparency = 0.15
button.Text = "AIM"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Parent = gui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(1, 0)
buttonCorner.Parent = button

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(255, 255, 255)
buttonStroke.Thickness = 2
buttonStroke.Parent = button

local aiming = false

button.Activated:Connect(function()
	aiming = not aiming

	if aiming then
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
	else
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	end
end)

local function getClosestTarget()
	local center = camera.ViewportSize / 2
	local closestTarget = nil
	local closestDistance = SETTINGS.FOV

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			local character = targetPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local targetPart = character and character:FindFirstChild(SETTINGS.AimPart)

			if humanoid and humanoid.Health > 0 and targetPart then
				local screenPos, visible =
					camera:WorldToViewportPoint(targetPart.Position)

				if visible then
					local screenDistance =
						(Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

					local worldDistance =
						(camera.CFrame.Position - targetPart.Position).Magnitude

					if screenDistance < closestDistance
						and worldDistance <= SETTINGS.MaxDistance then

						closestDistance = screenDistance
						closestTarget = targetPart
					end
				end
			end
		end
	end

	return closestTarget
end

RunService.RenderStepped:Connect(function()
	if not SETTINGS.Enabled or not aiming then
		return
	end

	local target = getClosestTarget()

	if target then
		local desired =
			CFrame.lookAt(camera.CFrame.Position, target.Position)

		camera.CFrame =
			camera.CFrame:Lerp(desired, SETTINGS.Smoothness)
	end
end)
