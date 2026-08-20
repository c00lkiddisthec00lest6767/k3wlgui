--==================================================
-- k3wlTSB CLIENT FLING
-- GitHub-only / client-side
--==================================================

local flingActive = false
local flingConnection = nil

local MAX_FLING_HEIGHT = 150

-- Higher values = more aggressive movement
local ORBIT_RADIUS = 5
local VERTICAL_OFFSET = 2
local TELEPORT_VARIATION = 6
local SPIN_SPEED = 250
local LINEAR_SPEED = 250

local function stopFling(originalCFrame)

	flingActive = false

	if flingConnection then
		flingConnection:Disconnect()
		flingConnection = nil
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

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

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not root or not humanoid then
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
		targetCharacter:FindFirstChild(
			"HumanoidRootPart"
		)

	if not targetRoot then

		Status.Text =
			"Status: Target unavailable"

		return
	end

	-- Save your exact starting position
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

					stopFling(originalCFrame)

					return
				end

				if not root
					or not root.Parent then

					stopFling(originalCFrame)

					return
				end

				if not lockedTarget
					or not lockedTarget.Character then

					stopFling(originalCFrame)

					return
				end

				local currentTargetRoot =
					lockedTarget.Character:
					FindFirstChild(
						"HumanoidRootPart"
					)

				if not currentTargetRoot then

					stopFling(originalCFrame)

					return
				end

				--==========================================
				-- ONLY AUTOMATIC STOP CONDITION:
				-- TOO HIGH
				--==========================================

				if root.Position.Y >
					originalY
					+ MAX_FLING_HEIGHT then

					stopFling(originalCFrame)

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

				--==========================================
				-- RAPID ORBIT
				--==========================================

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

				-- Move around the target
				local newPosition =
					currentTargetRoot.Position
					+ offset

				root.CFrame =
					CFrame.new(
						newPosition
					)
					* CFrame.Angles(
						angle,
						angle * 1.7,
						angle * 2.4
					)

				-- Spin extremely quickly
				root.AssemblyAngularVelocity =
					Vector3.new(
						SPIN_SPEED,
						SPIN_SPEED * 2,
						SPIN_SPEED * 1.5
					)

				-- Give your character substantial movement
				root.AssemblyLinearVelocity =
					(
						currentTargetRoot.Position
						- root.Position
					).Unit
					* LINEAR_SPEED

			end
		)
end

FlingButton.Activated:Connect(
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
