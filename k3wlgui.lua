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
			{"Toggle ESP", "esp_toggle", false},
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

-- Some games continuously re-apply stats (WalkSpeed, Health, etc.) from their
-- own systems every frame, silently overwriting a one-time change. These
-- helpers keep re-asserting a value every heartbeat so our change sticks.
local enforcedLoops = {}

local function enforce(key, applyFn)
	if enforcedLoops[key] then enforcedLoops[key]:Disconnect() end
	enforcedLoops[key] = RunService.Heartbeat:Connect(function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			local ok = pcall(applyFn, hum)
			if not ok then end
		end
	end)
end

local function stopEnforcing(key)
	if enforcedLoops[key] then
		enforcedLoops[key]:Disconnect()
		enforcedLoops[key] = nil
	end
end

Commands["god"] = function()
	enforce("god", function(hum)
		hum.MaxHealth = math.huge
		hum.Health = math.huge
	end)
end

Commands["ungod"] = function()
	stopEnforcing("god")
	local _, hum = getChar()
	if hum then hum.MaxHealth = 100; hum.Health = 100 end
end

Commands["heal"] = function()
	local _, hum = getChar()
	if hum then hum.Health = hum.MaxHealth end
end

Commands["maxhealth"] = function(value)
	local n = tonumber(value)
	if not n then return end
	enforce("maxhealth", function(hum)
		hum.MaxHealth = n
		if hum.Health > n then hum.Health = n end
	end)
	local _, hum = getChar()
	if hum then hum.Health = n end
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
	local n = tonumber(value) or 16
	enforce("speed", function(hum)
		hum.WalkSpeed = n
	end)
end

Commands["jumppower"] = function(value)
	local n = tonumber(value) or 50
	enforce("jumppower", function(hum)
		hum.UseJumpPower = true
		hum.JumpPower = n
	end)
end

Commands["superjump"] = function()
	enforce("jumppower", function(hum)
		hum.UseJumpPower = true
		hum.JumpPower = 120
	end)
end

local FLY_SPEED = 60

Commands["fly"] = function()
	local char, hum, hrp = getChar()
	if not hrp or not hum then return end
	stopFly()
	flying = true
	-- Deliberately NOT touching PlatformStand/AutoRotate here: on mobile,
	-- PlatformStand can disable the default touch joystick's input entirely,
	-- which was why fly didn't respond to phone controls. Overpowering
	-- gravity/movement with a strong BodyVelocity instead keeps normal
	-- input (keyboard, touch joystick, gamepad) fully working.

	flyBG = Instance.new("BodyGyro")
	flyBG.P = 9e4
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

		-- hum.MoveDirection works cross-platform: keyboard WASD, mobile touch joystick,
		-- and gamepad thumbsticks all feed into it, unlike raw keyboard key checks.
		local moveDir = hum.MoveDirection
		local moveVector = Vector3.new(0, 0, 0)

		if moveDir.Magnitude > 0.05 then
			local camFlatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
			if camFlatLook.Magnitude > 0 then camFlatLook = camFlatLook.Unit end
			local camFlatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)
			if camFlatRight.Magnitude > 0 then camFlatRight = camFlatRight.Unit end

			local forwardAmount = moveDir:Dot(camFlatLook)
			local rightAmount = moveDir:Dot(camFlatRight)

			-- Use the FULL camera vectors (including vertical tilt) so looking up
			-- while moving forward flies you up, and looking down flies you down.
			moveVector = (camCFrame.LookVector * forwardAmount) + (camCFrame.RightVector * rightAmount)
		end

		-- Keyboard WASD also still works as a direct fallback/addition on PC.
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
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CanCollide = false
		end
	end)
end

Commands["unnoclip"] = function()
	stopNoclip()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CanCollide = true
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
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
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
	anim.AnimationId = "rbxassetid://507770677"
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

