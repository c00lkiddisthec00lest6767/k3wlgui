local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getScreenSize()
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local MIN_WIDTH, MIN_HEIGHT, DEFAULT_WIDTH, DEFAULT_HEIGHT
if isMobile then
	MIN_WIDTH, MIN_HEIGHT = 300, 340
else
	MIN_WIDTH, MIN_HEIGHT = 460, 320
	DEFAULT_WIDTH, DEFAULT_HEIGHT = 760, 560
end

local SIDEBAR_WIDTH = isMobile and 108 or 160

local function getMaxSize()
	local screen = getScreenSize()
	local margin = isMobile and 16 or 60
	local hardCapWidth = isMobile and 900 or 1400
	local hardCapHeight = isMobile and 900 or 1000
	return math.min(hardCapWidth, screen.X - margin), math.min(hardCapHeight, screen.Y - margin)
end

if isMobile then
	-- Fill almost the whole phone screen by default instead of a fixed pixel size,
	-- so it looks right no matter what device this is played on.
	local maxW, maxH = getMaxSize()
	DEFAULT_WIDTH = maxW
	DEFAULT_HEIGHT = maxH
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

-- ============================================================
-- COMMAND CATEGORIES (self-only — no targeting, no remotes)
-- ============================================================

local BASE_CATEGORIES = {
	{
		name = "Main",
		commands = {
			{"God", "god", false},
			{"Ungod", "ungod", false},
			{"Heal", "heal", false},
			{"Max Health", "maxhealth", false},
			{"Anchor", "anchor", false},
			{"Unanchor", "unanchor", false},
			{"Respawn", "respawn", false},
		},
	},
	{
		name = "Movement",
		commands = {
			{"Speed", "speed", false},
			{"Jump Power", "jumppower", false},
			{"Superjump", "superjump", false},
			{"Fly", "fly", false},
			{"Unfly", "unfly", false},
			{"Noclip", "noclip", false},
			{"Unnoclip", "unnoclip", false},
			{"Walk On Water", "walkonwater", false},
		},
	},
	{
		name = "Fun",
		commands = {
			{"Bighead", "bighead", false},
			{"Tiny", "tiny", false},
			{"Giant", "giant", false},
			{"Dance", "dance", false},
			{"Spin", "spin", false},
			{"Wave", "wave", false},
			{"Point", "point", false},
			{"Laugh", "laugh", false},
			{"Salute", "salute", false},
			{"Sit", "sit", false},
			{"Ragdoll", "ragdoll", false},
			{"Nolimbs", "nolimbs", false},
			{"Rainbow", "rainbow", false},
			{"Glow", "glow", false},
			{"Sparkles", "sparkles", false},
			{"Confetti", "confetti", false},
			{"Zombie Walk", "zombie", false},
		},
	},
	{
		name = "Troll",
		commands = {
			{"Blackout Screen", "blackout", false},
			{"Screen Flash", "flash", false},
			{"Screen Shake", "screenshake", false},
			{"Upside Down Cam", "upsidedown", false},
			{"Drunk Cam", "drunk", false},
			{"Fake Error", "fakeerror", false},
			{"Fake Kick", "fakekick", false},
			{"Chat Spam (local)", "chatspam", false},
		},
	},
	{
		name = "Visuals",
		commands = {
			{"Invisible", "invisible", false},
			{"Visible", "visible", false},
			{"Neon", "neon", false},
			{"Trail", "trail", false},
			{"Cape", "cape", false},
			{"Remove Accessories", "clearaccessories", false},
		},
	},
	{
		name = "ESP",
		commands = {
			{"Toggle Self ESP Marker", "esp_toggle", false},
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

-- ============================================================
-- LOCAL COMMAND IMPLEMENTATIONS (self only, all client-side)
-- ============================================================

local function getChar()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return char, hum, hrp
end

local flying = false
local flyBV, flyBG
local FLY_BIND_NAME = "k3wlFlyStep"

local function stopFly()
	flying = false
	pcall(function() RunService:UnbindFromRenderStep(FLY_BIND_NAME) end)
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		hum.AutoRotate = true
	end
end

local noclipConn
local function stopNoclip()
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end

local function resetCamera()
	camera.CFrame = camera.CFrame -- no-op placeholder, real reset below
end

local blackoutFrame, flashFrame, chatFrame

local function ensureEffectGui()
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	local gui = pg:FindFirstChild("k3wlgui_Effects")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "k3wlgui_Effects"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 50
		gui.Parent = pg
	end
	return gui
end

local Commands = {}

Commands["god"] = function()
	local _, hum = getChar()
	if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
end

Commands["ungod"] = function()
	local _, hum = getChar()
	if hum then hum.MaxHealth = 100; hum.Health = 100 end
end

Commands["heal"] = function()
	local _, hum = getChar()
	if hum then hum.Health = hum.MaxHealth end
end

Commands["maxhealth"] = function(value)
	local _, hum = getChar()
	local n = tonumber(value)
	if hum and n then hum.MaxHealth = n; hum.Health = n end
end

Commands["anchor"] = function()
	local _, _, hrp = getChar()
	if hrp then hrp.Anchored = true end
end

Commands["unanchor"] = function()
	local _, _, hrp = getChar()
	if hrp then hrp.Anchored = false end
end

Commands["respawn"] = function()
	LocalPlayer:LoadCharacter()
end

Commands["speed"] = function(value)
	local _, hum = getChar()
	local n = tonumber(value) or 16
	if hum then hum.WalkSpeed = n end
end

Commands["jumppower"] = function(value)
	local _, hum = getChar()
	local n = tonumber(value) or 50
	if hum then hum.UseJumpPower = true; hum.JumpPower = n end
end

Commands["superjump"] = function()
	local _, hum = getChar()
	if hum then hum.UseJumpPower = true; hum.JumpPower = 120 end
end

local FLY_SPEED = 60

Commands["fly"] = function()
	local char, hum, hrp = getChar()
	if not hrp or not hum then return end
	stopFly()
	flying = true
	hum.PlatformStand = true
	hum.AutoRotate = false
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)

	flyBG = Instance.new("BodyGyro")
	flyBG.P = 3e4
	flyBG.D = 500
	flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	flyBG.CFrame = camera.CFrame
	flyBG.Parent = hrp

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	flyBV.Velocity = Vector3.new(0, 0, 0)
	flyBV.Parent = hrp

	RunService:BindToRenderStep(FLY_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		if not flying or not hrp.Parent then
			stopFly()
			return
		end

		local camCFrame = camera.CFrame
		flyBG.CFrame = camCFrame

		-- Pure camera-relative movement: looking up while moving forward flies you up.
		local moveVector = Vector3.new(0, 0, 0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += camCFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= camCFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= camCFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += camCFrame.RightVector end

		if moveVector.Magnitude > 0 then
			flyBV.Velocity = moveVector.Unit * FLY_SPEED
		else
			flyBV.Velocity = Vector3.new(0, 0, 0)
		end
	end)
end

Commands["unfly"] = function()
	stopFly()
end

Commands["noclip"] = function()
	stopNoclip()
	noclipConn = RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

Commands["unnoclip"] = function()
	stopNoclip()
	local char = LocalPlayer.Character
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = true
			end
		end
	end
end

Commands["walkonwater"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if hrp:FindFirstChild("k3wl_WaterWalk") then return end
	local conn
	conn = RunService.Stepped:Connect(function()
		if not hrp.Parent then conn:Disconnect(); return end
		local rayOrigin = hrp.Position
		local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -5, 0))
		if rayResult and rayResult.Material == Enum.Material.Water then
			hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
		end
	end)
	local marker = Instance.new("BoolValue")
	marker.Name = "k3wl_WaterWalk"
	marker.Parent = hrp
end

Commands["bighead"] = function()
	local char = LocalPlayer.Character
	local head = char and char:FindFirstChild("Head")
	if head then
		local mesh = head:FindFirstChildOfClass("SpecialMesh")
		if not mesh then
			mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Parent = head
		end
		mesh.Scale = Vector3.new(2.5, 2.5, 2.5)
	end
end

local function scaleCharacter(factor)
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local ok = pcall(function()
		hum:GetAttribute("BodyDepthScale")
	end)
	for _, scaleName in ipairs({"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}) do
		local v = hum:FindFirstChild(scaleName)
		if v then v.Value = factor end
	end
end

Commands["tiny"] = function() scaleCharacter(0.5) end
Commands["giant"] = function() scaleCharacter(2) end

Commands["dance"] = function()
	local char, hum = getChar()
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://507771019"
	local track = hum:LoadAnimation(anim)
	track:Play()
	task.delay(6, function() track:Stop() end)
end

Commands["wave"] = function()
	local char, hum = getChar()
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://507770239"
	local track = hum:LoadAnimation(anim)
	track:Play()
end

Commands["point"] = function()
	local char, hum = getChar()
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://507770453"
	local track = hum:LoadAnimation(anim)
	track:Play()
end

Commands["laugh"] = function()
	local char, hum = getChar()
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://507770818"
	local track = hum:LoadAnimation(anim)
	track:Play()
end

Commands["salute"] = function()
	local char, hum = getChar()
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://507771019"
	local track = hum:LoadAnimation(anim)
	track:Play()
end

Commands["spin"] = function()
	local char, hum, hrp = getChar()
	if not hrp then return end
	task.spawn(function()
		for i = 1, 36 do
			if not hrp.Parent then break end
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(10), 0)
			task.wait(0.02)
		end
	end)
end

Commands["sit"] = function()
	local _, hum = getChar()
	if hum then hum.Sit = true end
end

Commands["ragdoll"] = function()
	local _, hum = getChar()
	if hum then hum.PlatformStand = true end
	task.delay(3, function()
		local _, hum2 = getChar()
		if hum2 then hum2.PlatformStand = false end
	end)
end

Commands["nolimbs"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and (part.Name:find("Arm") or part.Name:find("Leg")) then
			part.Transparency = 1
		end
	end
end

local rainbowConn
Commands["rainbow"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	if rainbowConn then rainbowConn:Disconnect() end
	local hue = 0
	rainbowConn = RunService.Heartbeat:Connect(function(dt)
		hue = (hue + dt * 0.3) % 1
		local color = Color3.fromHSV(hue, 1, 1)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.Color = color end
		end
	end)
end

Commands["glow"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	local existing = char:FindFirstChild("k3wl_Glow")
	if existing then existing:Destroy() end
	local light = Instance.new("PointLight")
	light.Name = "k3wl_Glow"
	light.Brightness = 5
	light.Range = 12
	light.Color = COLOR_ACCENT
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then light.Parent = hrp end
end

Commands["sparkles"] = function()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local existing = hrp:FindFirstChild("k3wl_Sparkles")
	if existing then existing:Destroy() end
	local sparkles = Instance.new("Sparkles")
	sparkles.Name = "k3wl_Sparkles"
	sparkles.Parent = hrp
end

Commands["confetti"] = function()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local emitter = Instance.new("Part")
	emitter.Size = Vector3.new(1, 1, 1)
	emitter.Transparency = 1
	emitter.CanCollide = false
	emitter.Anchored = false
	emitter.CFrame = hrp.CFrame
	emitter.Parent = workspace
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = emitter
	weld.Part1 = hrp
	weld.Parent = emitter
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 80
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Speed = NumberRange.new(5, 10)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = emitter
	Debris:AddItem(emitter, 3)
end

Commands["zombie"] = function()
	local char, hum = getChar()
	if not hum then return end
	hum.WalkSpeed = 8
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://507766388"
	local ok, track = pcall(function() return hum:LoadAnimation(anim) end)
	if ok and track then track:Play() end
end

-- Troll (screen/local only)

Commands["blackout"] = function()
	local gui = ensureEffectGui()
	if blackoutFrame then blackoutFrame:Destroy() end
	blackoutFrame = Instance.new("Frame")
	blackoutFrame.Size = UDim2.new(1, 0, 1, 0)
	blackoutFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	blackoutFrame.ZIndex = 100
	blackoutFrame.Parent = gui
	task.delay(4, function()
		if blackoutFrame then blackoutFrame:Destroy(); blackoutFrame = nil end
	end)
end

Commands["flash"] = function()
	local gui = ensureEffectGui()
	flashFrame = Instance.new("Frame")
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	flashFrame.ZIndex = 100
	flashFrame.Parent = gui
	TweenService:Create(flashFrame, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(flashFrame, 0.7)
end

local shakeConn
Commands["screenshake"] = function()
	if shakeConn then shakeConn:Disconnect() end
	local t = 0
	shakeConn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		if t > 2 then
			shakeConn:Disconnect()
			return
		end
		camera.CFrame = camera.CFrame * CFrame.new(
			math.random(-20, 20) / 100,
			math.random(-20, 20) / 100,
			0
		)
	end)
end

Commands["upsidedown"] = function()
	camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(180))
	task.delay(3, function()
		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(180))
	end)
end

Commands["drunk"] = function()
	task.spawn(function()
		local t = 0
		while t < 5 do
			t += 0.03
			camera.CFrame = camera.CFrame * CFrame.Angles(math.sin(t * 3) * 0.02, math.cos(t * 2) * 0.02, 0)
			task.wait(0.03)
		end
	end)
end

Commands["fakeerror"] = function()
	local gui = ensureEffectGui()
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 320, 0, 120)
	box.Position = UDim2.new(0.5, -160, 0.5, -60)
	box.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	box.ZIndex = 200
	box.Parent = gui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -50)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = "Roblox has encountered an error and needs to close.\n(ID: 0x00k3wl)"
	label.TextWrapped = true
	label.Font = Enum.Font.SourceSans
	label.TextSize = 14
	label.TextColor3 = Color3.new(0, 0, 0)
	label.ZIndex = 200
	label.Parent = box
	local ok = Instance.new("TextButton")
	ok.Size = UDim2.new(0, 80, 0, 28)
	ok.Position = UDim2.new(0.5, -40, 1, -40)
	ok.Text = "OK"
	ok.ZIndex = 200
	ok.Parent = box
	ok.MouseButton1Click:Connect(function() box:Destroy() end)
end

Commands["fakekick"] = function()
	local gui = ensureEffectGui()
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 1, 0)
	box.BackgroundColor3 = Color3.new(0, 0, 0)
	box.ZIndex = 200
	box.Parent = gui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 40)
	label.Position = UDim2.new(0, 0, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Text = "You have been kicked: (fake) Exploiting"
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 22
	label.TextColor3 = Color3.new(1, 1, 1)
	label.ZIndex = 200
	label.Parent = box
	task.delay(4, function() box:Destroy() end)
end

Commands["chatspam"] = function()
	local StarterGui = game:GetService("StarterGui")
	for i = 1, 5 do
		task.delay(i * 0.3, function()
			pcall(function()
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = "k3wlgui says hi #" .. i,
					Color = COLOR_ACCENT,
				})
			end)
		end)
	end
