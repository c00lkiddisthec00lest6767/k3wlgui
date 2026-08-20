--// k3wlTSB
--// Mobile Friendly
--// Lock-On + Random + Teleport Spin Fling
--// Minimize + Reopen + Close
--// by k3wlkid

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local MAX_DISTANCE = 150

-- Fling settings
local FLING_DISTANCE_LIMIT = 100
local FLING_INTERVAL = 0.01
local SPIN_SPEED = 100

--==================================================
-- STATE
--==================================================

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

		if closed then
			break
		end

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

ScreenGui.Parent =
	LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.Size =
	UDim2.new(
		0,
		320,
		0,
		300
	)

Main.Position =
	UDim2.new(
		0.5,
		-160,
		0.5,
		-150
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		180,
		25,
		25
	)

Main.BorderSizePixel = 0

Main.Parent = ScreenGui

local MainCorner =
	Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

MainCorner.Parent = Main

--==================================================
-- HEADER
--==================================================

local Header =
	Instance.new("Frame")

Header.Name = "Header"

Header.Size =
	UDim2.new(
		1,
		0,
		0,
		55
	)

Header.BackgroundTransparency = 1

Header.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title =
	Instance.new("TextLabel")

Title.Name = "Title"

Title.Size =
	UDim2.new(
		1,
		-100,
		0,
		32
	)

Title.Position =
	UDim2.new(
		0,
		10,
		0,
		3
	)

Title.BackgroundTransparency = 1

Title.Text = "k3wlTSB"

Title.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Title.TextScaled = true

Title.Font =
	Enum.Font.GothamBold

Title.Parent = Header

--==================================================
-- SUBTITLE
--==================================================

local Subtitle =
	Instance.new("TextLabel")

Subtitle.Name = "Subtitle"

Subtitle.Size =
	UDim2.new(
		1,
		-100,
		0,
		18
	)

Subtitle.Position =
	UDim2.new(
		0,
		10,
		0,
		34
	)

Subtitle.BackgroundTransparency = 1

Subtitle.Text = "by k3wlkid"

Subtitle.TextColor3 =
	Color3.fromRGB(
		255,
		210,
		210
	)

Subtitle.TextScaled = true

Subtitle.Font =
	Enum.Font.Gotham

Subtitle.Parent = Header

--==================================================
-- MINIMIZE BUTTON
--==================================================

local MinimizeButton =
	Instance.new("TextButton")

MinimizeButton.Name =
	"MinimizeButton"

MinimizeButton.Size =
	UDim2.new(
		0,
		38,
		0,
		38
	)

MinimizeButton.Position =
	UDim2.new(
		1,
		-88,
		0,
		8
	)

MinimizeButton.BackgroundColor3 =
	Color3.fromRGB(
		120,
		15,
		15
	)

MinimizeButton.BorderSizePixel = 0

MinimizeButton.Text = "—"

MinimizeButton.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

MinimizeButton.TextSize = 24

MinimizeButton.Font =
	Enum.Font.GothamBold

MinimizeButton.ZIndex = 10

MinimizeButton.Parent = Header

local MinimizeCorner =
	Instance.new("UICorner")

MinimizeCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

MinimizeCorner.Parent =
	MinimizeButton

--==================================================
-- CLOSE BUTTON
--==================================================

local CloseButton =
	Instance.new("TextButton")

CloseButton.Name =
	"CloseButton"

CloseButton.Size =
	UDim2.new(
		0,
		38,
		0,
		38
	)

CloseButton.Position =
	UDim2.new(
		1,
		-44,
		0,
		8
	)

CloseButton.BackgroundColor3 =
	Color3.fromRGB(
		90,
		5,
		5
	)

CloseButton.BorderSizePixel = 0

CloseButton.Text = "X"

CloseButton.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

CloseButton.TextSize = 20

CloseButton.Font =
	Enum.Font.GothamBold

CloseButton.ZIndex = 10

CloseButton.Parent = Header

local CloseCorner =
	Instance.new("UICorner")

CloseCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

CloseCorner.Parent =
	CloseButton

--==================================================
-- STATUS
--==================================================

local Status =
	Instance.new("TextLabel")

Status.Name = "Status"

Status.Size =
	UDim2.new(
		1,
		-20,
		0,
		25
	)

Status.Position =
	UDim2.new(
		0,
		10,
		0,
		60
	)

Status.BackgroundTransparency = 1

Status.Text = "Status: OFF"

Status.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Status.TextScaled = true

Status.Font =
	Enum.Font.GothamBold

Status.Parent = Main

--==================================================
-- BUTTON CREATOR
--==================================================