-- ESP (highlights + name/health/distance for every player — purely read-only,
-- so no server script is needed: this just displays data that already
-- replicates to your client normally, like everyone's health and position.)

local espEnabled = false
local espData = {}
local espHighlightColor = Color3.fromRGB(255, 0, 0)
local espHeartbeat

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
	highlight.Name = "k3wl_ESPHighlight"
	highlight.FillColor = espHighlightColor
	highlight.OutlineColor = espHighlightColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "k3wl_ESP"
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
	nameLabel.TextColor3 = espHighlightColor
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

local function setEspHighlightColor(color)
	espHighlightColor = color
	for _, data in pairs(espData) do
		if data.highlight then
			data.highlight.FillColor = color
			data.highlight.OutlineColor = color
		end
		if data.nameLabel then
			data.nameLabel.TextColor3 = color
		end
	end
end

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
end

Commands["esp_toggle"] = function()
	if espEnabled then disableESP() else enableESP() end
end

Players.PlayerAdded:Connect(function(p)
	if espEnabled then setupESPTracking(p) end
end)

Players.PlayerRemoving:Connect(function(p)
	destroyESPFor(p)
end)

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

titleBar.ZIndex = 60

local titleBtnSize = isMobile and 34 or 26
local titleBtnGap = isMobile and 8 or 6

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, titleBtnSize, 0, titleBtnSize)
closeButton.Position = UDim2.new(1, -(8 + titleBtnSize), 0.5, -titleBtnSize / 2)
closeButton.BackgroundColor3 = COLOR_ROW
closeButton.Text = "X"
closeButton.Font = FONT_BOLD
closeButton.TextSize = isMobile and 17 or 13
closeButton.TextColor3 = COLOR_SUBTEXT
closeButton.AutoButtonColor = false
closeButton.ZIndex = 60
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, titleBtnSize, 0, titleBtnSize)
minimizeButton.Position = UDim2.new(1, -(8 + titleBtnSize + titleBtnGap + titleBtnSize), 0.5, -titleBtnSize / 2)
minimizeButton.BackgroundColor3 = COLOR_ROW
minimizeButton.Text = "–"
minimizeButton.Font = FONT_BOLD
minimizeButton.TextSize = isMobile and 20 or 15
minimizeButton.TextColor3 = COLOR_SUBTEXT
minimizeButton.AutoButtonColor = false
minimizeButton.ZIndex = 60
minimizeButton.Parent = titleBar
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 6)

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
catLayout.Padding = UDim.new(0, isMobile and 8 or 5)
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
	local swatchName, swatchColor = data[1], data[2]

	local swatch = Instance.new("TextButton")
	swatch.Size = UDim2.new(0, 22, 0, 22)
	swatch.LayoutOrder = i
	swatch.BackgroundColor3 = swatchColor
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
		setEspHighlightColor(swatchColor)
		refreshSwatchSelection()
	end)

	table.insert(espSwatchButtons, {color = swatchColor, stroke = swatchStroke})
end

refreshSwatchSelection()

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

local homePanel = Instance.new("ScrollingFrame")
homePanel.Size = UDim2.new(1, -32, 1, -24)
homePanel.Position = UDim2.new(0, 16, 0, 12)
homePanel.BackgroundTransparency = 1
homePanel.BorderSizePixel = 0
homePanel.ScrollBarThickness = 4
homePanel.ScrollBarImageColor3 = COLOR_ACCENT
homePanel.CanvasSize = UDim2.new(0, 0, 0, 0)
homePanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
homePanel.Visible = false
homePanel.Parent = content

local homeLayout = Instance.new("UIListLayout")
homeLayout.SortOrder = Enum.SortOrder.LayoutOrder
homeLayout.Padding = UDim.new(0, 14)
homeLayout.Parent = homePanel

-- Header: icon badge + title/subtitle + version/BETA pills
local homeHeader = Instance.new("Frame")
homeHeader.Size = UDim2.new(1, 0, 0, 56)
homeHeader.BackgroundTransparency = 1
homeHeader.LayoutOrder = 1
homeHeader.Parent = homePanel

local homeIcon = Instance.new("TextLabel")
homeIcon.Size = UDim2.new(0, 56, 0, 56)
homeIcon.BackgroundColor3 = COLOR_ACCENT
homeIcon.Font = FONT_BOLD
homeIcon.TextSize = 24
homeIcon.TextColor3 = COLOR_TEXT
homeIcon.Text = "k"
homeIcon.Parent = homeHeader
Instance.new("UICorner", homeIcon).CornerRadius = UDim.new(0, 14)

local homeTitle = Instance.new("TextLabel")
homeTitle.Size = UDim2.new(1, -68, 0, 26)
homeTitle.Position = UDim2.new(0, 68, 0, 0)
homeTitle.BackgroundTransparency = 1
homeTitle.Font = FONT_BOLD
homeTitle.TextSize = 22
homeTitle.TextColor3 = COLOR_TEXT
homeTitle.TextXAlignment = Enum.TextXAlignment.Left
homeTitle.Text = "k3wlgui"
homeTitle.Parent = homeHeader

local homeSubtitle = Instance.new("TextLabel")
homeSubtitle.Size = UDim2.new(1, -68, 0, 16)
homeSubtitle.Position = UDim2.new(0, 68, 0, 26)
homeSubtitle.BackgroundTransparency = 1
homeSubtitle.Font = FONT
homeSubtitle.TextSize = 12
homeSubtitle.TextColor3 = COLOR_SUBTEXT
homeSubtitle.TextXAlignment = Enum.TextXAlignment.Left
homeSubtitle.Text = "By: k3wlkid"
homeSubtitle.Parent = homeHeader

