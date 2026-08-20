-- k3wlTSB — COMPLETE GITHUB VERSION
-- by k3wlkid
-- Mobile friendly
-- LOCKON = nearest player
-- RANDOM = random player
-- FLING = aggressive client-side orbit/spin
-- — = minimize
-- X = completely close
-- k3wl = reopen

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 150
local MAX_FLING_HEIGHT = 150
local ORBIT_RADIUS = 5
local VERTICAL_OFFSET = 2
local TELEPORT_VARIATION = 6
local SPIN_SPEED = 250
local LINEAR_SPEED = 250

local lockedTarget = nil
local lockMode = nil
local lockConnection = nil
local flingConnection = nil
local flingActive = false
local closed = false

--==================================================
-- NOTIFICATION
--==================================================

task.spawn(function()
	task.wait(1)

	for i = 1, 15 do
		local success = pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "k3wlTSB",
				Text = "This little script was made for my team, ty for using :D",
				Duration = 5
			})
		end)

		if success then
			break
		end

		task.wait(0.5)
	end
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "k3wlTSB"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 300)
Main.Position = UDim2.new(0.5, -160, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 32)
Title.Position = UDim2.new(0, 10, 0, 3)
Title.BackgroundTransparency = 1
Title.Text = "k3wlTSB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -100, 0, 18)
Subtitle.Position = UDim2.new(0, 10, 0, 34)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "by k3wlkid"
Subtitle.TextColor3 = Color3.fromRGB(255, 210, 210)
Subtitle.TextScaled = true
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = Header

--==================================================
-- MINIMIZE
--==================================================

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 38, 0, 38)
MinimizeButton.Position = UDim2.new(1, -88, 0, 8)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(120, 15, 15)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.TextSize = 24
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.ZIndex = 10
MinimizeButton.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeButton

--==================================================
-- CLOSE
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 38, 0, 38)
CloseButton.Position = UDim2.new(1, -44, 0, 8)
CloseButton.BackgroundColor3 = Color3.fromRGB(90, 5, 5)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.ZIndex = 10
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.new(0, 10, 0, 60)
Status.BackgroundTransparency = 1
Status.Text = "Status: OFF"
Status.TextColor3 = Color3.new(1, 1, 1)
Status.TextScaled = true
Status.Font = Enum.Font.GothamBold
Status.Parent = Main

--==================================================
-- BUTTON CREATOR
--==================================================

