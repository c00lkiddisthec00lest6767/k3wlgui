--==================================================
-- k3wlEGG
-- by k3wlkid
-- Roblox Studio LocalScript
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local STEAL_NAME = "Steal"
local HATCH_NAME = "Hatch"

local running = false
local hatchBusy = false

local savedCFrame = nil
local interruptedCFrame = nil

local currentLoop = 0
local totalLoops = 1

--==================================================
-- CHARACTER
--==================================================

local function getRoot()
	local character = player.Character

	if not character then
		character = player.CharacterAdded:Wait()
	end

	return character:WaitForChild("HumanoidRootPart")
end

--==================================================
-- UI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "k3wlEGG"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(360, 315)
frame.Position = UDim2.new(0.5, -180, 0.5, -157)
frame.BackgroundColor3 = Color3.fromRGB(190, 0, 0)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(10, 8)
title.Size = UDim2.new(1, -20, 0, 45)
title.BackgroundTransparency = 1
title.Text = "k3wlEGG"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.fromOffset(10, 48)
subtitle.Size = UDim2.new(1, -20, 0, 25)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Steal + Hatch Automation"
subtitle.TextColor3 = Color3.fromRGB(255, 220, 220)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = frame

--==================================================
-- LOOP LABEL
--==================================================

local loopLabel = Instance.new("TextLabel")
loopLabel.Position = UDim2.fromOffset(20, 82)
loopLabel.Size = UDim2.fromOffset(65, 35)
loopLabel.BackgroundTransparency = 1
loopLabel.Text = "Loops:"
loopLabel.TextColor3 = Color3.new(1, 1, 1)
loopLabel.TextScaled = true
loopLabel.Font = Enum.Font.GothamBold
loopLabel.Parent = frame

--==================================================
-- LOOP BOX
--==================================================

local loopBox = Instance.new("TextBox")
loopBox.Position = UDim2.fromOffset(90, 82)
loopBox.Size = UDim2.fromOffset(95, 35)
loopBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loopBox.TextColor3 = Color3.fromRGB(25, 25, 25)
loopBox.PlaceholderText = "Loops"
loopBox.Text = "1"
loopBox.TextScaled = true
loopBox.Font = Enum.Font.GothamBold
loopBox.ClearTextOnFocus = false
loopBox.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 7)
boxCorner.Parent = loopBox

--==================================================
-- INFINITE TEXT
--==================================================

local infiniteText = Instance.new("TextLabel")
infiniteText.Position = UDim2.fromOffset(193, 82)
infiniteText.Size = UDim2.fromOffset(145, 35)
infiniteText.BackgroundTransparency = 1
infiniteText.Text = "0 times = infinite"
infiniteText.TextColor3 = Color3.fromRGB(255, 235, 235)
infiniteText.TextScaled = true
infiniteText.Font = Enum.Font.GothamBold
infiniteText.Parent = frame

--==================================================
-- STATUS
--==================================================

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(15, 120)
status.Size = UDim2.new(1, -30, 0, 38)
status.BackgroundTransparency = 1
status.Text = "Status: Ready"
status.TextColor3 = Color3.fromRGB(255, 240, 240)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

--==================================================
-- START
--==================================================

local startButton = Instance.new("TextButton")
startButton.Position = UDim2.fromOffset(30, 162)
startButton.Size = UDim2.new(1, -60, 0, 48)
startButton.BackgroundColor3 = Color3.fromRGB(0, 175, 70)
startButton.Text = "START"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextScaled = true
startButton.Font = Enum.Font.GothamBold
startButton.Parent = frame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 9)
startCorner.Parent = startButton

--==================================================
-- STOP
--==================================================

local stopButton = Instance.new("TextButton")
stopButton.Position = UDim2.fromOffset(30, 218)
stopButton.Size = UDim2.new(1, -60, 0, 40)
stopButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
stopButton.Text = "STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextScaled = true
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = frame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 9)
stopCorner.Parent = stopButton

--==================================================
-- CREDIT
--==================================================

local credit = Instance.new("TextLabel")
credit.Position = UDim2.new(0, 0, 1, -32)
credit.Size = UDim2.new(1, 0, 0, 25)
credit.BackgroundTransparency = 1
credit.Text = "by k3wlkid"
credit.TextColor3 = Color3.fromRGB(255, 220, 220)
credit.TextScaled = true
credit.Font = Enum.Font.GothamBold
credit.Parent = frame

--==================================================
-- PROMPT POSITION
--==================================================

local function getPromptPosition(prompt)

	local parent = prompt.Parent

	if parent:IsA("BasePart") then
		return parent.Position
	end

	if parent:IsA("Attachment") then
		return parent.WorldPosition
	end

	if parent:IsA("Model") then
		local part =
			parent.PrimaryPart
			or parent:FindFirstChildWhichIsA("BasePart")

		if part then
			return part.Position
		end
	end

	return nil
end

--==================================================
-- GET PROMPTS
--==================================================

local function getPrompts(name)

	local result = {}

	for _, object in ipairs(workspace:GetDescendants()) do

		if object:IsA("ProximityPrompt")
			and object.Name == name
			and object.Enabled then

			table.insert(result, object)
		end
	end

	return result
end