local homeBadgeRow = Instance.new("Frame")
homeBadgeRow.Size = UDim2.new(1, -68, 0, 16)
homeBadgeRow.Position = UDim2.new(0, 68, 0, 40)
homeBadgeRow.BackgroundTransparency = 1
homeBadgeRow.Parent = homeHeader

local homeBadgeLayout = Instance.new("UIListLayout")
homeBadgeLayout.FillDirection = Enum.FillDirection.Horizontal
homeBadgeLayout.Padding = UDim.new(0, 6)
homeBadgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
homeBadgeLayout.Parent = homeBadgeRow

local homeVersionTag = Instance.new("Frame")
homeVersionTag.Size = UDim2.new(0, 46, 1, 0)
homeVersionTag.BackgroundColor3 = COLOR_ROW
homeVersionTag.BorderSizePixel = 0
homeVersionTag.Parent = homeBadgeRow
Instance.new("UICorner", homeVersionTag).CornerRadius = UDim.new(0, 4)

local homeVersionTagLabel = Instance.new("TextLabel")
homeVersionTagLabel.Size = UDim2.new(1, 0, 1, 0)
homeVersionTagLabel.BackgroundTransparency = 1
homeVersionTagLabel.Font = FONT
homeVersionTagLabel.TextSize = 11
homeVersionTagLabel.TextColor3 = COLOR_SUBTEXT
homeVersionTagLabel.Text = "v1.0.0"
homeVersionTagLabel.Parent = homeVersionTag

local homeBetaTag = Instance.new("Frame")
homeBetaTag.Size = UDim2.new(0, 40, 1, 0)
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

-- Tagline
local homeTagline = Instance.new("TextLabel")
homeTagline.Size = UDim2.new(1, 0, 0, 0)
homeTagline.AutomaticSize = Enum.AutomaticSize.Y
homeTagline.BackgroundTransparency = 1
homeTagline.Font = FONT
homeTagline.TextSize = 13
homeTagline.TextColor3 = COLOR_SUBTEXT
homeTagline.TextWrapped = true
homeTagline.TextXAlignment = Enum.TextXAlignment.Left
homeTagline.LayoutOrder = 2
homeTagline.Text = "Your all-in-one self command panel — customization, movement, and pranks, all in one place."
homeTagline.Parent = homePanel

-- Stat cards
local homeStatsRow = Instance.new("Frame")
homeStatsRow.Size = UDim2.new(1, 0, 0, 64)
homeStatsRow.BackgroundTransparency = 1
homeStatsRow.LayoutOrder = 3
homeStatsRow.Parent = homePanel

local homeStatsLayout = Instance.new("UIListLayout")
homeStatsLayout.FillDirection = Enum.FillDirection.Horizontal
homeStatsLayout.Padding = UDim.new(0, 10)
homeStatsLayout.Parent = homeStatsRow

local function addStatCard(number, label)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.5, -5, 1, 0)
	card.BackgroundColor3 = COLOR_ROW
	card.BorderSizePixel = 0
	card.Parent = homeStatsRow
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local numLabel = Instance.new("TextLabel")
	numLabel.Size = UDim2.new(1, 0, 0, 30)
	numLabel.Position = UDim2.new(0, 0, 0, 8)
	numLabel.BackgroundTransparency = 1
	numLabel.Font = FONT_BOLD
	numLabel.TextSize = 22
	numLabel.TextColor3 = COLOR_ACCENT
	numLabel.Text = number
	numLabel.Parent = card

	local capLabel = Instance.new("TextLabel")
	capLabel.Size = UDim2.new(1, 0, 0, 16)
	capLabel.Position = UDim2.new(0, 0, 0, 38)
	capLabel.BackgroundTransparency = 1
	capLabel.Font = FONT
	capLabel.TextSize = 11
	capLabel.TextColor3 = COLOR_SUBTEXT
	capLabel.Text = label
	capLabel.Parent = card
end

