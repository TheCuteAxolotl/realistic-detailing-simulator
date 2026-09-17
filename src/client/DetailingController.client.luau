local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local ToolData = require(ReplicatedStorage.Shared.ToolData)
local remotes = ReplicatedStorage:WaitForChild("DetailingRemotes")
local useTool = remotes:WaitForChild("UseTool")
local stateUpdate = remotes:WaitForChild("StateUpdate")
local requestState = remotes:WaitForChild("RequestState")

local TOOL_ORDER = { "PressureWasher", "FoamCannon", "WashMitt", "DryingTowel" }
local KEY_TO_TOOL = {
	[Enum.KeyCode.One] = "PressureWasher",
	[Enum.KeyCode.Two] = "FoamCannon",
	[Enum.KeyCode.Three] = "WashMitt",
	[Enum.KeyCode.Four] = "DryingTowel",
}

local selectedTool = "PressureWasher"
local latestState = nil
local toolButtons = {}
local activePointer = nil
local pointerPosition = Vector2.zero
local actionLoopRunning = false

local gui = Instance.new("ScreenGui")
gui.Name = "DetailingHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = transparency
	stroke.Thickness = 1
	stroke.Parent = instance
end

local topCard = Instance.new("Frame")
topCard.Name = "JobCard"
topCard.Position = UDim2.fromOffset(18, 18)
topCard.Size = UDim2.fromOffset(300, 144)
topCard.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
topCard.BackgroundTransparency = 0.08
topCard.Parent = gui
addCorner(topCard, 14)
addStroke(topCard, 0.82)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(260, 144)
sizeConstraint.MaxSize = Vector2.new(340, 144)
sizeConstraint.Parent = topCard

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBold
title.Text = "CUSTOMER DETAIL"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topCard

local cashLabel = Instance.new("TextLabel")
cashLabel.BackgroundTransparency = 1
cashLabel.Position = UDim2.fromOffset(14, 34)
cashLabel.Size = UDim2.new(1, -28, 0, 20)
cashLabel.Font = Enum.Font.GothamMedium
cashLabel.Text = "Cash: $---"
cashLabel.TextColor3 = Color3.fromRGB(165, 235, 173)
cashLabel.TextSize = 14
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = topCard

local stateLabel = Instance.new("TextLabel")
stateLabel.BackgroundTransparency = 1
stateLabel.Position = UDim2.fromOffset(14, 58)
stateLabel.Size = UDim2.new(1, -28, 0, 48)
stateLabel.Font = Enum.Font.Gotham
stateLabel.Text = "Clean: --%   Dirt: --%\nSoap: --%   Water: --%"
stateLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
stateLabel.TextSize = 13
stateLabel.TextWrapped = true
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.TextYAlignment = Enum.TextYAlignment.Top
stateLabel.Parent = topCard

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.fromOffset(14, 108)
statusLabel.Size = UDim2.new(1, -28, 0, 28)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "Select a tool and aim at a body panel."
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 186)
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = topCard

local toolBar = Instance.new("Frame")
toolBar.Name = "ToolBar"
toolBar.AnchorPoint = Vector2.new(0.5, 1)
toolBar.Position = UDim2.new(0.5, 0, 1, -18)
toolBar.Size = UDim2.new(1, -24, 0, 78)
toolBar.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
toolBar.BackgroundTransparency = 0.08
toolBar.Parent = gui
addCorner(toolBar, 16)
addStroke(toolBar, 0.82)

local toolConstraint = Instance.new("UISizeConstraint")
toolConstraint.MaxSize = Vector2.new(720, 78)
toolConstraint.MinSize = Vector2.new(280, 78)
toolConstraint.Parent = toolBar

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = toolBar

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(6, 0)
grid.CellSize = UDim2.new(0.25, -5, 1, 0)
grid.FillDirectionMaxCells = 4
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = toolBar

local highlight = Instance.new("Highlight")
highlight.Name = "DetailPanelHighlight"
highlight.FillTransparency = 0.8
highlight.OutlineTransparency = 0.15
highlight.FillColor = Color3.fromRGB(255, 255, 255)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = workspace

