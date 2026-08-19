local Players = game:GetService("Players")

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Save the position where the player first spawned
local startingCFrame = humanoidRootPart.CFrame

local MAX_LOOPS = 10
local WAIT_TIME = 0.5

-- Find a prompt with "Steal" in its ActionText
local function findStealPrompt()
	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("ProximityPrompt") then
			local actionText = string.lower(object.ActionText or "")

			if string.find(actionText, "steal") then
				return object
			end
		end
	end

	return nil
end

for i = 1, MAX_LOOPS do
	-- Make sure the character still exists
	character = player.Character or player.CharacterAdded:Wait()
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Find the Steal prompt
	local prompt = findStealPrompt()

	if not prompt then
		warn("No Steal prompt found!")
		break
	end

	-- Teleport directly to the prompt
	humanoidRootPart.CFrame =
		prompt.Parent.CFrame + Vector3.new(0, 2, 0)

	task.wait()

	-- Instantly activate the ProximityPrompt
	prompt:InputHoldBegin()
	prompt:InputHoldEnd()

	-- Wait half a second
	task.wait(WAIT_TIME)

	-- Teleport back to the original position
	humanoidRootPart.CFrame = startingCFrame

	-- Small delay before the next cycle
	task.wait(0.1)
end

-- Finished all 10 attempts
task.wait(0.2)
player:Kick("Finished!")