end

-- Visuals

Commands["invisible"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.Transparency = 1
		end
	end
end

Commands["visible"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 0
		end
	end
end

Commands["neon"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Material = Enum.Material.Neon
		end
	end
end

Commands["trail"] = function()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if hrp:FindFirstChild("k3wl_Trail") then return end
	local a0 = Instance.new("Attachment", hrp)
	a0.Position = Vector3.new(0, 1, 0)
	local a1 = Instance.new("Attachment", hrp)
	a1.Position = Vector3.new(0, -1, 0)
	local trail = Instance.new("Trail")
	trail.Name = "k3wl_Trail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(COLOR_ACCENT)
	trail.Lifetime = 1
	trail.Parent = hrp
end

Commands["cape"] = function()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if hrp:FindFirstChild("k3wl_Cape") then return end
	local cape = Instance.new("Part")
	cape.Name = "k3wl_Cape"
	cape.Size = Vector3.new(1.8, 2.2, 0.2)
	cape.Color = Color3.fromRGB(120, 20, 20)
	cape.Material = Enum.Material.Fabric
	cape.CanCollide = false
	cape.CFrame = hrp.CFrame * CFrame.new(0, -0.3, 0.9)
	cape.Parent = char
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = cape
	weld.C0 = CFrame.new(0, -0.3, 0.9)
	weld.Parent = cape
end

Commands["clearaccessories"] = function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") then item:Destroy() end
	end
end

-- ESP (self marker, cosmetic only — just shows a marker above your own head)

local espEnabled = false
local espBillboard

local function enableESP()
	local char, _, hrp = getChar()
	if not hrp then return end
	if espBillboard then espBillboard:Destroy() end
	espBillboard = Instance.new("BillboardGui")
	espBillboard.Name = "k3wl_SelfESP"
	espBillboard.Adornee = hrp
	espBillboard.Size = UDim2.new(0, 120, 0, 24)
	espBillboard.StudsOffset = Vector3.new(0, 3, 0)
	espBillboard.AlwaysOnTop = true
	espBillboard.Parent = hrp
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = FONT_BOLD
	label.TextSize = 14
	label.TextColor3 = COLOR_ACCENT
	label.TextStrokeTransparency = 0
	label.Text = LocalPlayer.Name
	label.Parent = espBillboard
	espEnabled = true
end

local function disableESP()
	if espBillboard then espBillboard:Destroy(); espBillboard = nil end
	espEnabled = false
end

Commands["esp_toggle"] = function()
	if espEnabled then disableESP() else enableESP() end
end

-- ============================================================
-- GUI (same look as before, target selector removed)
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "k3wlgui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local showNotification -- forward declared; defined below, used by runCommand above it

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
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, titleBtnSize, 0, titleBtnSize)
closeButton.Position = UDim2.new(1, -(8 + titleBtnSize), 0.5, -titleBtnSize / 2)
closeButton.BackgroundColor3 = COLOR_ROW
closeButton.Text = "X"
closeButton.Font = FONT_BOLD
closeButton.TextSize = isMobile and 17 or 13
closeButton.TextColor3 = COLOR_SUBTEXT
closeButton.AutoButtonColor = false
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

do
	local dragging, dragStart, startAbsPos, startScale = false, nil, nil, nil
	titleBar.InputBegan:Connect(function(input)
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

local resizeHandleSize = isMobile and 44 or 26

local function createResizeHandle(anchor)
	-- anchor: "bottom-right", "top-left", "top-right"
	local handle = Instance.new("TextButton")
	handle.Size = UDim2.new(0, resizeHandleSize, 0, resizeHandleSize)
	if anchor == "bottom-right" then
		handle.Position = UDim2.new(1, -resizeHandleSize, 1, -resizeHandleSize)
	elseif anchor == "top-left" then
		handle.Position = UDim2.new(0, 0, 0, 0)
	elseif anchor == "top-right" then
		handle.Position = UDim2.new(1, -resizeHandleSize, 0, 0)
	end
	handle.BackgroundColor3 = COLOR_ROW
	handle.BackgroundTransparency = 0.5
	handle.BorderSizePixel = 0
	handle.Text = ""
	handle.AutoButtonColor = false
	handle.ZIndex = 50
	handle.Parent = main
	Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 6)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "⋰"
	icon.Font = FONT_BOLD
	icon.TextSize = isMobile and 22 or 18
	icon.TextColor3 = COLOR_ACCENT
	icon.Rotation = (anchor == "top-right") and 0 or 90
	icon.ZIndex = 50
	icon.Parent = handle

	local resizing, resizeStart, startSize, startPos = false, nil, nil, nil

	local function beginResize(input)
		resizing = true
		resizeStart = input.Position
		startSize = main.Size
		startPos = main.Position
		handle.BackgroundTransparency = 0.1
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
				handle.BackgroundTransparency = 0.5
			end
		end)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginResize(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStart
			local maxW, maxH = getMaxSize()
			local screen = getScreenSize()

			if anchor == "bottom-right" then
				local newWidth = math.clamp(startSize.X.Offset + delta.X, MIN_WIDTH, maxW)
				local newHeight = math.clamp(startSize.Y.Offset + delta.Y, MIN_HEIGHT, maxH)
				main.Size = UDim2.new(0, newWidth, 0, newHeight)
			elseif anchor == "top-left" then
				local newWidth = math.clamp(startSize.X.Offset - delta.X, MIN_WIDTH, maxW)
				local newHeight = math.clamp(startSize.Y.Offset - delta.Y, MIN_HEIGHT, maxH)
				local widthChange = newWidth - startSize.X.Offset
				local heightChange = newHeight - startSize.Y.Offset
				local newAbsX = (startPos.X.Scale * screen.X + startPos.X.Offset) - widthChange
				local newAbsY = (startPos.Y.Scale * screen.Y + startPos.Y.Offset) - heightChange
				main.Size = UDim2.new(0, newWidth, 0, newHeight)
				main.Position = UDim2.new(0, newAbsX, 0, newAbsY)
			elseif anchor == "top-right" then
				local newWidth = math.clamp(startSize.X.Offset + delta.X, MIN_WIDTH, maxW)
				local newHeight = math.clamp(startSize.Y.Offset - delta.Y, MIN_HEIGHT, maxH)
				local heightChange = newHeight - startSize.Y.Offset
				local newAbsY = (startPos.Y.Scale * screen.Y + startPos.Y.Offset) - heightChange
				main.Size = UDim2.new(0, newWidth, 0, newHeight)
				main.Position = UDim2.new(0, startPos.X.Scale * screen.X + startPos.X.Offset, 0, newAbsY)
			end
		end
	end)

	return handle
end

createResizeHandle("bottom-right")
createResizeHandle("top-left")
createResizeHandle("top-right")

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -40)
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

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -16, 1, 0)
searchBox.Position = UDim2.new(0, 8, 0, 0)
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

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -40)
content.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 40)
content.BackgroundColor3 = COLOR_BG
content.BorderSizePixel = 0
content.Parent = main

