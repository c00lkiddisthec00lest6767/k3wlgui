
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local enabled = false
local running = false

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TrickOrTreatGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 125)
frame.Position = UDim2.new(0.5, -120, 0.5, -62)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "🎃 Trick or Treat Auto"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0.8, 0, 0, 42)
toggle.Position = UDim2.new(0.1, 0, 0, 58)
toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggle.Text = "OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 16
toggle.Font = Enum.Font.GothamBold
toggle.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = toggle

-- Find prompts
local function getPrompts()
    local prompts = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ProximityPrompt")
            and object.Name == "Trick or Treat"
            and object.Enabled then

            table.insert(prompts, object)
        end
    end

    return prompts
end

-- Approach and attempt interaction
local function activatePrompt(prompt)
    if not prompt.Parent or not prompt.Enabled then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then return end

    local part = prompt.Parent

    if part:IsA("Attachment") then
        part = part.Parent
    end

    if not part or not part:IsA("BasePart") then
        return
    end

    -- Teleport close to prompt
    root.CFrame = part.CFrame * CFrame.new(0, 0, -3)

    task.wait(0.5)

    -- Attempt normal prompt interaction
    if prompt.Enabled then
        prompt:InputHoldBegin()

        task.wait(math.max(prompt.HoldDuration, 0.1))

        prompt:InputHoldEnd()
    end
end

-- Automation loop
local function startAutomation()
    if running then return end
    running = true

    while enabled do
        local prompts = getPrompts()

        for _, prompt in ipairs(prompts) do
            if not enabled then break end

            if prompt.Parent and prompt.Enabled then
                activatePrompt(prompt)
                task.wait(math.random(10, 15))
            end
        end

        task.wait(1)
    end

    running = false
end

-- Toggle
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled

    toggle.Text = enabled and "ON" or "OFF"

    toggle.BackgroundColor3 = enabled
        and Color3.fromRGB(40, 170, 80)
        or Color3.fromRGB(180, 50, 50)

    if enabled then
        task.spawn(startAutomation)
    end
end)
