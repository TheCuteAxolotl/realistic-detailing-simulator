local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ToolData = require(ReplicatedStorage.Shared.ToolData)

local VehicleService = {}

local DETAIL_PANEL_TAG = "DetailPanel"
local vehicleModel = nil
local panels = {}
local jobActive = false
local jobNumber = 0

local PANEL_DEFINITIONS = {
	{ Name = "Hood", Size = Vector3.new(4.2, 0.35, 2.3), Position = Vector3.new(0, 3.15, -2.35) },
	{ Name = "Roof", Size = Vector3.new(3.6, 0.35, 2.5), Position = Vector3.new(0, 4.55, 0.35) },
	{ Name = "Trunk", Size = Vector3.new(4.1, 0.35, 1.55), Position = Vector3.new(0, 3.2, 3.05) },
	{ Name = "LeftFrontDoor", Size = Vector3.new(0.35, 1.65, 2.1), Position = Vector3.new(-2.12, 3.45, -0.75) },
	{ Name = "RightFrontDoor", Size = Vector3.new(0.35, 1.65, 2.1), Position = Vector3.new(2.12, 3.45, -0.75) },
	{ Name = "LeftRearDoor", Size = Vector3.new(0.35, 1.65, 2.0), Position = Vector3.new(-2.12, 3.45, 1.35) },
	{ Name = "RightRearDoor", Size = Vector3.new(0.35, 1.65, 2.0), Position = Vector3.new(2.12, 3.45, 1.35) },
	{ Name = "FrontBumper", Size = Vector3.new(4.2, 0.9, 0.35), Position = Vector3.new(0, 2.55, -3.75) },
	{ Name = "RearBumper", Size = Vector3.new(4.2, 0.9, 0.35), Position = Vector3.new(0, 2.55, 4.0) },
}