local function createButton(
	name,
	text,
	y
)

	local Button =
		Instance.new("TextButton")

	Button.Name = name

	Button.Size =
		UDim2.new(
			1,
			-30,
			0,
			50
		)

	Button.Position =
		UDim2.new(
			0,
			15,
			0,
			y
		)

	Button.BackgroundColor3 =
		Color3.fromRGB(
			110,
			10,
			10
		)

	Button.BorderSizePixel = 0

	Button.Text = text

	Button.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

	Button.TextScaled = true

	Button.Font =
		Enum.Font.GothamBold

	Button.AutoButtonColor = true

	Button.ZIndex = 2

	Button.Parent = Main

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			8
		)

	Corner.Parent = Button

	return Button
end

--==================================================
-- BUTTONS
--==================================================

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

local ReopenButton =
	Instance.new("TextButton")

ReopenButton.Name =
	"ReopenButton"

ReopenButton.Size =
	UDim2.new(
		0,
		80,
		0,
		50
	)

ReopenButton.Position =
	UDim2.new(
		0,
		20,
		0.5,
		-25
	)

ReopenButton.BackgroundColor3 =
	Color3.fromRGB(
		180,
		25,
		25
	)

ReopenButton.BorderSizePixel = 0

ReopenButton.Text = "k3wl"

ReopenButton.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

ReopenButton.TextScaled = true

ReopenButton.Font =
	Enum.Font.GothamBold

ReopenButton.Visible = false

ReopenButton.ZIndex = 20

ReopenButton.Parent = ScreenGui

local ReopenCorner =
	Instance.new("UICorner")

ReopenCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

ReopenCorner.Parent =
	ReopenButton

--==================================================
-- GET NEAREST PLAYER
--==================================================

local function getNearestPlayer()

	local character =
		LocalPlayer.Character

	if not character then
		return nil
	end

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not root then
		return nil
	end

	local nearest = nil

	local shortestDistance =
		MAX_DISTANCE

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then

			local targetCharacter =
				player.Character

			if targetCharacter then

				local targetRoot =
					targetCharacter:
					FindFirstChild(
						"HumanoidRootPart"
					)

				local humanoid =
					targetCharacter:
					FindFirstChildOfClass(
						"Humanoid"
					)

				if targetRoot
					and humanoid
					and humanoid.Health > 0 then

					local distance =
						(
							root.Position
							- targetRoot.Position
						).Magnitude

					if distance <
						shortestDistance then

						shortestDistance =
							distance

						nearest =
							player

					end
				end
			end
		end
	end

	return nearest
end

--==================================================
-- GET RANDOM PLAYER
--==================================================

