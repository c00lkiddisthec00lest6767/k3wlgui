local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local AdminCommand = ReplicatedStorage:WaitForChild("AdminCommand")

local AdminCommandResult = ReplicatedStorage:FindFirstChild("AdminCommandResult")
    or ReplicatedStorage:WaitForChild("AdminCommandResult", 5)

local camera = workspace.CurrentCamera

local function getScreenSize()
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local MIN_WIDTH, MIN_HEIGHT, DEFAULT_WIDTH, DEFAULT_HEIGHT
if isMobile then
    MIN_WIDTH, MIN_HEIGHT = 300, 260
    DEFAULT_WIDTH, DEFAULT_HEIGHT = 320, 280
else
    MIN_WIDTH, MIN_HEIGHT = 460, 320
    DEFAULT_WIDTH, DEFAULT_HEIGHT = 480, 340
end

local function getMaxSize()
    local screen = getScreenSize()
    local margin = isMobile and 24 or 60
    local hardCapWidth = isMobile and 700 or 980
    local hardCapHeight = isMobile and 560 or 760
    return math.min(hardCapWidth, screen.X - margin), math.min(hardCapHeight, screen.Y - margin)
end

do
    local maxW, maxH = getMaxSize()
    DEFAULT_WIDTH = math.clamp(DEFAULT_WIDTH, MIN_WIDTH, maxW)
    DEFAULT_HEIGHT = math.clamp(DEFAULT_HEIGHT, MIN_HEIGHT, maxH)
end

local COLOR_BG        = Color3.fromRGB(42, 20, 22)
local COLOR_SIDEBAR   = Color3.fromRGB(34, 16, 18)
local COLOR_ROW       = Color3.fromRGB(54, 26, 28)
local COLOR_ROW_HOVER = Color3.fromRGB(66, 32, 34)
local COLOR_ACCENT    = Color3.fromRGB(214, 110, 95)
local COLOR_TEXT      = Color3.fromRGB(240, 232, 232)
local COLOR_SUBTEXT   = Color3.fromRGB(188, 160, 160)
local COLOR_INPUT     = Color3.fromRGB(26, 12, 14)
local COLOR_DANGER    = Color3.fromRGB(235, 95, 95)
local COLOR_CAT_ACTIVE = Color3.fromRGB(214, 110, 95)

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local BASE_CATEGORIES = {
    {
        name = "ESP",
        commands = {
            {"Toggle ESP", "esp_toggle", false},
        },
    },
    {
        name = "Fun",
        commands = {
            {"Bighead",       "bighead",       false},
            {"Confetti",      "confetti",      false},
            {"Dance",         "dance",         false},
            {"Giant",         "giant",         false},
            {"Glow",          "glow",          false},
            {"Laugh",         "laugh",         false},
            {"Nolimbs",       "nolimbs",       false},
            {"Platformstand", "platformstand", false},
            {"Point",         "point",         false},
            {"Ragdoll",       "ragdoll",       false},
            {"Rainbow",       "rainbow",       false},
            {"Salute",        "salute",        false},
            {"Sit",           "sit",           false},
            {"Sparkles",      "sparkles",      false},
            {"Spin",          "spin",          false},
            {"Tiny",          "tiny",          false},
            {"Trip",          "trip",          false},
            {"Wave",          "wave",          false},
            {"Zombie",        "zombie",        false},
        },
    },
    {
        name = "Troll",
        commands = {
            {"Blackout",        "blackout",        false},
            {"Chatspam",        "chatspam",        false},
            {"Confuse",         "confuse",         false},
            {"Drunk",           "drunk",           false},
            {"Fakekick",        "fakekick",        false},
            {"Fakeerror",       "fakeerror",       false},
            {"Flash",           "flash",           false},
            {"Invertcontrols",  "invertcontrols",  false},
            {"Loudnoise",       "loudnoise",       false},
            {"Randomteleport",  "randomteleport",  false},
            {"Screenshake",     "screenshake",     false},
            {"Shuffle",         "shuffle",         false},
            {"Spamjump",        "spamjump",        false},
            {"Spin360",         "spin360",         false},
            {"Upsidedown",      "upsidedown",      false},
        },
    },
    {
        name = "Combat",
        commands = {
            {"Blind",     "blind",     false},
            {"Explode",   "explode",   true},
            {"Fling",     "fling",     true},
            {"Freeze",    "freeze",    false},
            {"Kill",      "kill",      true},
            {"Knockback", "knockback", false},
            {"Stun",      "stun",      false},
            {"Unfreeze",  "unfreeze",  false},
        },
    },
    {
        name = "Movement",
        commands = {
            {"Fly",            "fly",         false},
            {"Jump Power",     "jumppower",   false},
            {"Noclip",         "noclip",      false},
            {"Speed",          "speed",       false},
            {"Superjump",      "superjump",   false},
            {"Teleport",       "teleport",    false},
            {"Unfly",          "unfly",       false},
            {"Unnoclip",       "unnoclip",    false},
            {"Walk On Water",  "walkonwater", false},
        },
    },
    {
        name = "Visuals",
        commands = {
            {"Cape",      "cape",      false},
            {"Headband",  "headband",  false},
            {"Invisible", "invisible", false},
            {"Jacket",    "jacket",    false},
            {"Neon",      "neon",      false},
            {"Trail",     "trail",     false},
            {"Visible",   "visible",   false},
        },
    },
    {
        name = "Transform",
        commands = {
            {"Block",   "block",   false},
            {"Chicken", "chicken", false},
            {"Creeper", "creeper", false},
            {"Duck",    "duck",    false},
        },
    },
    {
        name = "Main",
        commands = {
            {"Anchor",     "anchor",    false},
            {"God",        "god",       false},
            {"Heal",       "heal",      false},
            {"Max Health", "maxhealth", false},
            {"Respawn",    "respawn",   false},
            {"Unanchor",   "unanchor",  false},
            {"Ungod",      "ungod",     false},
        },
    },
}

local ALL_COMMANDS = {}
for _, cat in ipairs(BASE_CATEGORIES) do
    for _, cmd in ipairs(cat.commands) do
        table.insert(ALL_COMMANDS, cmd)
    end
end

local CATEGORIES = {}
table.insert(CATEGORIES, {name = "Home", commands = {}})
table.insert(CATEGORIES, {name = "All", commands = ALL_COMMANDS})
for _, cat in ipairs(BASE_CATEGORIES) do
    table.insert(CATEGORIES, cat)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "k3wlgui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
