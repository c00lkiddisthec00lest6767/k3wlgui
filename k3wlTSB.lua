--==================================================
-- FLING BUTTON
--==================================================

local FlingButton = createButton(
	"Fling",
	"FLING — Locked Player",
	UDim2.new(0, 15, 0, 215)
)

-- Make the window taller so the new button fits
Main.Size = UDim2.new(0, 320, 0, 300)
Main.Position = UDim2.new(0.5, -160, 0.5, -150)

--==================================================
-- FLING FUNCTION
--==================================================

local function flingTarget()

	if not lockedTarget then
		Status.Text = "Status: Lock onto someone first!"
		return
	end

	local character = lockedTarget.Character

	if not character then
		Status.Text = "Status: Target unavailable"
		return
	end

	local targetRoot = character:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = character:FindFirstChildOfClass("Humanoid")

	if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		Status.Text = "Status: Target unavailable"
		return
	end

	-- Strong physics impulse
	local attachment = targetRoot:FindFirstChild("k3wlFlingAttachment")

	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "k3wlFlingAttachment"
		attachment.Parent = targetRoot
	end

	local velocity = targetRoot:FindFirstChild("k3wlFlingVelocity")

	if not velocity then
		velocity = Instance.new("LinearVelocity")
		velocity.Name = "k3wlFlingVelocity"
		velocity.Attachment0 = attachment
		velocity.MaxForce = math.huge
		velocity.VectorVelocity = Vector3.new(
			math.random(-150, 150),
			200,
			math.random(-150, 150)
		)
		velocity.Parent = targetRoot
	else
		velocity.VectorVelocity = Vector3.new(
			math.random(-150, 150),
			200,
			math.random(-150, 150)
		)
	end

	Status.Text = "FLUNG: " .. lockedTarget.Name

	-- Remove the fling force after a short moment
	task.delay(0.35, function()
		if velocity and velocity.Parent then
			velocity:Destroy()
		end

		if attachment and attachment.Parent then
			attachment:Destroy()
		end

		if Status and Status.Parent and lockedTarget then
			Status.Text = "Locked: " .. lockedTarget.Name
		end
	end)
end

--==================================================
-- FLING BUTTON
--==================================================

FlingButton.Activated:Connect(function()
	flingTarget()
end)