local function updateState(state)
	if type(state) ~= "table" then
		return
	end
	latestState = state
	stateLabel.Text = string.format(
		"Clean: %d%%   Dirt: %d%%\nSoap: %d%%   Water: %d%%",
		math.floor((state.Cleanliness or 0) + 0.5),
		math.floor((state.Dirt or 0) + 0.5),
		math.floor((state.Soap or 0) + 0.5),
		math.floor((state.Water or 0) + 0.5)
	)
end

local function updateSelectedTool()
	for toolName, button in toolButtons do
		local selected = toolName == selectedTool
		button.BackgroundColor3 = selected and Color3.fromRGB(235, 235, 238) or Color3.fromRGB(38, 38, 42)
		button.TextColor3 = selected and Color3.fromRGB(18, 18, 20) or Color3.fromRGB(235, 235, 238)
	end

	local data = ToolData[selectedTool]
	if data then
		statusLabel.Text = `{data.Label}: {data.Hint}`
	end
end

local function selectTool(toolName)
	if not ToolData[toolName] then
		return
	end
	selectedTool = toolName
	updateSelectedTool()
end

for index, toolName in TOOL_ORDER do
	local data = ToolData[toolName]
	local button = Instance.new("TextButton")
	button.Name = toolName
	button.LayoutOrder = index
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
	button.Font = Enum.Font.GothamBold
	button.Text = `{data.Shortcut}\n{data.Label}`
	button.TextColor3 = Color3.fromRGB(235, 235, 238)
	button.TextSize = 12
	button.TextWrapped = true
	button.Parent = toolBar
	addCorner(button, 10)
	button.Activated:Connect(function()
		selectTool(toolName)
	end)
	toolButtons[toolName] = button
end

local function getTargetAt(screenPosition)
	camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	if player.Character then
		params.FilterDescendantsInstances = { player.Character }
	else
		params.FilterDescendantsInstances = {}
	end

	local result = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	return result and result.Instance or nil
end

local function performAction()
	local target = getTargetAt(pointerPosition)
	if not target or not CollectionService:HasTag(target, "DetailPanel") then
		statusLabel.Text = "Aim directly at one of the dirty painted panels."
		return
	end
	useTool:FireServer(selectedTool, target)
end

local function runActionLoop()
	if actionLoopRunning then
		return
	end
	actionLoopRunning = true

	task.spawn(function()
		while activePointer do
			performAction()
			task.wait(0.09)
		end
		actionLoopRunning = false
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local mappedTool = KEY_TO_TOOL[input.KeyCode]
	if mappedTool then
		selectTool(mappedTool)
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		activePointer = input
		pointerPosition = Vector2.new(input.Position.X, input.Position.Y)
		runActionLoop()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == activePointer or (activePointer and input.UserInputType == Enum.UserInputType.MouseMovement) then
		pointerPosition = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == activePointer or (activePointer and input.UserInputType == Enum.UserInputType.MouseButton1) then
		activePointer = nil
	end
end)

stateUpdate.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.State then
		updateState(payload.State)
	end
	if type(payload.Message) == "string" then
		statusLabel.Text = payload.Message
	end

	if payload.Kind == "JobComplete" then
		statusLabel.TextColor3 = Color3.fromRGB(165, 235, 173)
	elseif payload.Kind == "Warning" then
		statusLabel.TextColor3 = Color3.fromRGB(245, 188, 120)
	else
		statusLabel.TextColor3 = Color3.fromRGB(180, 180, 186)
	end
end)

local function connectCashDisplay()
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then
		return
	end
	local cash = leaderstats:WaitForChild("Cash", 5)
	if not cash then
		return
	end

	local function refresh()
		cashLabel.Text = `Cash: ${cash.Value}`
	end
	refresh()
	cash:GetPropertyChangedSignal("Value"):Connect(refresh)
end

task.spawn(connectCashDisplay)

task.spawn(function()
	local success, initial = pcall(function()
		return requestState:InvokeServer()
	end)
	if success and type(initial) == "table" and initial.State then
		updateState(initial.State)
	end
end)

RunService.RenderStepped:Connect(function()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		highlight.Enabled = false
		return
	end

	local target = mouse.Target
	if target and CollectionService:HasTag(target, "DetailPanel") then
		highlight.Adornee = target
		highlight.Enabled = true
	else
		highlight.Enabled = false
		highlight.Adornee = nil
	end
end)

selectTool(selectedTool)