--==================================================
-- FARTHEST STEAL
--==================================================

local function getFarthestSteal()

	local root = getRoot()

	local farthest = nil
	local farthestDistance = -math.huge

	local prompts = getPrompts(STEAL_NAME)

	if #prompts == 0 then
		return nil
	end

	for _, prompt in ipairs(prompts) do

		local position = getPromptPosition(prompt)

		if position then

			local distance =
				(root.Position - position).Magnitude

			if distance > farthestDistance then
				farthestDistance = distance
				farthest = prompt
			end
		end
	end

	return farthest
end

--==================================================
-- TELEPORT
--==================================================

local function teleportToPrompt(prompt)

	if not prompt then
		return false
	end

	local position = getPromptPosition(prompt)

	if not position then
		return false
	end

	local root = getRoot()

	root.CFrame =
		CFrame.new(position + Vector3.new(0, 3, 0))

	return true
end

--==================================================
-- FIND CLOSEST HATCH
--==================================================

local function findHatch()

	local root = getRoot()

	local closest = nil
	local closestDistance = math.huge

	for _, prompt in ipairs(getPrompts(HATCH_NAME)) do

		local position = getPromptPosition(prompt)

		if position then

			local distance =
				(root.Position - position).Magnitude

			if distance < closestDistance then
				closestDistance = distance
				closest = prompt
			end
		end
	end

	return closest
end

--==================================================
-- HATCH INTERRUPT
--==================================================

local function handleHatch(prompt)

	if hatchBusy or not running then
		return
	end

	hatchBusy = true

	local root = getRoot()

	-- Remember exactly where the task was.
	interruptedCFrame = root.CFrame

	status.Text = "🥚 HATCH DETECTED!"

	task.wait(0.1)

	if not running then
		hatchBusy = false
		return
	end

	teleportToPrompt(prompt)

	task.wait(0.2)

	-- Prompt interaction belongs to the game's
	-- normal ProximityPrompt/server system.
	--
	-- If this is your own game, the server should
	-- handle the actual Hatch action when the prompt
	-- is triggered.

	if interruptedCFrame and running then
		root.CFrame = interruptedCFrame
	end

	task.wait(0.15)

	interruptedCFrame = nil
	hatchBusy = false

	if running then
		status.Text =
			"Status: Loop " ..
			currentLoop ..
			"/" ..
			(totalLoops == 0 and "∞" or totalLoops)
	end
end

--==================================================
-- HATCH WATCHER
--==================================================

task.spawn(function()

	while true do

		if running and not hatchBusy then

			local hatch = findHatch()

			if hatch then
				handleHatch(hatch)
			end
		end

		task.wait(0.1)
	end
end)

--==================================================
-- ONE LOOP
--==================================================

local function runOneTask()

	if not running then
		return false
	end

	local root = getRoot()

	-- Save starting position.
	savedCFrame = root.CFrame

	status.Text = "Status: Looking for Steal..."

	task.wait(0.1)

	local steal = getFarthestSteal()

	if not steal then
		status.Text = "ERROR: No 'Steal' prompt found!"
		return false
	end

	status.Text = "Status: Steal found!"

	task.wait(0.2)

	if not running then
		return false
	end

	teleportToPrompt(steal)

	status.Text = "Status: At Steal..."

	task.wait(0.3)

	if not running then
		return false
	end

	-- Return to the saved position.
	root.CFrame = savedCFrame

	status.Text = "Status: Back at saved position"

	task.wait(0.3)

	return true
end

--==================================================
-- LOOP NUMBER
--==================================================

local function getLoopCount()

	local number = tonumber(loopBox.Text)

	if not number then
		loopBox.Text = "1"
		return 1
	end

	number = math.floor(number)

	if number < 0 then
		number = 1
	end

	loopBox.Text = tostring(number)

	return number
end

--==================================================
-- MAIN AUTOMATION
--==================================================

local function startAutomation()

	if running then
		return
	end

	running = true
	hatchBusy = false
	currentLoop = 0

	totalLoops = getLoopCount()

	startButton.Text = "RUNNING..."

	task.spawn(function()

		while running do

			if totalLoops > 0
				and currentLoop >= totalLoops then

				break
			end

			currentLoop += 1

			status.Text =
				"Status: Loop " ..
				currentLoop ..
				"/" ..
				(totalLoops == 0 and "∞" or totalLoops)

			local success = runOneTask()

			if not success then
				break
			end

			task.wait(0.25)
		end

		running = false
		hatchBusy = false

		startButton.Text = "START"

		if currentLoop > 0 then
			status.Text =
				"Status: Finished (" ..
				currentLoop ..
				" loops)"
		else
			status.Text = "Status: Stopped"
		end
	end)
end

--==================================================
-- BUTTONS
--==================================================

startButton.Activated:Connect(function()
	startAutomation()
end)

stopButton.Activated:Connect(function()

	running = false
	hatchBusy = false
	interruptedCFrame = nil

	startButton.Text = "START"
	status.Text = "Status: Stopped"
end)

--==================================================
-- PC + MOBILE DRAG
--==================================================

local dragging = false
local dragStart = nil
local startPosition = nil

frame.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		local delta =
			input.Position - dragStart

		frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)