local contentHeader = Instance.new("TextLabel")
contentHeader.Size = UDim2.new(1, -32, 0, 30)
contentHeader.Position = UDim2.new(0, 16, 0, 12)
contentHeader.BackgroundTransparency = 1
contentHeader.Font = FONT_BOLD
contentHeader.TextSize = 16
contentHeader.TextColor3 = COLOR_TEXT
contentHeader.TextXAlignment = Enum.TextXAlignment.Left
contentHeader.Text = "Main"
contentHeader.Parent = content

local valueBox = Instance.new("TextBox")
valueBox.Size = UDim2.new(1, -32, 0, 30)
valueBox.Position = UDim2.new(0, 16, 0, 44)
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

local function getCurrentValue()
	local rawValue = valueBox.Text
	return rawValue ~= "" and rawValue or nil
end

-- ============================================================
-- Home page + Update Log (restored)
-- ============================================================

local CHANGELOG = {
	{
		version = "v1.0.0",
		tag = "BETA",
		title = "Self-Only Release",
		sections = {
			{
				header = "🎉 New Features",
				items = {
					"Launched k3wlgui — a full command panel with categories and 40+ self commands",
					"Added a self ESP marker toggle",
					"Added a value box for commands that need a number, like Speed",
				},
			},
			{
				header = "🛠️ Improvements",
				items = {
					"Added full window controls: drag, resize, and close",
					"Added a new \"All\" tab combining every command from every category into one list",
					"Added a search bar to quickly filter commands by name",
					"Reworked Fly to move relative to your camera — look up to go up",
					"Restored toast notifications for command feedback",
				},
			},
			{
				header = "🎨 Visual Changes",
				items = {
					"Dark maroon visual theme across the whole panel",
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
homeVersionTag.Size = UDim2.new(0, 40, 1, 0)
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
homeTagline.Text = "Your all-in-one self command panel — customization, movement, and pranks, all in one place."
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
changelogPanel.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -40)
changelogPanel.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 40)
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
		versionText.Size = UDim2.new(0, 160, 1, 0)
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

local function runCommand(commandName, label)
	local fn = Commands[commandName]
	if not fn then
		setStatus("Not implemented: " .. commandName, true)
		return
	end
	local ok, err = pcall(fn, getCurrentValue())
	if ok then
		setStatus("Ran '" .. label .. "'", false)
		showNotification("Ran: " .. label, 2)
	else
		setStatus("Error running '" .. label .. "'", true)
		showNotification("Error running: " .. label, 3)
		warn(err)
	end
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
		runCommand(commandName, label)
	end

	runButton.MouseButton1Click:Connect(trigger)
	hitbox.MouseButton1Click:Connect(trigger)
end

local catButtons = {}

local function selectCategory(cat)
	contentHeader.Text = cat.name
	clearRows()
	closeChangelog()

	local isHome = cat.name == "Home"
	contentHeader.Visible = not isHome
	rowList.Visible = not isHome
	valueBox.Visible = not isHome
	homePanel.Visible = isHome

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
	closeChangelog()
	homePanel.Visible = false
	contentHeader.Visible = true
	rowList.Visible = true
	valueBox.Visible = true
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

LocalPlayer.CharacterAdded:Connect(function()
	stopFly()
	stopNoclip()
end)

function showNotification(text, duration)
	duration = duration or 6
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 320, 0, 0)
	notif.AutomaticSize = Enum.AutomaticSize.Y
	notif.Position = UDim2.new(1, -336, 0, 16)
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

showNotification("Hello! Welcome to k3wlgui!1!11! Self-only mode — commands act on yourself.", 6)

local isOpen = false
local function setOpen(open)
	isOpen = open
	main.Visible = open
end

toggleButton.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
closeButton.MouseButton1Click:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightAlt then
		setOpen(not isOpen)
	end
end)