local toggleSize = isMobile and 58 or 46
toggleButton.Size = UDim2.new(0, toggleSize, 0, toggleSize)
toggleButton.Position = UDim2.new(0, 12, 0.5, -toggleSize / 2)
toggleButton.BackgroundColor3 = COLOR_ACCENT
toggleButton.Text = "k"
toggleButton.Font = FONT_BOLD
toggleButton.TextSize = isMobile and 24 or 20
toggleButton.TextColor3 = COLOR_TEXT
toggleButton.AutoButtonColor = false
toggleButton.Parent = screenGui
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)

local main = Instance.new("Frame")
main.Size = UDim2.new(0, DEFAULT_WIDTH, 0, DEFAULT_HEIGHT)
main.Position = UDim2.new(0.5, -DEFAULT_WIDTH / 2, 0.5, -DEFAULT_HEIGHT / 2)
main.BackgroundColor3 = COLOR_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(80, 44, 46)
mainStroke.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = COLOR_SIDEBAR
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 60, 1, 0)
title.Position = UDim2.new(0, 16, 0, -4)
title.BackgroundTransparency = 1
title.Text = "k3wlgui"
title.Font = FONT_BOLD
title.TextSize = 15
title.TextColor3 = COLOR_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 22, 0, 14)
versionLabel.Position = UDim2.new(0, 76, 0, 1)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1"
versionLabel.Font = FONT
versionLabel.TextSize = 10
versionLabel.TextColor3 = COLOR_SUBTEXT
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = titleBar

local betaBadge = Instance.new("Frame")
betaBadge.Size = UDim2.new(0, 34, 0, 14)
betaBadge.Position = UDim2.new(0, 98, 0, 1)
betaBadge.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
betaBadge.BorderSizePixel = 0
betaBadge.Parent = titleBar
Instance.new("UICorner", betaBadge).CornerRadius = UDim.new(0, 4)

local betaBadgeLabel = Instance.new("TextLabel")
betaBadgeLabel.Size = UDim2.new(1, 0, 1, 0)
betaBadgeLabel.BackgroundTransparency = 1
betaBadgeLabel.Text = "BETA"
betaBadgeLabel.Font = FONT_BOLD
betaBadgeLabel.TextSize = 9
betaBadgeLabel.TextColor3 = Color3.fromRGB(74, 27, 12)
betaBadgeLabel.Parent = betaBadge

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0.5, -110, 0, 14)
subtitle.Position = UDim2.new(0, 16, 0, 22)
subtitle.BackgroundTransparency = 1
subtitle.Text = "By: k3wlkid"
subtitle.Font = FONT
subtitle.TextSize = 10
subtitle.TextColor3 = COLOR_SUBTEXT
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleBar

local titleBtnSize = isMobile and 34 or 26
local titleBtnGap = isMobile and 8 or 4
local titleBtnEdgeMargin = 8
local closeX = -(titleBtnEdgeMargin + titleBtnSize)
local maximizeX = closeX - titleBtnGap - titleBtnSize
local minimizeX = maximizeX - titleBtnGap - titleBtnSize

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, titleBtnSize, 0, titleBtnSize)
minimizeButton.Position = UDim2.new(1, minimizeX, 0.5, -titleBtnSize / 2)
minimizeButton.BackgroundColor3 = COLOR_ROW
minimizeButton.Text = "–"
minimizeButton.Font = FONT_BOLD
minimizeButton.TextSize = isMobile and 20 or 15
minimizeButton.TextColor3 = COLOR_SUBTEXT
minimizeButton.AutoButtonColor = false
minimizeButton.Parent = titleBar
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 6)

local maximizeButton = Instance.new("TextButton")
maximizeButton.Size = UDim2.new(0, titleBtnSize, 0, titleBtnSize)
maximizeButton.Position = UDim2.new(1, maximizeX, 0.5, -titleBtnSize / 2)
maximizeButton.BackgroundColor3 = COLOR_ROW
maximizeButton.Text = "▢"
maximizeButton.Font = FONT_BOLD
maximizeButton.TextSize = isMobile and 16 or 12
maximizeButton.TextColor3 = COLOR_SUBTEXT
maximizeButton.AutoButtonColor = false
maximizeButton.Parent = titleBar
Instance.new("UICorner", maximizeButton).CornerRadius = UDim.new(0, 6)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, titleBtnSize, 0, titleBtnSize)
closeButton.Position = UDim2.new(1, closeX, 0.5, -titleBtnSize / 2)
closeButton.BackgroundColor3 = COLOR_ROW
closeButton.Text = "X"
closeButton.Font = FONT_BOLD
closeButton.TextSize = isMobile and 17 or 13
closeButton.TextColor3 = COLOR_SUBTEXT
closeButton.AutoButtonColor = false
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

local normalSize = main.Size
local normalPosition = main.Position
local isMinimized = false
local isMaximized = false

local sidebar
local content

local function setBodyVisible(visible)
    sidebar.Visible = visible
    content.Visible = visible
end

local function setMinimized(minimize)
    if isMaximized then return end
    isMinimized = minimize
    if minimize then
        normalSize = main.Size
        main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 48)
        setBodyVisible(false)
        minimizeButton.Text = "▭"
    else
        main.Size = normalSize
        setBodyVisible(true)
        minimizeButton.Text = "–"
    end
end

local function setMaximized(maximize)
    if isMinimized then setMinimized(false) end
    isMaximized = maximize
    if maximize then
        normalSize = main.Size
        normalPosition = main.Position
        main.Size = UDim2.new(0.92, 0, 0.88, 0)
        main.Position = UDim2.new(0.04, 0, 0.06, 0)
        maximizeButton.Text = "❐"
        setBodyVisible(true)
    else
        main.Size = normalSize
        main.Position = normalPosition
        maximizeButton.Text = "▢"
    end
end

minimizeButton.MouseButton1Click:Connect(function()
    setMinimized(not isMinimized)
end)

maximizeButton.MouseButton1Click:Connect(function()
    setMaximized(not isMaximized)
end)

do
    local dragging, dragStart, startAbsPos, startScale = false, nil, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if isMaximized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startAbsPos = main.AbsolutePosition
            startScale = Vector2.new(main.Position.X.Scale, main.Position.Y.Scale)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local screen = getScreenSize()
            local visibleMargin = 80

            local newAbsX = startAbsPos.X + delta.X
            local newAbsY = startAbsPos.Y + delta.Y

            local minAbsX = -main.AbsoluteSize.X + visibleMargin
            local maxAbsX = screen.X - visibleMargin
            local minAbsY = 0
            local maxAbsY = screen.Y - visibleMargin

            newAbsX = math.clamp(newAbsX, minAbsX, maxAbsX)
            newAbsY = math.clamp(newAbsY, minAbsY, maxAbsY)

            local offsetX = newAbsX - startScale.X * screen.X
            local offsetY = newAbsY - startScale.Y * screen.Y

            main.Position = UDim2.new(startScale.X, offsetX, startScale.Y, offsetY)
        end
    end)