local function createButton(name, text, y)

	local button = Instance.new("TextButton")

	button.Name = name
	button.Size = UDim2.new(1, -30, 0, 50)
	button.Position = UDim2.new(0, 15, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(110, 10, 10)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = Main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local NearestButton =
	createButton(
		"NearestButton",
		"LOCKON — Nearest Player",
		95
	)

local RandomButton =
	createButton(
		"RandomButton",
		"RANDOM — Random Player",
		150
	)

local FlingButton =
	createButton(
		"FlingButton",
		"FLING — Locked Player",
		205
	)

--==================================================
-- REOPEN BUTTON
--==================================================

local ReopenButton = Instance.new("TextButton")
ReopenButton.Size = UDim2.new(0, 80, 0, 50)
ReopenButton.Position = UDim2.new(0, 20, 0.5, -25)
ReopenButton.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
ReopenButton.BorderSizePixel = 0
ReopenButton.Text = "k3wl"
ReopenButton.TextColor3 = Color3.new(1, 1, 1)
ReopenButton.TextScaled = true
ReopenButton.Font = Enum.Font.GothamBold
ReopenButton.Visible = false
ReopenButton.ZIndex = 20
ReopenButton.Parent = ScreenGui

local ReopenCorner = Instance.new("UICorner")
ReopenCorner.CornerRadius = UDim.new(0, 12)
ReopenCorner.Parent = ReopenButton

--==================================================
-- TARGET FUNCTIONS
--==================================================

local function getNearestPlayer()

	local character = LocalPlayer.Character
	if not character then return nil end

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not root then return nil end

	local nearest = nil
	local shortest = MAX_DISTANCE

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then

			local char = player.Character

			if char then

				local targetRoot =
					char:FindFirstChild("HumanoidRootPart")

				local humanoid =
					char:FindFirstChildOfClass("Humanoid")

				if targetRoot
					and humanoid
					and humanoid.Health > 0 then

					local distance =
						(root.Position - targetRoot.Position).Magnitude

					if distance < shortest then

						shortest = distance
						nearest = player

					end
				end
			end
		end
	end

	return nearest
end

local function getRandomPlayer()

	local available = {}

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then

			local char = player.Character

			if char then

				local root =
					char:FindFirstChild("HumanoidRootPart")

				local humanoid =
					char:FindFirstChildOfClass("Humanoid")

				if root
					and humanoid
					and humanoid.Health > 0 then

					table.insert(
						available,
						player
					)

				end
			end
		end
	end

	if #available == 0 then
		return nil
	end

	return available[
		math.random(1, #available)
	]
end

--==================================================
-- STOP LOCK
--==================================================

local function stopLock()

	lockedTarget = nil
	lockMode = nil

	if lockConnection then
		lockConnection:Disconnect()
		lockConnection = nil
	end

	Status.Text = "Status: OFF"
end

--==================================================
-- LOCK
--==================================================

local function lockOnto(player, mode)

	if not player then

		Status.Text =
			"Status: No valid player"

		return
	end

	lockedTarget = player
	lockMode = mode

	Status.Text =
		"Locked: " .. player.Name

	if lockConnection then
		lockConnection:Disconnect()
	end

	lockConnection =
		RunService.RenderStepped:Connect(function()

			if closed or not lockedTarget then
				return
			end

			local char =
				lockedTarget.Character

			if not char then
				stopLock()
				return
			end

			local root =
				char:FindFirstChild(
					"HumanoidRootPart"
				)

			local humanoid =
				char:FindFirstChildOfClass(
					"Humanoid"
				)

			if not root
				or not humanoid
				or humanoid.Health <= 0 then

				stopLock()
				return
			end

			local camera =
				workspace.CurrentCamera

			if camera then

				camera.CFrame =
					CFrame.lookAt(
						camera.CFrame.Position,
						root.Position
					)

			end
		end)
end

--==================================================
-- STOP FLING
--==================================================

local function stopFling(originalCFrame)

	flingActive = false

	if flingConnection then
		flingConnection:Disconnect()
		flingConnection = nil
	end

	local char = LocalPlayer.Character

	if not char then
		return
	end

	local humanoid =
		char:FindFirstChildOfClass("Humanoid")

	local root =
		char:FindFirstChild(
			"HumanoidRootPart"
		)

	if humanoid then
		humanoid.AutoRotate = true
	end

	if root then

		root.AssemblyAngularVelocity =
			Vector3.zero

		root.AssemblyLinearVelocity =
			Vector3.zero

		if originalCFrame then
			root.CFrame = originalCFrame
		end
	end
end

--==================================================
-- CLIENT FLING
--==================================================

local function flingTarget()

	if flingActive then
		return
	end

	if not lockedTarget then

		Status.Text =
			"Status: Lock onto someone first!"

		return
	end

	local char =
		LocalPlayer.Character

	if not char then
		return
	end

	local root =
		char:FindFirstChild(
			"HumanoidRootPart"
		)

	local humanoid =
		char:FindFirstChildOfClass(
			"Humanoid"
		)

	if not root or not humanoid then
		return
	end

	local targetChar =
		lockedTarget.Character

	if not targetChar then

		Status.Text =
			"Status: Target unavailable"

		return
	end

	local targetRoot =
		targetChar:FindFirstChild(
			"HumanoidRootPart"
		)

	if not targetRoot then

		Status.Text =
			"Status: Target unavailable"

		return
	end

	-- Save starting location
	local originalCFrame =
		root.CFrame

	local originalY =
		root.Position.Y

	flingActive = true

	humanoid.AutoRotate = false

	Status.Text =
		"FLINGING: "
		.. lockedTarget.Name

	local startTime = os.clock()

	flingConnection =
		RunService.RenderStepped:Connect(
			function()

				if not flingActive then
					return
				end

				if closed then

					stopFling(
						originalCFrame
					)

					return
				end

				if not root
					or not root.Parent then

					stopFling(
						originalCFrame
					)

					return
				end

				if not lockedTarget
					or not lockedTarget.Character then

					stopFling(
						originalCFrame
					)

					return
				end

				local currentTargetRoot =
					lockedTarget.Character:
					FindFirstChild(
						"HumanoidRootPart"
					)

				if not currentTargetRoot then

					stopFling(
						originalCFrame
					)

					return
				end

				-- ONLY automatic stop:
				-- player gets too high
				if root.Position.Y >
					originalY
					+ MAX_FLING_HEIGHT then

					stopFling(
						originalCFrame
					)

					Status.Text =
						"Fling finished!"

					task.delay(
						1,
						function()

							if Status
								and Status.Parent
								and lockedTarget then

								Status.Text =
									"Locked: "
									.. lockedTarget.Name

							end
						end
					)

					return
				end

				--======================================
				-- RAPID MOVEMENT AROUND TARGET
				--======================================

				local elapsed =
					os.clock()
					- startTime

				local angle =
					elapsed
					* SPIN_SPEED

				local radius =
					ORBIT_RADIUS
					+ math.sin(
						elapsed * 35
					)
					* TELEPORT_VARIATION

				local offset =
					Vector3.new(

						math.cos(angle)
						* radius,

						VERTICAL_OFFSET
						+ math.sin(
							angle * 3
						)
						* TELEPORT_VARIATION,

						math.sin(angle)
						* radius
					)

				local position =
					currentTargetRoot.Position
					+ offset

				root.CFrame =
					CFrame.new(position)
					* CFrame.Angles(
						angle,
						angle * 1.7,
						angle * 2.4
					)

				root.AssemblyAngularVelocity =
					Vector3.new(
						SPIN_SPEED,
						SPIN_SPEED * 2,
						SPIN_SPEED * 1.5
					)

				root.AssemblyLinearVelocity =
					(
						currentTargetRoot.Position
						- root.Position
					).Unit
					* LINEAR_SPEED

			end
		)
end

--==================================================
-- BUTTONS
--==================================================

NearestButton.Activated:Connect(function()

	if lockMode == "Nearest" then

		stopLock()

		return
	end

	local target =
		getNearestPlayer()

	if target then

		lockOnto(
			target,
			"Nearest"
		)

	else

		Status.Text =
			"Status: No nearby player"

	end
end)

RandomButton.Activated:Connect(function()

	if lockMode == "Random" then

		stopLock()

		return
	end

	local target =
		getRandomPlayer()

	if target then

		lockOnto(
			target,
			"Random"
		)

	else

		Status.Text =
			"Status: No other players"

	end
end)

FlingButton.Activated:Connect(function()

	if flingActive then

		stopFling()

		Status.Text =
			"Fling stopped"

		return
	end

	flingTarget()
end)

--==================================================
-- MINIMIZE / REOPEN
--==================================================

MinimizeButton.Activated:Connect(function()

	if closed then
		return
	end

	Main.Visible = false
	ReopenButton.Visible = true
end)

ReopenButton.Activated:Connect(function()

	if closed then
		return
	end

	Main.Visible = true
	ReopenButton.Visible = false
end)

--==================================================
-- CLOSE
--==================================================

CloseButton.Activated:Connect(function()

	if closed then
		return
	end

	closed = true

	stopFling()
	stopLock()

	ScreenGui:Destroy()
end)

--==================================================
-- DRAGGING
--==================================================

local function makeDraggable(object)

	local dragging = false
	local dragStart
	local startPosition

	object.InputBegan:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = object.Position

			input.Changed:Connect(function()

				if input.UserInputState ==
					Enum.UserInputState.End then

					dragging = false

				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)

		if not dragging then
			return
		end

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			local delta =
				input.Position
				- dragStart

			object.Position =
				UDim2.new(
					startPosition.X.Scale,
					startPosition.X.Offset
						+ delta.X,

					startPosition.Y.Scale,
					startPosition.Y.Offset
						+ delta.Y
				)
		end
	end)
end

makeDraggable(Main)
makeDraggable(ReopenButton)
