local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ToolData = require(ReplicatedStorage.Shared.ToolData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local VehicleService = require(script.Parent.VehicleService)

local function getOrCreate(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local remotes = getOrCreate("Folder", "DetailingRemotes", ReplicatedStorage)
local useTool = getOrCreate("RemoteEvent", "UseTool", remotes)
local stateUpdate = getOrCreate("RemoteEvent", "StateUpdate", remotes)
local requestState = getOrCreate("RemoteFunction", "RequestState", remotes)

PlayerDataService.Init()
VehicleService.Init()

local lastActions = {}

local function canAct(player, toolName)
	local cooldown = Config.ActionCooldowns[toolName]
	if not cooldown then
		return false
	end

	local now = os.clock()
	local playerActions = lastActions[player.UserId]
	if not playerActions then
		playerActions = {}
		lastActions[player.UserId] = playerActions
	end

	local last = playerActions[toolName] or 0
	if now - last < cooldown then
		return false
	end

	playerActions[toolName] = now
	return true
end

requestState.OnServerInvoke = function(player)
	return {
		State = VehicleService.GetState(),
		Profile = PlayerDataService.GetPublicProfile(player),
	}
end

useTool.OnServerEvent:Connect(function(player, toolName, target)
	if type(toolName) ~= "string" or not ToolData[toolName] then
		return
	end
	if not canAct(player, toolName) then
		return
	end

	local success, message, state = VehicleService.ApplyTool(player, toolName, target)
	stateUpdate:FireClient(player, {
		Kind = success and "Action" or "Warning",
		Message = message,
		State = state,
	})

	if not success then
		return
	end

	local completion = VehicleService.TryComplete()
	if not completion then
		return
	end

	PlayerDataService.AwardJob(player, completion.Payout, completion.Reputation)
	stateUpdate:FireAllClients({
		Kind = "JobComplete",
		Message = `{player.DisplayName} finished the detail — ${completion.Payout} earned ({math.floor(completion.Quality)}% quality).`,
		State = completion.State,
		Payout = completion.Payout,
		Tip = completion.Tip,
		Quality = completion.Quality,
	})

	task.delay(Config.Job.ResetDelay, function()
		local newState = VehicleService.ResetJob()
		stateUpdate:FireAllClients({
			Kind = "JobReset",
			Message = "A new customer vehicle is ready.",
			State = newState,
		})
	end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastActions[player.UserId] = nil
end)