end

sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = COLOR_SIDEBAR
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, -20, 0, 32)
searchFrame.Position = UDim2.new(0, 10, 0, 10)
searchFrame.BackgroundColor3 = COLOR_INPUT
searchFrame.BorderSizePixel = 0
searchFrame.Parent = sidebar
Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 6)

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, 20, 1, 0)
searchIcon.Position = UDim2.new(0, 6, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextSize = 12
searchIcon.TextColor3 = COLOR_SUBTEXT
searchIcon.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -32, 1, 0)
searchBox.Position = UDim2.new(0, 28, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "Search"
searchBox.Font = FONT
searchBox.TextSize = 13
searchBox.TextColor3 = COLOR_TEXT
searchBox.PlaceholderColor3 = COLOR_SUBTEXT
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = searchFrame

local catList = Instance.new("ScrollingFrame")
catList.Size = UDim2.new(1, -12, 1, -54)
catList.Position = UDim2.new(0, 6, 0, 50)
catList.BackgroundTransparency = 1
catList.BorderSizePixel = 0
catList.ScrollBarThickness = 3
catList.ScrollBarImageColor3 = COLOR_ACCENT
catList.CanvasSize = UDim2.new(0, 0, 0, 0)
catList.AutomaticCanvasSize = Enum.AutomaticSize.Y
catList.Parent = sidebar

local catLayout = Instance.new("UIListLayout")
catLayout.SortOrder = Enum.SortOrder.LayoutOrder
catLayout.Padding = UDim.new(0, 2)
catLayout.Parent = catList

content = Instance.new("Frame")
content.Size = UDim2.new(1, -160, 1, -40)
content.Position = UDim2.new(0, 160, 0, 40)
content.BackgroundColor3 = COLOR_BG
content.BorderSizePixel = 0
content.Parent = main

local resizeHandleSize = isMobile and 30 or 18
local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, resizeHandleSize, 0, resizeHandleSize)
resizeHandle.Position = UDim2.new(1, -resizeHandleSize, 1, -resizeHandleSize)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = ""
resizeHandle.AutoButtonColor = false
resizeHandle.ZIndex = 20
resizeHandle.Parent = main

local resizeIcon = Instance.new("TextLabel")
resizeIcon.Size = UDim2.new(1, 0, 1, 0)
resizeIcon.BackgroundTransparency = 1
resizeIcon.Text = "⋰"
resizeIcon.Font = FONT_BOLD
resizeIcon.TextSize = 16
resizeIcon.TextColor3 = COLOR_SUBTEXT
resizeIcon.Rotation = 90
resizeIcon.ZIndex = 20
resizeIcon.Parent = resizeHandle

do
    local resizing, resizeStart, startSize = false, nil, nil
    resizeHandle.InputBegan:Connect(function(input)
        if isMaximized or isMinimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = main.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local maxW, maxH = getMaxSize()
            local newWidth = math.clamp(startSize.X.Offset + delta.X, MIN_WIDTH, maxW)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, MIN_HEIGHT, maxH)
            main.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)
end

local contentHeader = Instance.new("TextLabel")
contentHeader.Size = UDim2.new(1, -32, 0, 30)
contentHeader.Position = UDim2.new(0, 16, 0, 12)
contentHeader.BackgroundTransparency = 1
contentHeader.Font = FONT_BOLD
contentHeader.TextSize = 16
contentHeader.TextColor3 = COLOR_TEXT
contentHeader.TextXAlignment = Enum.TextXAlignment.Left
contentHeader.Text = "Fun"
contentHeader.Parent = content

local targetSelector = Instance.new("TextButton")
targetSelector.Size = UDim2.new(0.62, -20, 0, 30)
targetSelector.Position = UDim2.new(0, 16, 0, 44)
targetSelector.BackgroundColor3 = COLOR_INPUT
targetSelector.AutoButtonColor = false
targetSelector.Font = FONT
targetSelector.TextSize = 13
targetSelector.TextColor3 = COLOR_TEXT
targetSelector.TextXAlignment = Enum.TextXAlignment.Left
targetSelector.Text = "  Target: Yourself  ▾"
targetSelector.Parent = content
Instance.new("UICorner", targetSelector).CornerRadius = UDim.new(0, 6)
local targetSelectorStroke = Instance.new("UIStroke")
targetSelectorStroke.Color = Color3.fromRGB(80, 44, 46)
targetSelectorStroke.Parent = targetSelector

local valueBox = Instance.new("TextBox")
valueBox.Size = UDim2.new(0.38, -12, 0, 30)
valueBox.Position = UDim2.new(0.62, 4, 0, 44)
valueBox.BackgroundColor3 = COLOR_INPUT
valueBox.PlaceholderText = "Value (e.g. Speed #)"
valueBox.Font = FONT
valueBox.TextSize = 13
valueBox.TextColor3 = COLOR_TEXT
valueBox.PlaceholderColor3 = COLOR_SUBTEXT
valueBox.Text = ""
valueBox.ClearTextOnFocus = false
valueBox.TextXAlignment = Enum.TextXAlignment.Left
valueBox.Parent = content
Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 6)
local valueBoxPad = Instance.new("UIPadding")
valueBoxPad.PaddingLeft = UDim.new(0, 8)
valueBoxPad.Parent = valueBox

local espColorRow = Instance.new("Frame")
espColorRow.Size = UDim2.new(1, -32, 0, 30)
espColorRow.Position = UDim2.new(0, 16, 0, 44)
espColorRow.BackgroundTransparency = 1
espColorRow.Visible = false
espColorRow.Parent = content

local espColorLabel = Instance.new("TextLabel")
espColorLabel.Size = UDim2.new(0, 90, 1, 0)
espColorLabel.BackgroundTransparency = 1
espColorLabel.Font = FONT
espColorLabel.TextSize = 12
espColorLabel.TextColor3 = COLOR_SUBTEXT
espColorLabel.TextXAlignment = Enum.TextXAlignment.Left
espColorLabel.Text = "Highlight color:"
espColorLabel.Parent = espColorRow

local espColorSwatchHolder = Instance.new("Frame")
espColorSwatchHolder.Size = UDim2.new(1, -94, 1, 0)
espColorSwatchHolder.Position = UDim2.new(0, 94, 0, 0)
espColorSwatchHolder.BackgroundTransparency = 1
espColorSwatchHolder.Parent = espColorRow

local espColorSwatchLayout = Instance.new("UIListLayout")
espColorSwatchLayout.FillDirection = Enum.FillDirection.Horizontal
espColorSwatchLayout.Padding = UDim.new(0, 6)
espColorSwatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
espColorSwatchLayout.Parent = espColorSwatchHolder

