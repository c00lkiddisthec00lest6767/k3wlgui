--// k3wlAIMBOT - For your own Roblox experience
--// Mobile + PC friendly

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// SETTINGS
local AIMBOT_ENABLED = false
local FOV_RADIUS = 150
local AIM_SMOOTHNESS = 0.18
local TEAM_CHECK = true

--//==================================================
--// UI
--//==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "k3wlAIMBOT"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main red background
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(190, 90)
Main.Position = UDim2.new(0, 15, 0.5, -45)
Main.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "k3wlAIMBOT"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

-- Toggle button
local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Size = UDim2.new(1, -20, 0, 38)
Toggle.Position = UDim2.new(0, 10, 0, 42)
Toggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Text = "AIMBOT: OFF"
Toggle.TextScaled = true
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = true
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

--//==================================================
--// FOV CIRCLE
--//==================================================

local FOV = Instance.new("Frame")
FOV.Name = "FOV"
FOV.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
FOV.AnchorPoint = Vector2.new(0.5, 0.5)
FOV.Position = UDim2.fromScale(0.5, 0.5)
FOV.BackgroundTransparency = 1
FOV.BorderSizePixel = 0
FOV.Visible = false
FOV.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 0, 0)
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.15
FOVStroke.Parent = FOV

--//==================================================
--// STARTUP NOTIFICATION
--//==================================================

task.spawn(function()
	for _ = 1, 5 do
		local success = pcall(function()
			StarterGui:SetCore(
				"SendNotification",
				{
					Title = "k3wlAIMBOT",
					Text = "a simple aimbot by k3wlkid ty for using >3",
					Duration = 5
				}
			)
		end)

		if success then
			break
		end

		task.wait(1)
	end
end)

--//==================================================
--// TEAM CHECK
--//==================================================

local function IsTeammate(player)
	if not TEAM_CHECK then
		return false
	end

	if not LocalPlayer.Team or not player.Team then
		return false
	end

	return LocalPlayer.Team == player.Team
end

--//==================================================
--// VALID TARGET
--//==================================================

local function GetHRP(player)
	if not player or player == LocalPlayer then
		return nil
	end

	if IsTeammate(player) then
		return nil
	end

	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return nil
	end

	if humanoid.Health <= 0 then
		return nil
	end

	return hrp
end

--//==================================================
--// FIND NEAREST HRP IN FOV
--//==================================================

local function GetNearestTarget()
	local viewportSize = Camera.ViewportSize
	local screenCenter = Vector2.new(
		viewportSize.X / 2,
		viewportSize.Y / 2
	)

	local closestHRP = nil
	local closestDistance = FOV_RADIUS

	for _, player in ipairs(Players:GetPlayers()) do
		local hrp = GetHRP(player)

		if hrp then
			local screenPosition, visible =
				Camera:WorldToViewportPoint(hrp.Position)

			if visible and screenPosition.Z > 0 then
				local targetPosition = Vector2.new(
					screenPosition.X,
					screenPosition.Y
				)

				local distance =
					(targetPosition - screenCenter).Magnitude

				if distance < closestDistance then
					closestDistance = distance
					closestHRP = hrp
				end
			end
		end
	end

	return closestHRP
end

--//==================================================
--// TOGGLE
--//==================================================

local function UpdateButton()
	if AIMBOT_ENABLED then
		Toggle.Text = "AIMBOT: ON"
		Toggle.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
		FOV.Visible = true
	else
		Toggle.Text = "AIMBOT: OFF"
		Toggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
		FOV.Visible = false
	end
end

Toggle.Activated:Connect(function()
	AIMBOT_ENABLED = not AIMBOT_ENABLED
	UpdateButton()
end)

UpdateButton()

--//==================================================
--// AIM LOOP
--//==================================================

RunService:BindToRenderStep(
	"k3wlAIMBOT",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if not AIMBOT_ENABLED then
			return
		end

		local target = GetNearestTarget()

		if not target then
			return
		end

		-- Smoothly rotate camera toward target HRP
		local cameraPosition = Camera.CFrame.Position

		local targetCFrame = CFrame.lookAt(
			cameraPosition,
			target.Position
		)

		Camera.CFrame = Camera.CFrame:Lerp(
			targetCFrame,
			AIM_SMOOTHNESS
		)
	end
)