local function makePart(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = parent
	return part
end

local function updatePanelVisual(panel)
	local dirt = panel:GetAttribute("Dirt") or 0
	local soap = panel:GetAttribute("Soap") or 0
	local water = panel:GetAttribute("Water") or 0

	local dirtAmount = math.clamp(dirt / 100, 0, 1)
	local soapAmount = math.clamp(soap / 100, 0, 0.72)
	local color = Config.Vehicle.CleanPaintColor:Lerp(Config.Vehicle.DirtColor, dirtAmount)
	if soapAmount > 0 then
		color = color:Lerp(Config.Vehicle.SoapColor, soapAmount)
	end

	panel.Color = color
	panel.Reflectance = math.clamp((water / 100) * 0.12, 0, 0.12)
	panel:SetAttribute("Cleanliness", math.clamp(100 - dirt, 0, 100))
end

local function setCondition(panel, dirt, soap, water, swirls)
	panel:SetAttribute("Dirt", math.clamp(dirt, 0, 100))
	panel:SetAttribute("Soap", math.clamp(soap, 0, 100))
	panel:SetAttribute("Water", math.clamp(water, 0, 100))
	panel:SetAttribute("Swirls", math.max(0, swirls))
	updatePanelVisual(panel)
end

local function buildPracticeBay()
	local oldBay = Workspace:FindFirstChild("DetailingPracticeBay")
	if oldBay then
		oldBay:Destroy()
	end

	local bay = Instance.new("Model")
	bay.Name = "DetailingPracticeBay"
	bay.Parent = Workspace

	local floor = makePart(bay, "BayFloor", Vector3.new(34, 0.5, 34), Vector3.new(0, 0.25, 0), Color3.fromRGB(50, 50, 52))
	floor.Material = Enum.Material.Concrete

	local pad = makePart(bay, "WashPad", Vector3.new(11, 0.12, 14), Vector3.new(0, 0.57, 0), Color3.fromRGB(72, 72, 75))
	pad.Material = Enum.Material.Slate

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "DetailerSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 1, 11)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.45
	spawn.Color = Color3.fromRGB(220, 220, 220)
	spawn.Parent = bay

	local sign = makePart(bay, "InstructionSign", Vector3.new(8, 4, 0.4), Vector3.new(-11, 3, -6), Color3.fromRGB(22, 22, 24))
	sign.CanCollide = false
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.PixelsPerStud = 50
	surface.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "REALISTIC DETAILING\n1 PRE-RINSE  2 FOAM\n3 CONTACT WASH\n1 RINSE  4 DRY"
	label.Parent = surface

	return bay
end

local function buildPracticeVehicle(parent)
	vehicleModel = Instance.new("Model")
	vehicleModel.Name = "PracticeDetailVehicle"
	vehicleModel.Parent = parent

	local chassis = makePart(vehicleModel, "Chassis", Vector3.new(4, 0.8, 7.2), Vector3.new(0, 2.2, 0.2), Color3.fromRGB(26, 26, 28))
	chassis.CanCollide = true

	local cabin = makePart(vehicleModel, "Cabin", Vector3.new(3.45, 1.25, 3.25), Vector3.new(0, 3.65, 0.55), Color3.fromRGB(22, 28, 34))
	cabin.Transparency = 0.08
	cabin.Material = Enum.Material.Glass

	for index, definition in PANEL_DEFINITIONS do
		local panel = makePart(vehicleModel, definition.Name, definition.Size, definition.Position, Config.Vehicle.CleanPaintColor)
		panel:SetAttribute("PanelId", index)
		panel:SetAttribute("PanelName", definition.Name)
		CollectionService:AddTag(panel, DETAIL_PANEL_TAG)
		table.insert(panels, panel)
	end

	local wheelPositions = {
		Vector3.new(-2.25, 1.55, -2.25),
		Vector3.new(2.25, 1.55, -2.25),
		Vector3.new(-2.25, 1.55, 2.55),
		Vector3.new(2.25, 1.55, 2.55),
	}

	for index, position in wheelPositions do
		local wheel = makePart(vehicleModel, `Wheel{index}`, Vector3.new(0.8, 1.7, 1.7), position, Color3.fromRGB(18, 18, 18))
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Orientation = Vector3.new(0, 0, 90)
	end
end

function VehicleService.GetState()
	local panelCount = #panels
	if panelCount == 0 then
		return {
			Dirt = 0,
			Soap = 0,
			Water = 0,
			Swirls = 0,
			Cleanliness = 100,
			Panels = 0,
			Active = jobActive,
			JobNumber = jobNumber,
		}
	end

	local dirtTotal = 0
	local soapTotal = 0
	local waterTotal = 0
	local swirlTotal = 0

	for _, panel in panels do
		dirtTotal += panel:GetAttribute("Dirt") or 0
		soapTotal += panel:GetAttribute("Soap") or 0
		waterTotal += panel:GetAttribute("Water") or 0
		swirlTotal += panel:GetAttribute("Swirls") or 0
	end

	local dirt = dirtTotal / panelCount
	return {
		Dirt = dirt,
		Soap = soapTotal / panelCount,
		Water = waterTotal / panelCount,
		Swirls = swirlTotal / panelCount,
		Cleanliness = math.clamp(100 - dirt, 0, 100),
		Panels = panelCount,
		Active = jobActive,
		JobNumber = jobNumber,
	}
end

function VehicleService.ResetJob()
	jobNumber += 1
	jobActive = true

	for _, panel in panels do
		local dirt = math.random(Config.Vehicle.StartingDirtMin, Config.Vehicle.StartingDirtMax)
		setCondition(panel, dirt, 0, 0, 0)
	end

	return VehicleService.GetState()
end

function VehicleService.ApplyTool(player, toolName, target)
	if not jobActive then
		return false, "The next customer vehicle is not ready yet.", VehicleService.GetState()
	end

	local tool = ToolData[toolName]
	if not tool then
		return false, "Unknown detailing tool.", VehicleService.GetState()
	end

	if typeof(target) ~= "Instance" or not target:IsA("BasePart") then
		return false, "Aim at a body panel.", VehicleService.GetState()
	end

	if not vehicleModel or not target:IsDescendantOf(vehicleModel) or not CollectionService:HasTag(target, DETAIL_PANEL_TAG) then
		return false, "That is not a detailable body panel.", VehicleService.GetState()
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "Character is not ready.", VehicleService.GetState()
	end

	if (root.Position - target.Position).Magnitude > Config.MaxToolDistance then
		return false, "Move closer to the vehicle.", VehicleService.GetState()
	end

	local dirt = target:GetAttribute("Dirt") or 0
	local soap = target:GetAttribute("Soap") or 0
	local water = target:GetAttribute("Water") or 0
	local swirls = target:GetAttribute("Swirls") or 0
	local message = ""

	if toolName == "PressureWasher" then
		if dirt > 30 then
			dirt = math.max(30, dirt - tool.DirtRemoval)
		end
		soap = math.max(0, soap - tool.SoapRemoval)
		water = math.min(100, water + tool.WaterAdd)
		message = soap > 2 and "Rinsing soap from the panel." or "Loose dirt removed. Road film still needs contact washing."
	elseif toolName == "FoamCannon" then
		soap = math.min(100, soap + tool.SoapAdd)
		water = math.min(100, water + tool.WaterAdd)
		message = "Foam applied. Let the mitt do the contact cleaning."
	elseif toolName == "WashMitt" then
		if soap >= tool.MinimumSoap then
			dirt = math.max(0, dirt - tool.DirtRemoval)
			soap = math.max(0, soap - tool.SoapUse)
			water = math.min(100, water + 3)
			message = "Contact wash cleaned this section."
		else
			dirt = math.max(0, dirt - 2)
			swirls += tool.DryContactSwirls
			message = "Not enough lubrication — dry contact added paint defects."
		end
	elseif toolName == "DryingTowel" then
		if soap > tool.MaximumSoap then
			return false, "Rinse the soap off before drying.", VehicleService.GetState()
		end

		if water <= 1 then
			return false, "That panel is already dry.", VehicleService.GetState()
		end

		if dirt > 10 then
			water = math.max(0, water - tool.WaterRemoval * 0.4)
			swirls += tool.DirtyPaintSwirls
			message = "Drying dirty paint added defects. Clean the panel first."
		else
			water = math.max(0, water - tool.WaterRemoval)
			message = "Panel dried safely."
		end
	end

	setCondition(target, dirt, soap, water, swirls)
	return true, message, VehicleService.GetState()
end

function VehicleService.TryComplete()
	if not jobActive then
		return nil
	end

	local state = VehicleService.GetState()
	if state.Dirt > Config.Job.CompletionDirt then
		return nil
	end
	if state.Soap > Config.Job.CompletionSoap then
		return nil
	end
	if state.Water > Config.Job.CompletionWater then
		return nil
	end

	jobActive = false
	local quality = math.clamp(100 - (state.Swirls * 4), 0, 100)
	local tip = math.floor(Config.Job.MaxTip * (quality / 100))
	local payout = Config.Job.BasePayout + tip
	local reputation = math.max(1, math.floor(quality / 20))

	state.Active = false
	return {
		Payout = payout,
		Tip = tip,
		Quality = quality,
		Reputation = reputation,
		State = state,
	}
end

function VehicleService.Init()
	panels = {}
	local bay = buildPracticeBay()
	buildPracticeVehicle(bay)
	VehicleService.ResetJob()
end

return VehicleService