local targetDropdown = Instance.new("Frame")
targetDropdown.Size = UDim2.new(0.62, -20, 0, 170)
targetDropdown.Position = UDim2.new(0, 16, 0, 78)
targetDropdown.BackgroundColor3 = COLOR_SIDEBAR
targetDropdown.BorderSizePixel = 0
targetDropdown.Visible = false
targetDropdown.ZIndex = 10
targetDropdown.Parent = content
Instance.new("UICorner", targetDropdown).CornerRadius = UDim.new(0, 6)
local targetDropdownStroke = Instance.new("UIStroke")
targetDropdownStroke.Color = COLOR_ACCENT
targetDropdownStroke.Parent = targetDropdown

local targetDropdownList = Instance.new("ScrollingFrame")
targetDropdownList.Size = UDim2.new(1, -8, 1, -8)
targetDropdownList.Position = UDim2.new(0, 4, 0, 4)
targetDropdownList.BackgroundTransparency = 1
targetDropdownList.BorderSizePixel = 0
targetDropdownList.ScrollBarThickness = 3
targetDropdownList.ScrollBarImageColor3 = COLOR_ACCENT
targetDropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
targetDropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetDropdownList.ZIndex = 10
targetDropdownList.Parent = targetDropdown

local targetDropdownLayout = Instance.new("UIListLayout")
targetDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetDropdownLayout.Padding = UDim.new(0, 2)
targetDropdownLayout.Parent = targetDropdownList

local rowList = Instance.new("ScrollingFrame")
rowList.Size = UDim2.new(1, -32, 1, -92)
rowList.Position = UDim2.new(0, 16, 0, 84)
rowList.BackgroundTransparency = 1
rowList.BorderSizePixel = 0
rowList.ScrollBarThickness = 4
rowList.ScrollBarImageColor3 = COLOR_ACCENT
rowList.CanvasSize = UDim2.new(0, 0, 0, 0)
rowList.AutomaticCanvasSize = Enum.AutomaticSize.Y
rowList.Parent = content

local rowLayout = Instance.new("UIListLayout")
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Padding = UDim.new(0, 6)
rowLayout.Parent = rowList

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 16)
status.Position = UDim2.new(0, 16, 1, -22)
status.BackgroundTransparency = 1
status.Font = FONT
status.TextSize = 11
status.TextColor3 = COLOR_ACCENT
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = ""
status.Parent = content

local function setStatus(text, isError)
    status.Text = text
    status.TextColor3 = isError and COLOR_DANGER or COLOR_ACCENT
    task.delay(2.5, function()
        if status.Text == text then status.Text = "" end
    end)
end

local CHANGELOG = {
    {
        version = "v1.0.0",
        tag = "BETA",
        title = "Initial Release",
        sections = {
            {
                header = "🎉 New Features",
                items = {
                    "Launched k3wlgui — a full command panel with 7 categories and 45+ commands",
                    "Added live ESP: player name, health, and distance shown above every player, refreshed in real time",
                    "Added see-through-wall Highlights for ESP with 9 selectable colors, defaulting to red",
                    "Added a player picker — choose anyone in the server, or hit \"All Players\" to run a command on everyone one after another",
                    "Added Fling with a teleport-to, fling, teleport-back sequence, now with server-confirmed success detection",
                },
            },
            {
                header = "🛠️ Improvements",
                items = {
                    "Added full window controls: drag, resize, minimize, and maximize",
                    "Added a new \"All\" tab combining every command from every category into one list",
                    "Alphabetized every category for faster browsing",
                    "Added a search bar to quickly filter commands by name",
                    "Added a value box for commands that need a number, like Speed",
                },
            },
            {
                header = "🎨 Visual Changes",
                items = {
                    "New dark maroon visual theme across the whole panel",
                    "Added version and BETA tags to the title bar",
                    "Added this Home page and Update Log",
                },
            },
        },
    },
}

local homePanel = Instance.new("Frame")
homePanel.Size = UDim2.new(1, -32, 1, -24)
homePanel.Position = UDim2.new(0, 16, 0, 12)
homePanel.BackgroundTransparency = 1
homePanel.Visible = false
homePanel.Parent = content

local homeTitle = Instance.new("TextLabel")
homeTitle.Size = UDim2.new(1, 0, 0, 34)
homeTitle.Position = UDim2.new(0, 0, 0, 20)
homeTitle.BackgroundTransparency = 1
homeTitle.Font = FONT_BOLD
homeTitle.TextSize = 26
homeTitle.TextColor3 = COLOR_TEXT
homeTitle.Text = "k3wlgui"
homeTitle.Parent = homePanel

local homeBadgeRow = Instance.new("Frame")
homeBadgeRow.Size = UDim2.new(1, 0, 0, 20)
homeBadgeRow.Position = UDim2.new(0, 0, 0, 56)
homeBadgeRow.BackgroundTransparency = 1
homeBadgeRow.Parent = homePanel

local homeBadgeLayout = Instance.new("UIListLayout")
homeBadgeLayout.FillDirection = Enum.FillDirection.Horizontal
homeBadgeLayout.Padding = UDim.new(0, 6)
homeBadgeLayout.Parent = homeBadgeRow

local homeVersionTag = Instance.new("TextLabel")
homeVersionTag.Size = UDim2.new(0, 32, 1, 0)
homeVersionTag.BackgroundTransparency = 1
homeVersionTag.Font = FONT
homeVersionTag.TextSize = 12
homeVersionTag.TextColor3 = COLOR_SUBTEXT
homeVersionTag.Text = "v1.0.0"
homeVersionTag.TextXAlignment = Enum.TextXAlignment.Left
homeVersionTag.Parent = homeBadgeRow

local homeBetaTag = Instance.new("Frame")
homeBetaTag.Size = UDim2.new(0, 40, 0, 18)
homeBetaTag.BackgroundColor3 = COLOR_ACCENT
homeBetaTag.BorderSizePixel = 0
homeBetaTag.Parent = homeBadgeRow
Instance.new("UICorner", homeBetaTag).CornerRadius = UDim.new(0, 4)

local homeBetaTagLabel = Instance.new("TextLabel")
homeBetaTagLabel.Size = UDim2.new(1, 0, 1, 0)
homeBetaTagLabel.BackgroundTransparency = 1
homeBetaTagLabel.Font = FONT_BOLD
homeBetaTagLabel.TextSize = 10
homeBetaTagLabel.TextColor3 = Color3.fromRGB(74, 27, 12)
homeBetaTagLabel.Text = "BETA"
homeBetaTagLabel.Parent = homeBetaTag

