--// k3wlTSB Lock-On UI
--// Mobile Friendly
--// Made for Roblox Studio

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--// SETTINGS
local MAX_DISTANCE = 150

local lockedTarget = nil
local lockMode = nil
local lockConnection = nil

--// ROBLOX NOTIFICATION
pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "k3wlTSB",
		Text = "This little script was made for my team, ty for using :D",
		Duration = 5
	})
end)

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "k3wlTSB"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 230)
Main.Position = UDim2.new(0.5, -150, 0.5, -115)
Main.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

--// TITLE
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 45)
Title.Position = UDim2.new(0, 10, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "k3wlTSB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--// SUBTITLE
local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, -20, 0, 25)
Subtitle.Position = UDim2.new(0, 10, 0, 48)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "by k3wlkid"
Subtitle.TextColor3 = Color3.fromRGB(255, 210, 210)
Subtitle.TextScaled = true
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = Main

--// STATUS
local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.new(0, 10, 0, 73)
Status.BackgroundTransparency = 1
Status.Text = "Status: OFF"
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.TextScaled = true
Status.Font = Enum.Font.GothamBold
Status.Parent = Main

--// BUTTON CREATOR
local function createButton(name, text, position)
	local Button = Instance.new("TextButton")
	Button.Name = name
	Button.Size = UDim2.new(1, -30, 0, 50)
	Button.Position = position
	Button.BackgroundColor3 = Color3.fromRGB(110, 10, 10)
	Button.BorderSizePixel = 0
	Button.Text = text
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextScaled = true
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = true
	Button.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button

	return Button
end

--// BUTTONS
local NearestButton = createButton(
	"NearestLock",
	"LOCKON — Nearest Player",
	UDim2.new(0, 15, 0, 105)
)

local RandomButton = createButton(
	"RandomLock",
	"RANDOM — Random Player",
	UDim2.new(0, 15, 0, 160)
)

--// FIND NEAREST PLAYER
local function getNearestPlayer()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local nearest = nil
	local shortestDistance = MAX_DISTANCE

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character
			if targetCharacter then
				local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
				local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

				if targetRoot and humanoid and humanoid.Health > 0 then
					local distance = (root.Position - targetRoot.Position).Magnitude

					if distance < shortestDistance then
						shortestDistance = distance
						nearest = player
					end
				end
			end
		end
	end

	return nearest
end

--// GET RANDOM PLAYER
local function getRandomPlayer()
	local availablePlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local character = player.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if root and humanoid and humanoid.Health > 0 then
					table.insert(availablePlayers, player)
				end
			end
		end
	end

	if #availablePlayers == 0 then
		return nil
	end

	return availablePlayers[math.random(1, #availablePlayers)]
end

--// START LOCK
local function lockOnto(player, mode)
	if not player then
		Status.Text = "Status: No valid player"
		lockedTarget = nil
		lockMode = nil
		return
	end

	lockedTarget = player
	lockMode = mode

	Status.Text = "Locked: " .. player.Name

	if lockConnection then
		lockConnection:Disconnect()
	end

	-- Continuously update the target's HumanoidRootPart
	lockConnection = game:GetService("RunService").RenderStepped:Connect(function()
		if not lockedTarget then
			return
		end

		local targetCharacter = lockedTarget.Character
		if not targetCharacter then
			return
		end

		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

		if not targetRoot or not humanoid or humanoid.Health <= 0 then
			lockedTarget = nil
			lockMode = nil
			Status.Text = "Status: Target unavailable"

			if lockConnection then
				lockConnection:Disconnect()
				lockConnection = nil
			end

			return
		end

		-- Lock-on target is specifically the HumanoidRootPart.
		-- Camera faces the target's HumanoidRootPart.
		local camera = workspace.CurrentCamera
		local cameraPosition = camera.CFrame.Position

		camera.CFrame = CFrame.lookAt(
			cameraPosition,
			targetRoot.Position
		)
	end)
end

--// NEAREST BUTTON
NearestButton.Activated:Connect(function()
	if lockMode == "Nearest" then
		lockedTarget = nil
		lockMode = nil

		if lockConnection then
			lockConnection:Disconnect()
			lockConnection = nil
		end

		Status.Text = "Status: OFF"
		return
	end

	local target = getNearestPlayer()

	if target then
		lockOnto(target, "Nearest")
	else
		Status.Text = "Status: No nearby player"
	end
end)

--// RANDOM BUTTON
RandomButton.Activated:Connect(function()
	if lockMode == "Random" then
		lockedTarget = nil
		lockMode = nil

		if lockConnection then
			lockConnection:Disconnect()
			lockConnection = nil
		end

		Status.Text = "Status: OFF"
		return
	end

	local target = getRandomPlayer()

	if target then
		lockOnto(target, "Random")
	else
		Status.Text = "Status: No other players"
	end
end)

--// MAKE UI DRAGGABLE ON MOBILE + PC
local UserInputService = game:GetService("UserInputService")

local dragging = false
local dragStart
local startPosition

Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position

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

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)