addStatCard(tostring(#ALL_COMMANDS), "commands")
addStatCard(tostring(#BASE_CATEGORIES), "categories")

-- Quick tips card
local homeTipsCard = Instance.new("Frame")
homeTipsCard.Size = UDim2.new(1, 0, 0, 0)
homeTipsCard.AutomaticSize = Enum.AutomaticSize.Y
homeTipsCard.BackgroundColor3 = COLOR_ROW
homeTipsCard.BorderSizePixel = 0
homeTipsCard.LayoutOrder = 4
homeTipsCard.Parent = homePanel
Instance.new("UICorner", homeTipsCard).CornerRadius = UDim.new(0, 10)

local homeTipsPad = Instance.new("UIPadding")
homeTipsPad.PaddingTop = UDim.new(0, 12)
homeTipsPad.PaddingBottom = UDim.new(0, 12)
homeTipsPad.PaddingLeft = UDim.new(0, 14)
homeTipsPad.PaddingRight = UDim.new(0, 14)
homeTipsPad.Parent = homeTipsCard

local homeTipsLayout = Instance.new("UIListLayout")
homeTipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
homeTipsLayout.Padding = UDim.new(0, 6)
homeTipsLayout.Parent = homeTipsCard

local homeTipsHeader = Instance.new("TextLabel")
homeTipsHeader.Size = UDim2.new(1, 0, 0, 16)
homeTipsHeader.BackgroundTransparency = 1
homeTipsHeader.Font = FONT_BOLD
homeTipsHeader.TextSize = 12
homeTipsHeader.TextColor3 = COLOR_ACCENT
homeTipsHeader.TextXAlignment = Enum.TextXAlignment.Left
homeTipsHeader.LayoutOrder = 1
homeTipsHeader.Text = "Quick tips"
homeTipsHeader.Parent = homeTipsCard

local HOME_TIPS = {
	"Drag the title bar to move the window, or drag the K button to reposition it",
	"Resize from any corner — bottom-right, top-left, or top-right",
	"Tap – to minimize, and X to close",
	"Type in the value box before running commands like Speed or Jump Power",
	"ESP shows a color picker instead of the value box — pick any highlight color",
}

for i, tip in ipairs(HOME_TIPS) do
	local tipLabel = Instance.new("TextLabel")
	tipLabel.Size = UDim2.new(1, 0, 0, 0)
	tipLabel.AutomaticSize = Enum.AutomaticSize.Y
	tipLabel.BackgroundTransparency = 1
	tipLabel.Font = FONT
	tipLabel.TextSize = 11
	tipLabel.TextColor3 = COLOR_SUBTEXT
	tipLabel.TextWrapped = true
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.LayoutOrder = 1 + i
	tipLabel.Text = "•  " .. tip
	tipLabel.Parent = homeTipsCard
end

local updateLogButton = Instance.new("TextButton")
updateLogButton.Size = UDim2.new(1, 0, 0, 38)
updateLogButton.BackgroundColor3 = COLOR_ACCENT
updateLogButton.AutoButtonColor = false
updateLogButton.Font = FONT_BOLD
updateLogButton.TextSize = 13
updateLogButton.TextColor3 = COLOR_TEXT
updateLogButton.Text = "📜  View Update Log"
updateLogButton.LayoutOrder = 5
updateLogButton.Parent = homePanel
Instance.new("UICorner", updateLogButton).CornerRadius = UDim.new(0, 8)

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
	local isESP = cat.name == "ESP"
	contentHeader.Visible = not isHome
	rowList.Visible = not isHome
	valueBox.Visible = not isHome and not isESP
	espColorRow.Visible = isESP and not isHome
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

local CATEGORY_BTN_HEIGHT = isMobile and 52 or 36

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
	espColorRow.Visible = false
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

showNotification("Hello! Welcome to k3wlgui!1!11! Please remember that this script is still in the works and could be exposed to some anti-cheats.", 6)

local normalSize = main.Size
local isMinimized = false

local function setMinimized(minimize)
	isMinimized = minimize
	if minimize then
		normalSize = main.Size
		main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 44)
		sidebar.Visible = false
		content.Visible = false
		changelogPanel.Visible = false
		minimizeButton.Text = "▭"
	else
		main.Size = normalSize
		sidebar.Visible = true
		content.Visible = true
		minimizeButton.Text = "–"
	end
end

minimizeButton.MouseButton1Click:Connect(function()
	setMinimized(not isMinimized)
end)

local isOpen = false
local function setOpen(open)
	isOpen = open
	main.Visible = open
end

do
	local dragging, dragStart, startAbsPos, startScale, moved = false, nil, nil, nil, false
	local DRAG_THRESHOLD = 6

	toggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startAbsPos = toggleButton.AbsolutePosition
			startScale = Vector2.new(toggleButton.Position.X.Scale, toggleButton.Position.Y.Scale)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved then
						setOpen(not isOpen)
					end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > DRAG_THRESHOLD then
				moved = true
			end
			local screen = getScreenSize()
			local margin = 8
			local newAbsX = math.clamp(startAbsPos.X + delta.X, margin, screen.X - toggleButton.AbsoluteSize.X - margin)
			local newAbsY = math.clamp(startAbsPos.Y + delta.Y, margin, screen.Y - toggleButton.AbsoluteSize.Y - margin)
			local offsetX = newAbsX - startScale.X * screen.X
			local offsetY = newAbsY - startScale.Y * screen.Y
			toggleButton.Position = UDim2.new(startScale.X, offsetX, startScale.Y, offsetY)
		end
	end)
end

closeButton.MouseButton1Click:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightAlt then
		setOpen(not isOpen)
	end
end)