local function getRandomPlayer()

	local players = {}

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then

			local character =
				player.Character

			if character then

				local root =
					character:
					FindFirstChild(
						"HumanoidRootPart"
					)

				local humanoid =
					character:
					FindFirstChildOfClass(
						"Humanoid"
					)

				if root
					and humanoid
					and humanoid.Health > 0 then

					table.insert(
						players,
						player
					)

				end
			end
		end
	end

	if #players == 0 then
		return nil
	end

	return players[
		math.random(
			1,
			#players
		)
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

	if Status
		and Status.Parent then

		Status.Text =
			"Status: OFF"

	end
end

--==================================================
-- LOCK ON
--==================================================

local function lockOnto(
	player,
	mode
)

	if not player then

		Status.Text =
			"Status: No valid player"

		return
	end

	lockedTarget =
		player

	lockMode =
		mode

	Status.Text =
		"Locked: "
		.. player.Name

	if lockConnection then

		lockConnection:Disconnect()

	end

	lockConnection =
		RunService.RenderStepped:
		Connect(
			function()

				if closed then
					return
				end

				if not lockedTarget then
					return
				end

				local character =
					lockedTarget.Character

				if not character then

					stopLock()

					return
				end

				local root =
					character:
					FindFirstChild(
						"HumanoidRootPart"
					)

				local humanoid =
					character:
					FindFirstChildOfClass(
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
			end
		)
end

--==================================================
-- STOP FLING
--==================================================

local function stopFling()

	flingActive = false

	if flingConnection then

		flingConnection:Disconnect()

		flingConnection = nil

	end

	local character =
		LocalPlayer.Character

	if character then

		local humanoid =
			character:
			FindFirstChildOfClass(
				"Humanoid"
			)

		local root =
			character:
			FindFirstChild(
				"HumanoidRootPart"
			)

		if humanoid then

			humanoid.AutoRotate = true

		end

		if root then

			root.AssemblyAngularVelocity =
				Vector3.zero

		end
	end
end

--==================================================
-- TELEPORT SPIN FLING
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

	local character =
		LocalPlayer.Character

	if not character then
		return
	end

	local myRoot =
		character:
		FindFirstChild(
			"HumanoidRootPart"
		)

	local myHumanoid =
		character:
		FindFirstChildOfClass(
			"Humanoid"
		)

	if not myRoot
		or not myHumanoid then

		return
	end

	local targetCharacter =
		lockedTarget.Character

	if not targetCharacter then

		Status.Text =
			"Status: Target unavailable"

		return
	end

	local targetRoot =
		targetCharacter:
		FindFirstChild(
			"HumanoidRootPart"
		)

	if not targetRoot then

		Status.Text =
			"Status: Target unavailable"

		return
	end

	--==============================================
	-- SAVE ORIGINAL POSITION
	--==============================================

	local originalCFrame =
		myRoot.CFrame

	local originalPosition =
		myRoot.Position

	flingActive = true

	myHumanoid.AutoRotate =
		false

	Status.Text =
		"FLINGING: "
		.. lockedTarget.Name

	--==============================================
	-- FLING LOOP
	--==============================================

	flingConnection =
		RunService.RenderStepped:
		Connect(
			function()

				if not flingActive then
					return
				end

				if closed then

					stopFling()

					return
				end

				if not myRoot
					or not myRoot.Parent then

					stopFling()

					return
				end

				if not lockedTarget
					or not lockedTarget.Character then

					stopFling()

					if myRoot.Parent then
						myRoot.CFrame =
							originalCFrame
					end

					return
				end

				local newTargetRoot =
					lockedTarget.Character:
					FindFirstChild(
						"HumanoidRootPart"
					)

				if not newTargetRoot then

					stopFling()

					myRoot.CFrame =
						originalCFrame

					return
				end

				--==================================
				-- DISTANCE CHECK
				--==================================

				local distanceFromStart =
					(
						myRoot.Position
						- originalPosition
					).Magnitude

				if distanceFromStart >
					FLING_DISTANCE_LIMIT then

					stopFling()

					-- Return to EXACT
					-- starting position
					myRoot.CFrame =
						originalCFrame

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

				--==================================
				-- TELEPORT TO TARGET
				--==================================

				local targetPosition =
					newTargetRoot.Position

				myRoot.CFrame =
					CFrame.new(
						targetPosition
						+ Vector3.new(
							math.random(
								-3,
								3
							),
							math.random(
								-2,
								3
							),
							math.random(
								-3,
								3
							)
						)
					)

				--==================================
				-- CRAZY SPIN
				--==================================

				myRoot.AssemblyAngularVelocity =
					Vector3.new(
						SPIN_SPEED,
						SPIN_SPEED * 1.5,
						SPIN_SPEED
					)

				-- Keep the loop extremely fast
				task.wait(
					FLING_INTERVAL
				)
			end
		)
end

--==================================================
-- NEAREST BUTTON
--==================================================

NearestButton.Activated:
	Connect(
		function()

			if lockMode ==
				"Nearest" then

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
		end
	)

--==================================================
-- RANDOM BUTTON
--==================================================

RandomButton.Activated:
	Connect(
		function()

			if lockMode ==
				"Random" then

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
		end
	)

--==================================================
-- FLING BUTTON
--==================================================

FlingButton.Activated:
	Connect(
		function()

			if flingActive then

				stopFling()

				Status.Text =
					"Fling stopped"

				return
			end

			flingTarget()

		end
	)

--==================================================
-- MINIMIZE
--==================================================

MinimizeButton.Activated:
	Connect(
		function()

			if closed then
				return
			end

			Main.Visible =
				false

			ReopenButton.Visible =
				true

		end
	)

--==================================================
-- REOPEN
--==================================================

ReopenButton.Activated:
	Connect(
		function()

			if closed then
				return
			end

			Main.Visible =
				true

			ReopenButton.Visible =
				false

		end
	)

--==================================================
-- FULL CLOSE
--==================================================

CloseButton.Activated:
	Connect(
		function()

			if closed then
				return
			end

			closed = true

			-- Stop fling
			stopFling()

			-- Stop lock-on
			stopLock()

			-- Destroy entire UI
			ScreenGui:Destroy()

		end
	)

--==================================================
-- DRAGGING
--==================================================

local function makeDraggable(
	object
)

	local dragging = false

	local dragStart

	local startPosition

	object.InputBegan:
		Connect(
			function(input)

				if input.UserInputType ==
					Enum.UserInputType.MouseButton1
					or input.UserInputType ==
					Enum.UserInputType.Touch then

					dragging =
						true

					dragStart =
						input.Position

					startPosition =
						object.Position

					input.Changed:
						Connect(
							function()

								if input.UserInputState ==
									Enum.UserInputState.End then

									dragging =
										false

								end
							end
						)
				end
			end
		)

	UserInputService.InputChanged:
		Connect(
			function(input)

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
			end
		)
end

-- Make both windows draggable
makeDraggable(Main)

makeDraggable(ReopenButton)