local homeSubtitle = Instance.new("TextLabel")
homeSubtitle.Size = UDim2.new(1, 0, 0, 16)
homeSubtitle.Position = UDim2.new(0, 0, 0, 82)
homeSubtitle.BackgroundTransparency = 1
homeSubtitle.Font = FONT
homeSubtitle.TextSize = 12
homeSubtitle.TextColor3 = COLOR_SUBTEXT
homeSubtitle.Text = "By: k3wlkid"
homeSubtitle.Parent = homePanel

local homeTagline = Instance.new("TextLabel")
homeTagline.Size = UDim2.new(1, 0, 0, 40)
homeTagline.Position = UDim2.new(0, 0, 0, 106)
homeTagline.BackgroundTransparency = 1
homeTagline.Font = FONT
homeTagline.TextSize = 12
homeTagline.TextColor3 = COLOR_SUBTEXT
homeTagline.TextWrapped = true
homeTagline.Text = "Your all-in-one command panel — ESP, targeting, and 45+ commands, all in one place."
homeTagline.Parent = homePanel

local homeStatsRow = Instance.new("Frame")
homeStatsRow.Size = UDim2.new(1, 0, 0, 24)
homeStatsRow.Position = UDim2.new(0, 0, 0, 152)
homeStatsRow.BackgroundTransparency = 1
homeStatsRow.Parent = homePanel

local homeStatsLayout = Instance.new("UIListLayout")
homeStatsLayout.FillDirection = Enum.FillDirection.Horizontal
homeStatsLayout.Padding = UDim.new(0, 16)
homeStatsLayout.Parent = homeStatsRow

