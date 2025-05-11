-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- SETTINGS
local aimbotEnabled = false
local noclipEnabled = false
local targetPartName = "HumanoidRootPart"
local priority = "Closest" -- "Health", "Closest", "Farthest"
local maxRange = 200
local lastVerboseTime = 0

-- VERBOSE
local function vprint(msg)
	local t = tick()
	if t - lastVerboseTime > 1 then
		print("[AIMBOT] " .. msg)
		lastVerboseTime = t
	end
end

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 320, 0, 280)
mainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- Tabs Buttons
local tabs = { "Aimbot", "Other" }
local tabFrames = {}

for i, tabName in ipairs(tabs) do
	local btn = Instance.new("TextButton", mainFrame)
	btn.Size = UDim2.new(0.5, 0, 0, 30)
	btn.Position = UDim2.new((i - 1) * 0.5, 0, 0, 0)
	btn.Text = tabName
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 16

	local frame = Instance.new("Frame", mainFrame)
	frame.Size = UDim2.new(1, 0, 1, -30)
	frame.Position = UDim2.new(0, 0, 0, 30)
	frame.BackgroundTransparency = 1
	frame.Visible = (i == 1)
	tabFrames[tabName] = frame

	btn.MouseButton1Click:Connect(function()
		for _, f in pairs(tabFrames) do
			f.Visible = false
		end
		frame.Visible = true
	end)
end

local aimbotTab = tabFrames["Aimbot"]
local otherTab = tabFrames["Other"]

-- Aimbot Toggle
local aimbotToggle = Instance.new("TextButton", aimbotTab)
aimbotToggle.Size = UDim2.new(0.9, 0, 0, 30)
aimbotToggle.Position = UDim2.new(0.05, 0, 0, 10)
aimbotToggle.Text = "Aimbot: OFF"
aimbotToggle.TextColor3 = Color3.new(1, 1, 1)
aimbotToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
aimbotToggle.Font = Enum.Font.SourceSans
aimbotToggle.TextSize = 16

aimbotToggle.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotToggle.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
	vprint("Aimbot toggled " .. (aimbotEnabled and "ON" or "OFF"))
end)

-- Priority Dropdown
local priorityLabel = Instance.new("TextLabel", aimbotTab)
priorityLabel.Size = UDim2.new(0.9, 0, 0, 20)
priorityLabel.Position = UDim2.new(0.05, 0, 0, 60)
priorityLabel.Text = "Priority:"
priorityLabel.TextColor3 = Color3.new(1, 1, 1)
priorityLabel.BackgroundTransparency = 1
priorityLabel.Font = Enum.Font.SourceSans
priorityLabel.TextSize = 14

local priorityDropdown = Instance.new("TextButton", aimbotTab)
priorityDropdown.Size = UDim2.new(0.9, 0, 0, 30)
priorityDropdown.Position = UDim2.new(0.05, 0, 0, 80)
priorityDropdown.TextColor3 = Color3.new(1, 1, 1)
priorityDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
priorityDropdown.Font = Enum.Font.SourceSans
priorityDropdown.TextSize = 16

local priorityOptions = {"Health", "Closest", "Farthest"}
priorityDropdown.Text = priority

priorityDropdown.MouseButton1Click:Connect(function()
	local index = table.find(priorityOptions, priority) or 0
	local next = (index % #priorityOptions) + 1
	priority = priorityOptions[next]
	priorityDropdown.Text = priority
	vprint("Priority set to: " .. priority)
end)

-- Noclip Toggle
local noclipBtn = Instance.new("TextButton", otherTab)
noclipBtn.Size = UDim2.new(0.9, 0, 0, 30)
noclipBtn.Position = UDim2.new(0.05, 0, 0, 10)
noclipBtn.Text = "Noclip: OFF"
noclipBtn.TextColor3 = Color3.new(1, 1, 1)
noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
noclipBtn.Font = Enum.Font.SourceSans
noclipBtn.TextSize = 16

noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
	vprint("Noclip toggled " .. (noclipEnabled and "ON" or "OFF"))
end)

-- Targeting Logic
local function getTarget()
	local zombiesFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Zombies")
	if not zombiesFolder then return end

	local bestTarget, bestValue = nil, (priority == "Farthest" and -math.huge or math.huge)

	for _, model in pairs(zombiesFolder:GetChildren()) do
		if model:IsA("Model") then
			local part = model:FindFirstChild(targetPartName)
			if part and part:IsA("BasePart") then
				local dist = (part.Position - HumanoidRootPart.Position).Magnitude
				if dist <= maxRange then
					if priority == "Closest" and dist < bestValue then
						bestValue, bestTarget = dist, part
					elseif priority == "Farthest" and dist > bestValue then
						bestValue, bestTarget = dist, part
					elseif priority == "Health" then
						local hp = model:FindFirstChild("Humanoid")
						if hp and hp.Health < bestValue then
							bestValue, bestTarget = hp.Health, part
						end
					end
				end
			end
		end
	end

	if bestTarget then vprint("Targeting: " .. bestTarget:GetFullName()) end
	return bestTarget
end

-- Main Loop
RunService.RenderStepped:Connect(function()
	if aimbotEnabled then
		local target = getTarget()
		if target then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
		end
	end

	if noclipEnabled and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end
    -- === Part Selection Dropdown ===
local partLabel = Instance.new("TextLabel", aimbotTab)
partLabel.Size = UDim2.new(0.9, 0, 0, 20)
partLabel.Position = UDim2.new(0.05, 0, 0, 120)
partLabel.Text = "Target Part:"
partLabel.TextColor3 = Color3.new(1, 1, 1)
partLabel.BackgroundTransparency = 1
partLabel.Font = Enum.Font.SourceSans
partLabel.TextSize = 14

local partOptions = {"HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso"}
local partDropdown = Instance.new("TextButton", aimbotTab)
partDropdown.Size = UDim2.new(0.9, 0, 0, 30)
partDropdown.Position = UDim2.new(0.05, 0, 0, 140)
partDropdown.Text = targetPartName
partDropdown.TextColor3 = Color3.new(1, 1, 1)
partDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
partDropdown.Font = Enum.Font.SourceSans
partDropdown.TextSize = 16

partDropdown.MouseButton1Click:Connect(function()
	local index = table.find(partOptions, targetPartName) or 0
	local next = (index % #partOptions) + 1
	targetPartName = partOptions[next]
	partDropdown.Text = targetPartName
	vprint("Part set to: " .. targetPartName)
end
-- === GUI TOGGLE BUTTON ===
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 10, 1, -60)
toggleBtn.Text = "GUI"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 18

local guiVisible = true
toggleBtn.MouseButton1Click:Connect(function()
	guiVisible = not guiVisible
	mainFrame.Visible = guiVisible
end
end)
