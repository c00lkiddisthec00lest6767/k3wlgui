-- k3wlEGG
-- by k3wlkid
-- Mobile + PC friendly
-- Steal / Hatch automation with loop count

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
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

--==================================================
-- UI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "k3wlEGG"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 310, 0, 300)
frame.Position = UDim2.new(0.5, -155, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "k3wlEGG"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.new(0, 0, 0, 40)
subtitle.Size = UDim2.new(1, 0, 0, 25)
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
loopLabel.Position = UDim2.new(0.1, 0, 0, 72)
loopLabel.Size = UDim2.new(0.35, 0, 0, 35)
loopLabel.BackgroundTransparency = 1
loopLabel.Text = "Loops:"
loopLabel.TextColor3 = Color3.new(1, 1, 1)
loopLabel.TextScaled = true
loopLabel.Font = Enum.Font.GothamBold
loopLabel.Parent = frame

--==================================================
-- LOOP TEXTBOX
--==================================================

local loopBox = Instance.new("TextBox")
loopBox.Position = UDim2.new(0.47, 0, 0, 72)
loopBox.Size = UDim2.new(0.43, 0, 0, 35)
loopBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loopBox.TextColor3 = Color3.fromRGB(30, 30, 30)
loopBox.PlaceholderText = "1 = one time"
loopBox.Text = "1"
loopBox.TextScaled = true
loopBox.Font = Enum.Font.GothamBold
loopBox.ClearTextOnFocus = false
loopBox.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 7)
boxCorner.Parent = loopBox

--==================================================
-- STATUS
--==================================================

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0.05, 0, 0, 112)
status.Size = UDim2.new(0.9, 0, 0, 25)
status.BackgroundTransparency = 1
status.Text = "Status: Ready"
status.TextColor3 = Color3.fromRGB(255, 230, 230)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

--==================================================
-- START BUTTON
--==================================================

local startButton = Instance.new("TextButton")
startButton.Position = UDim2.new(0.1, 0, 0, 145)
startButton.Size = UDim2.new(0.8, 0, 0, 48)
startButton.BackgroundColor3 = Color3.fromRGB(0, 170, 70)
startButton.Text = "START"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextScaled = true
startButton.Font = Enum.Font.GothamBold
startButton.Parent = frame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

--==================================================
-- STOP BUTTON
--==================================================

local stopButton = Instance.new("TextButton")
stopButton.Position = UDim2.new(0.1, 0, 0, 201)
stopButton.Size = UDim2.new(0.8, 0, 0, 40)
stopButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
stopButton.Text = "STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextScaled = true
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = frame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
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
-- PROMPT HELPERS
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
		local part = parent.PrimaryPart
			or parent:FindFirstChildWhichIsA("BasePart")

		if part then
			return part.Position
		end
	end

	return nil
end

local function getPrompts(name)
	local prompts = {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt")
			and obj.Name == name
			and obj.Enabled then

			table.insert(prompts, obj)
		end
	end

	return prompts
end

--==================================================
-- FARTHEST STEAL
--==================================================

local function getFarthestSteal()
	local root = getRoot()

	local farthest = nil
	local farthestDistance = -math.huge

	for _, prompt in ipairs(getPrompts(STEAL_NAME)) do
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
-- INTERACT
--==================================================

local function interact(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end

	-- For your own Studio experience, have the server
	-- listen for PromptTriggered and perform the action.

	prompt:InputHoldBegin()

	if prompt.HoldDuration > 0 then
		task.wait(prompt.HoldDuration)
	end

	prompt:InputHoldEnd()
end

--==================================================
-- FIND HATCH
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

	-- Save current task position.
	interruptedCFrame = root.CFrame

	status.Text = "Status: HATCH DETECTED!"

	-- Go to Hatch.
	if teleportToPrompt(prompt) then

		task.wait(0.15)

		interact(prompt)

		task.wait(0.15)

		-- Return to task.
		if interruptedCFrame and running then
			root.CFrame = interruptedCFrame
		end
	end

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
-- ONE STEAL TASK
--==================================================

local function runOneTask()
	if not running then
		return false
	end

	local root = getRoot()

	-- Save original position.
	savedCFrame = root.CFrame

	status.Text = "Status: Finding farthest Steal..."

	local steal = getFarthestSteal()

	if not steal then
		status.Text = "Status: No Steal found"
		return false
	end

	status.Text = "Status: Going to Steal..."

	teleportToPrompt(steal)

	task.wait(0.15)

	if not running then
		return false
	end

	status.Text = "Status: Stealing..."

	interact(steal)

	task.wait(0.15)

	if not running then
		return false
	end

	-- Return to original position.
	status.Text = "Status: Returning..."

	root.CFrame = savedCFrame

	task.wait(0.15)

	if not running then
		return false
	end

	-- Final interaction near saved position.
	status.Text = "Status: Finishing..."

	for _, prompt in ipairs(workspace:GetDescendants()) do

		if prompt:IsA("ProximityPrompt")
			and prompt.Enabled then

			local position = getPromptPosition(prompt)

			if position then

				local distance =
					(position - savedCFrame.Position).Magnitude

				if distance <= 8 then
					interact(prompt)
					break
				end
			end
		end
	end

	return true
end

--==================================================
-- LOOP PARSER
--==================================================

local function getLoopCount()
	local number = tonumber(loopBox.Text)

	if not number then
		return 1
	end

	number = math.floor(number)

	if number < 0 then
		number = 1
	end

	return number
end

--==================================================
-- MAIN LOOP
--==================================================

local function startAutomation()
	if running then
		return
	end

	running = true
	hatchBusy = false
	currentLoop = 0

	totalLoops = getLoopCount()

	if totalLoops == 0 then
		status.Text = "Status: Running ∞ loops"
	else
		status.Text =
			"Status: Running " ..
			totalLoops ..
			" loops"
	end

	while running do

		-- 0 = infinite
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

		-- Small delay before next loop.
		task.wait(0.2)
	end

	running = false
	hatchBusy = false

	startButton.Text = "START"
	status.Text = "Status: Finished"
end

--==================================================
-- BUTTONS
--==================================================

startButton.Activated:Connect(function()
	if running then
		return
	end

	startButton.Text = "RUNNING..."

	task.spawn(startAutomation)
end)

stopButton.Activated:Connect(function()
	running = false
	hatchBusy = false
	interruptedCFrame = nil

	startButton.Text = "START"
	status.Text = "Status: Stopped"
end)

--==================================================
-- MOBILE + PC DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

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