local function addStat(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 150, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = FONT
    lbl.TextSize = 11
    lbl.TextColor3 = COLOR_ACCENT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = homeStatsRow
end

addStat(("%d commands"):format(#ALL_COMMANDS))
addStat(("%d categories"):format(#BASE_CATEGORIES))

local updateLogButton = Instance.new("TextButton")
updateLogButton.Size = UDim2.new(0, 190, 0, 34)
updateLogButton.Position = UDim2.new(0, 0, 0, 196)
updateLogButton.BackgroundColor3 = COLOR_ACCENT
updateLogButton.AutoButtonColor = false
updateLogButton.Font = FONT_BOLD
updateLogButton.TextSize = 13
updateLogButton.TextColor3 = COLOR_TEXT
updateLogButton.Text = "📜  View Update Log"
updateLogButton.Parent = homePanel
Instance.new("UICorner", updateLogButton).CornerRadius = UDim.new(0, 6)

local changelogPanel = Instance.new("Frame")
changelogPanel.Size = UDim2.new(1, -160, 1, -40)
changelogPanel.Position = UDim2.new(0, 160, 0, 40)
changelogPanel.BackgroundColor3 = COLOR_BG
changelogPanel.BorderSizePixel = 0
changelogPanel.ZIndex = 15
changelogPanel.Visible = false
changelogPanel.Parent = main

local changelogHeader = Instance.new("TextLabel")
changelogHeader.Size = UDim2.new(1, -100, 0, 30)
changelogHeader.Position = UDim2.new(0, 16, 0, 12)
changelogHeader.BackgroundTransparency = 1
changelogHeader.Font = FONT_BOLD
changelogHeader.TextSize = 16
changelogHeader.TextColor3 = COLOR_TEXT
changelogHeader.TextXAlignment = Enum.TextXAlignment.Left
changelogHeader.Text = "Update Log"
changelogHeader.ZIndex = 15
changelogHeader.Parent = changelogPanel

local changelogBackButton = Instance.new("TextButton")
changelogBackButton.Size = UDim2.new(0, 76, 0, 26)
changelogBackButton.Position = UDim2.new(1, -92, 0, 14)
changelogBackButton.BackgroundColor3 = COLOR_ROW
changelogBackButton.AutoButtonColor = false
changelogBackButton.Font = FONT
changelogBackButton.TextSize = 12
changelogBackButton.TextColor3 = COLOR_SUBTEXT
changelogBackButton.Text = "← Back"
changelogBackButton.ZIndex = 15
changelogBackButton.Parent = changelogPanel
Instance.new("UICorner", changelogBackButton).CornerRadius = UDim.new(0, 6)

local changelogList = Instance.new("ScrollingFrame")
changelogList.Size = UDim2.new(1, -32, 1, -60)
changelogList.Position = UDim2.new(0, 16, 0, 52)
changelogList.BackgroundTransparency = 1
changelogList.BorderSizePixel = 0
changelogList.ScrollBarThickness = 4
changelogList.ScrollBarImageColor3 = COLOR_ACCENT
changelogList.CanvasSize = UDim2.new(0, 0, 0, 0)
changelogList.AutomaticCanvasSize = Enum.AutomaticSize.Y
changelogList.ZIndex = 15
changelogList.Parent = changelogPanel

local changelogLayout = Instance.new("UIListLayout")
changelogLayout.SortOrder = Enum.SortOrder.LayoutOrder
changelogLayout.Padding = UDim.new(0, 14)
changelogLayout.Parent = changelogList

local function buildChangelog()
    for i, release in ipairs(CHANGELOG) do
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, 0, 0, 0)
        entry.AutomaticSize = Enum.AutomaticSize.Y
        entry.BackgroundColor3 = COLOR_ROW
        entry.LayoutOrder = i
        entry.ZIndex = 15
        entry.Parent = changelogList
        Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 8)

        local entryPad = Instance.new("UIPadding")
        entryPad.PaddingTop = UDim.new(0, 12)
        entryPad.PaddingBottom = UDim.new(0, 12)
        entryPad.PaddingLeft = UDim.new(0, 14)
        entryPad.PaddingRight = UDim.new(0, 14)
        entryPad.Parent = entry

        local entryLayout = Instance.new("UIListLayout")
        entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
        entryLayout.Padding = UDim.new(0, 8)
        entryLayout.Parent = entry

        local headerRow = Instance.new("Frame")
        headerRow.Size = UDim2.new(1, 0, 0, 20)
        headerRow.BackgroundTransparency = 1
        headerRow.LayoutOrder = 1
        headerRow.ZIndex = 15
        headerRow.Parent = entry

        local versionText = Instance.new("TextLabel")
        versionText.Size = UDim2.new(0, 90, 1, 0)
        versionText.BackgroundTransparency = 1
        versionText.Font = FONT_BOLD
        versionText.TextSize = 14
        versionText.TextColor3 = COLOR_TEXT
        versionText.TextXAlignment = Enum.TextXAlignment.Left
        versionText.Text = release.version .. " — " .. release.title
        versionText.ZIndex = 15
        versionText.Parent = headerRow

        if release.tag then
            local tagLabel = Instance.new("TextLabel")
            tagLabel.Size = UDim2.new(0, 40, 0, 16)
            tagLabel.Position = UDim2.new(0, 230, 0, 2)
            tagLabel.BackgroundColor3 = COLOR_ACCENT
            tagLabel.Font = FONT_BOLD
            tagLabel.TextSize = 9
            tagLabel.TextColor3 = Color3.fromRGB(74, 27, 12)
            tagLabel.Text = release.tag
            tagLabel.ZIndex = 15
            tagLabel.Parent = headerRow
            Instance.new("UICorner", tagLabel).CornerRadius = UDim.new(0, 4)
        end

        for si, section in ipairs(release.sections) do
            local sectionLabel = Instance.new("TextLabel")
            sectionLabel.Size = UDim2.new(1, 0, 0, 16)
            sectionLabel.BackgroundTransparency = 1
            sectionLabel.Font = FONT_BOLD
            sectionLabel.TextSize = 12
            sectionLabel.TextColor3 = COLOR_ACCENT
            sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            sectionLabel.Text = section.header
            sectionLabel.LayoutOrder = 1 + si * 10
            sectionLabel.ZIndex = 15
            sectionLabel.Parent = entry

            for ii, item in ipairs(section.items) do
                local itemLabel = Instance.new("TextLabel")
                itemLabel.Size = UDim2.new(1, 0, 0, 0)
                itemLabel.AutomaticSize = Enum.AutomaticSize.Y
                itemLabel.BackgroundTransparency = 1
                itemLabel.Font = FONT
                itemLabel.TextSize = 11
                itemLabel.TextColor3 = COLOR_SUBTEXT
                itemLabel.TextWrapped = true
                itemLabel.TextXAlignment = Enum.TextXAlignment.Left
                itemLabel.Text = "•  " .. item
                itemLabel.LayoutOrder = 1 + si * 10 + ii
                itemLabel.ZIndex = 15
                itemLabel.Parent = entry
            end
        end
    end
end

buildChangelog()

local function openChangelog()
    changelogPanel.Visible = true
end

local function closeChangelog()
    changelogPanel.Visible = false
end

updateLogButton.MouseButton1Click:Connect(openChangelog)
changelogBackButton.MouseButton1Click:Connect(closeChangelog)

local selectedTarget = "self"

local function targetLabelText()
    if selectedTarget == "self" then return "Yourself" end
    if selectedTarget == "all" then return "All Players" end
    if typeof(selectedTarget) == "Instance" and selectedTarget.Parent then
        return selectedTarget.Name
    end
    return "Yourself"
end

local function refreshSelectorLabel()
    targetSelector.Text = "  Target: " .. targetLabelText() .. "  ▾"
end

local function closeDropdown()
    targetDropdown.Visible = false
end

local function buildDropdownRow(labelText, layoutOrder, onClick, highlight)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.LayoutOrder = layoutOrder
    row.BackgroundColor3 = highlight and COLOR_ACCENT or COLOR_ROW
    row.AutoButtonColor = false
    row.Text = ""
    row.ZIndex = 11
    row.Parent = targetDropdownList
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = FONT
    lbl.TextSize = 12
    lbl.TextColor3 = COLOR_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText
    lbl.ZIndex = 11
    lbl.Parent = row

    if not highlight then
        row.MouseEnter:Connect(function() row.BackgroundColor3 = COLOR_ROW_HOVER end)
        row.MouseLeave:Connect(function() row.BackgroundColor3 = COLOR_ROW end)
    end

    row.MouseButton1Click:Connect(function()
        onClick()
        refreshSelectorLabel()
        closeDropdown()
    end)
end

local function rebuildDropdown()
    for _, child in ipairs(targetDropdownList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local order = 0
    order += 1
    buildDropdownRow("Yourself", order, function() selectedTarget = "self" end, selectedTarget == "self")

    order += 1
    buildDropdownRow("⚡ All Players (one by one)", order, function() selectedTarget = "all" end, selectedTarget == "all")

    for _, p in ipairs(Players:GetPlayers()) do
        order += 1
        local isSelected = typeof(selectedTarget) == "Instance" and selectedTarget == p
        buildDropdownRow(p.Name .. (p == LocalPlayer and " (you)" or ""), order, function()
            selectedTarget = p
        end, isSelected)
    end
end

targetSelector.MouseButton1Click:Connect(function()
    if targetDropdown.Visible then
        closeDropdown()
    else
        rebuildDropdown()
        targetDropdown.Visible = true
    end
end)

local function getCurrentValue()
    local rawValue = valueBox.Text
    return rawValue ~= "" and (tonumber(rawValue) or rawValue) or nil
end

local function fireCommand(commandName)
    local extraValue = getCurrentValue()

    if selectedTarget == "self" then
        AdminCommand:FireServer(commandName, {LocalPlayer.Name}, extraValue)
        setStatus(("Used '%s' on yourself"):format(commandName), false)
    elseif selectedTarget == "all" then
        local players = Players:GetPlayers()
        if #players == 0 then
            setStatus("No players in the server", true)
            return
        end
        task.spawn(function()
            for _, p in ipairs(players) do
                AdminCommand:FireServer(commandName, {p.Name}, extraValue)
                task.wait(0.1)
            end
        end)
        setStatus(("Used '%s' on all players"):format(commandName), false)
    else
        local target = selectedTarget
        if not (typeof(target) == "Instance" and target.Parent) then
            setStatus("Selected target left the game — pick a new one", true)
            selectedTarget = "self"
            refreshSelectorLabel()
            return
        end
        AdminCommand:FireServer(commandName, {target.Name}, extraValue)
        setStatus(("Used '%s' on %s"):format(commandName, target.Name), false)
    end
end

local espEnabled = false
local espHighlightColor = Color3.fromRGB(255, 0, 0)
local espData = {}

local function destroyESPFor(player)
    local data = espData[player]
    if not data then return end
    if data.billboard then data.billboard:Destroy() end
    if data.highlight then data.highlight:Destroy() end
    if data.charAddedConn then data.charAddedConn:Disconnect() end
    espData[player] = nil
end

local function attachESP(player, character)
    if not espEnabled then return end
    local existing = espData[player]
    if existing then
        if existing.billboard then existing.billboard:Destroy() end
        if existing.highlight then existing.highlight:Destroy() end
    end

    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not hrp or not humanoid then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "k3wlgui_ESPHighlight"
    highlight.FillColor = espHighlightColor
    highlight.OutlineColor = espHighlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "k3wlgui_ESP"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 170, 0, 54)
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = hrp

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = FONT_BOLD
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = COLOR_ACCENT
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 16)
    healthLabel.Position = UDim2.new(0, 0, 0, 18)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font = FONT
    healthLabel.TextSize = 12
    healthLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    healthLabel.Text = "HP: --/--"
    healthLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 16)
    distLabel.Position = UDim2.new(0, 0, 0, 34)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = FONT
    distLabel.TextSize = 12
    distLabel.TextColor3 = COLOR_SUBTEXT
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Text = "-- studs"
    distLabel.Parent = billboard

    espData[player] = espData[player] or {}
    espData[player].billboard = billboard
    espData[player].highlight = highlight
    espData[player].hrp = hrp
    espData[player].humanoid = humanoid
    espData[player].nameLabel = nameLabel
    espData[player].healthLabel = healthLabel
    espData[player].distLabel = distLabel
end

local function setEspHighlightColor(color)
    espHighlightColor = color
    for _, data in pairs(espData) do
        if data.highlight then
            data.highlight.FillColor = color
            data.highlight.OutlineColor = color
        end
    end
end

local ESP_COLORS = {
    {"Red",    Color3.fromRGB(255, 0, 0)},
    {"Orange", Color3.fromRGB(255, 140, 0)},
    {"Yellow", Color3.fromRGB(255, 230, 0)},
    {"Green",  Color3.fromRGB(0, 220, 90)},
    {"Cyan",   Color3.fromRGB(0, 220, 220)},
    {"Blue",   Color3.fromRGB(60, 130, 255)},
    {"Purple", Color3.fromRGB(170, 90, 255)},
    {"Pink",   Color3.fromRGB(255, 90, 180)},
    {"White",  Color3.fromRGB(255, 255, 255)},
}

local espSwatchButtons = {}

local function refreshSwatchSelection()
    for _, entry in ipairs(espSwatchButtons) do
        entry.stroke.Transparency = (entry.color == espHighlightColor) and 0 or 1
    end
end

for i, data in ipairs(ESP_COLORS) do
    local name, color = data[1], data[2]

    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 22, 0, 22)
    swatch.LayoutOrder = i
    swatch.BackgroundColor3 = color
    swatch.AutoButtonColor = false
    swatch.Text = ""
    swatch.Parent = espColorSwatchHolder
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(1, 0)

    local swatchStroke = Instance.new("UIStroke")
    swatchStroke.Color = COLOR_TEXT
    swatchStroke.Thickness = 2
    swatchStroke.Transparency = 1
    swatchStroke.Parent = swatch

    swatch.MouseButton1Click:Connect(function()
        setEspHighlightColor(color)
        refreshSwatchSelection()
    end)

    table.insert(espSwatchButtons, {color = color, stroke = swatchStroke})
end

refreshSwatchSelection()

local function setupESPTracking(player)
    if player == LocalPlayer then return end
    espData[player] = espData[player] or {}

    if player.Character then
        attachESP(player, player.Character)
    end

    espData[player].charAddedConn = player.CharacterAdded:Connect(function(char)
        attachESP(player, char)
    end)
end

local espHeartbeat
local function enableESP()
    espEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        setupESPTracking(p)
    end

    espHeartbeat = RunService.Heartbeat:Connect(function()
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        for player, data in pairs(espData) do
            if data.billboard and data.billboard.Parent and data.humanoid then
                local hp = math.max(0, math.floor(data.humanoid.Health))
                local maxHp = math.floor(data.humanoid.MaxHealth)
                data.healthLabel.Text = ("HP: %d/%d"):format(hp, maxHp)

                if myHRP and data.hrp and data.hrp.Parent then
                    local dist = (myHRP.Position - data.hrp.Position).Magnitude
                    data.distLabel.Text = ("%d studs"):format(math.floor(dist))
                else
                    data.distLabel.Text = "-- studs"
                end
            end
        end
    end)

    setStatus("ESP enabled", false)
end

local function disableESP()
    espEnabled = false
    if espHeartbeat then
        espHeartbeat:Disconnect()
        espHeartbeat = nil
    end
    for player, _ in pairs(espData) do
        destroyESPFor(player)
    end
    setStatus("ESP disabled", false)
end

local function toggleESP()
    if espEnabled then
        disableESP()
    else
        enableESP()
    end
end

Players.PlayerAdded:Connect(function(p)
    if espEnabled then setupESPTracking(p) end
end)

Players.PlayerRemoving:Connect(function(p)
    destroyESPFor(p)
end)

local isFlinging = false

local function waitForCommandResult(command, targetName, timeout)
    if not AdminCommandResult then
        task.wait(timeout)
        return nil
    end

    local result = nil
    local conn
    conn = AdminCommandResult.OnClientEvent:Connect(function(resultCommand, resultTarget, success)
        if result == nil and resultCommand == command and resultTarget == targetName then
            result = success
        end
    end)

    local startTime = tick()
    while result == nil and (tick() - startTime) < timeout do
        task.wait(0.05)
    end
    conn:Disconnect()
    return result
end

local function performFlingOn(targetPlayer)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local targetChar = targetPlayer.Character
    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if not hrp or not targetHRP then
        setStatus(("Skipped %s (character not ready)"):format(targetPlayer.Name), true)
        return
    end

    local originalCFrame = hrp.CFrame
    hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
    AdminCommand:FireServer("fling", {targetPlayer.Name}, nil)
    setStatus(("Flinging %s..."):format(targetPlayer.Name), false)

    local success = waitForCommandResult("fling", targetPlayer.Name, 2)

    if success == true then
        setStatus(("Flung %s"):format(targetPlayer.Name), false)
    elseif success == false then
        setStatus(("Fling on %s failed"):format(targetPlayer.Name), true)
    else
        setStatus(("No confirmation for %s — add AdminCommandResult on your server"):format(targetPlayer.Name), true)
    end

    character = LocalPlayer.Character
    hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = originalCFrame end
end

local function performFling()
    if isFlinging then return end

    local targets = {}
    if selectedTarget == "self" then
        setStatus("You can't fling yourself with this", true)
        return
    elseif selectedTarget == "all" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(targets, p) end
        end
    else
        if typeof(selectedTarget) == "Instance" and selectedTarget.Parent and selectedTarget ~= LocalPlayer then
            table.insert(targets, selectedTarget)
        end
    end

    if #targets == 0 then
        setStatus("No valid fling target selected", true)
        return
    end

    isFlinging = true
    task.spawn(function()
        for _, p in ipairs(targets) do
            if p.Parent then
                performFlingOn(p)
            end
        end
        isFlinging = false
    end)
end

local function clearRows()
    for _, child in ipairs(rowList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local ROW_HEIGHT = isMobile and 48 or 38
local RUN_BTN_SIZE = isMobile and 34 or 26

local function buildRow(label, commandName, isDanger, layoutOrder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.BackgroundColor3 = COLOR_ROW
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = rowList
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(1, -(RUN_BTN_SIZE + 24), 1, 0)
    rowLabel.Position = UDim2.new(0, 14, 0, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Font = FONT
    rowLabel.TextSize = isMobile and 14 or 13
    rowLabel.TextColor3 = COLOR_TEXT
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.Text = label
    rowLabel.Parent = row

    local runButton = Instance.new("TextButton")
    runButton.Size = UDim2.new(0, RUN_BTN_SIZE, 0, RUN_BTN_SIZE)
    runButton.Position = UDim2.new(1, -(RUN_BTN_SIZE + 10), 0.5, -RUN_BTN_SIZE / 2)
    runButton.BackgroundColor3 = isDanger and COLOR_DANGER or COLOR_ACCENT
    runButton.AutoButtonColor = false
    runButton.Text = "▶"
    runButton.Font = FONT_BOLD
    runButton.TextSize = isMobile and 14 or 11
    runButton.TextColor3 = COLOR_TEXT
    runButton.Parent = row
    Instance.new("UICorner", runButton).CornerRadius = UDim.new(1, 0)

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.ZIndex = 0
    hitbox.Parent = row

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = COLOR_ROW_HOVER}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = COLOR_ROW}):Play()
    end)

    local function trigger()
        if commandName == "fling" then
            performFling()
        elseif commandName == "esp_toggle" then
            toggleESP()
        else
            fireCommand(commandName)
        end
    end

    runButton.MouseButton1Click:Connect(trigger)
    hitbox.MouseButton1Click:Connect(trigger)
end

local catButtons = {}

local ROWLIST_DEFAULT_POS = UDim2.new(0, 16, 0, 84)
local ROWLIST_DEFAULT_SIZE = UDim2.new(1, -32, 1, -92)
local ROWLIST_EXPANDED_POS = UDim2.new(0, 16, 0, 44)
local ROWLIST_EXPANDED_SIZE = UDim2.new(1, -32, 1, -52)

local function selectCategory(cat)
    contentHeader.Text = cat.name
    clearRows()
    closeDropdown()
    closeChangelog()

    local isESP = cat.name == "ESP"
    local isHome = cat.name == "Home"

    contentHeader.Visible = not isHome
    homePanel.Visible = isHome
    rowList.Visible = not isHome
    targetSelector.Visible = not isESP and not isHome
    valueBox.Visible = not isESP and not isHome
    espColorRow.Visible = isESP and not isHome
    rowList.Position = ROWLIST_DEFAULT_POS
    rowList.Size = ROWLIST_DEFAULT_SIZE

    if not isHome then
        for i, data in ipairs(cat.commands) do
            buildRow(data[1], data[2], data[3], i)
        end
    end
    for _, entry in ipairs(catButtons) do
        local isActive = entry.cat == cat
        entry.button.BackgroundColor3 = isActive and COLOR_CAT_ACTIVE or COLOR_SIDEBAR
        entry.label.TextColor3 = isActive and COLOR_TEXT or COLOR_SUBTEXT
    end
end

local CATEGORY_BTN_HEIGHT = isMobile and 40 or 32

for i, cat in ipairs(CATEGORIES) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, CATEGORY_BTN_HEIGHT)
    btn.LayoutOrder = i
    btn.BackgroundColor3 = COLOR_SIDEBAR
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = catList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = FONT
    lbl.TextSize = isMobile and 14 or 13
    lbl.TextColor3 = COLOR_SUBTEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = cat.name
    lbl.Parent = btn

    table.insert(catButtons, {cat = cat, button = btn, label = lbl})
    btn.MouseButton1Click:Connect(function() selectCategory(cat) end)
end

selectCategory(CATEGORIES[1])

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = searchBox.Text:lower()
    if q == "" then return end
    clearRows()
    closeDropdown()
    closeChangelog()
    contentHeader.Visible = true
    homePanel.Visible = false
    rowList.Visible = true
    targetSelector.Visible = true
    valueBox.Visible = true
    espColorRow.Visible = false
    rowList.Position = ROWLIST_DEFAULT_POS
    rowList.Size = ROWLIST_DEFAULT_SIZE
    local order = 0
    for _, cat in ipairs(CATEGORIES) do
        for _, data in ipairs(cat.commands) do
            if data[1]:lower():find(q, 1, true) then
                order += 1
                buildRow(data[1], data[2], data[3], order)
            end
        end
    end
    contentHeader.Text = "Search results"
end)

local function showNotification(text, duration)
    duration = duration or 6
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 340, 0, 0)
    notif.AutomaticSize = Enum.AutomaticSize.Y
    notif.Position = UDim2.new(1, -356, 0, 16)
    notif.BackgroundColor3 = COLOR_SIDEBAR
    notif.BorderSizePixel = 0
    notif.Parent = screenGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = COLOR_ACCENT
    notifStroke.Thickness = 1
    notifStroke.Parent = notif

    local notifPadding = Instance.new("UIPadding")
    notifPadding.PaddingTop = UDim.new(0, 10)
    notifPadding.PaddingBottom = UDim.new(0, 10)
    notifPadding.PaddingLeft = UDim.new(0, 12)
    notifPadding.PaddingRight = UDim.new(0, 12)
    notifPadding.Parent = notif

    local notifLabel = Instance.new("TextLabel")
    notifLabel.Size = UDim2.new(1, 0, 0, 0)
    notifLabel.AutomaticSize = Enum.AutomaticSize.Y
    notifLabel.BackgroundTransparency = 1
    notifLabel.Font = FONT
    notifLabel.TextSize = 13
    notifLabel.TextColor3 = COLOR_TEXT
    notifLabel.TextWrapped = true
    notifLabel.TextXAlignment = Enum.TextXAlignment.Left
    notifLabel.Text = text
    notifLabel.Parent = notif

    notif.BackgroundTransparency = 1
    notifLabel.TextTransparency = 1
    notifStroke.Transparency = 1
    TweenService:Create(notif, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
    TweenService:Create(notifStroke, TweenInfo.new(0.25), {Transparency = 0.2}):Play()
    TweenService:Create(notifLabel, TweenInfo.new(0.25), {TextTransparency = 0}):Play()

    task.delay(duration, function()
        TweenService:Create(notif, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(notifStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
        TweenService:Create(notifLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.wait(0.4)
        notif:Destroy()
    end)
end

showNotification(
    "Hello! Welcome to k3wlgui!1!11! Please remember that this script is still "
        .. "in the works and could be exposed to some anti-cheats.",
    6
)

local isOpen = false
local function setOpen(open)
    isOpen = open
    main.Visible = open
    if not open then closeDropdown() end
end

toggleButton.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
closeButton.MouseButton1Click:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        setOpen(not isOpen)
    end
end)
