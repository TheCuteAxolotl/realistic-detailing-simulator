local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataService = {}

local store = DataStoreService:GetDataStore("RealisticDetailingSimulator_Player_v1")
local profiles = {}

local function defaultProfile()
	return {
		Cash = Config.StartingCash,
		Jobs = 0,
		Reputation = 0,
	}
end

local function sanitizeProfile(raw)
	local profile = defaultProfile()
	if type(raw) ~= "table" then
		return profile
	end

	if type(raw.Cash) == "number" then
		profile.Cash = math.max(0, math.floor(raw.Cash))
	end
	if type(raw.Jobs) == "number" then
		profile.Jobs = math.max(0, math.floor(raw.Jobs))
	end
	if type(raw.Reputation) == "number" then
		profile.Reputation = math.max(0, raw.Reputation)
	end

	return profile
end

local function createLeaderstats(player, profile)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = profile.Cash
	cash.Parent = leaderstats

	local jobs = Instance.new("IntValue")
	jobs.Name = "Jobs"
	jobs.Value = profile.Jobs
	jobs.Parent = leaderstats

	local reputation = Instance.new("NumberValue")
	reputation.Name = "Reputation"
	reputation.Value = profile.Reputation
	reputation.Parent = player
end

local function syncValues(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		local jobs = leaderstats:FindFirstChild("Jobs")
		if cash then
			cash.Value = profile.Cash
		end
		if jobs then
			jobs.Value = profile.Jobs
		end
	end

	local reputation = player:FindFirstChild("Reputation")
	if reputation then
		reputation.Value = profile.Reputation
	end
end

function PlayerDataService.LoadPlayer(player)
	local profile = defaultProfile()
	local success, result = pcall(function()
		return store:GetAsync(`player_{player.UserId}`)
	end)

	if success then
		profile = sanitizeProfile(result)
	else
		warn(`[PlayerDataService] DataStore load unavailable for {player.Name}: {result}`)
	end

	profiles[player] = profile
	createLeaderstats(player, profile)
end

function PlayerDataService.SavePlayer(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local payload = {
		Cash = profile.Cash,
		Jobs = profile.Jobs,
		Reputation = profile.Reputation,
	}

	local success, err = pcall(function()
		store:SetAsync(`player_{player.UserId}`, payload)
	end)

	if not success then
		warn(`[PlayerDataService] DataStore save unavailable for {player.Name}: {err}`)
	end
end

function PlayerDataService.AwardJob(player, cashAmount, reputationAmount)
	local profile = profiles[player]
	if not profile then
		return
	end

	profile.Cash += math.max(0, math.floor(cashAmount))
	profile.Jobs += 1
	profile.Reputation += math.max(0, reputationAmount)
	syncValues(player)
end

function PlayerDataService.GetPublicProfile(player)
	local profile = profiles[player]
	if not profile then
		return defaultProfile()
	end

	return {
		Cash = profile.Cash,
		Jobs = profile.Jobs,
		Reputation = profile.Reputation,
	}
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(PlayerDataService.LoadPlayer)
	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.SavePlayer(player)
		profiles[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(PlayerDataService.LoadPlayer, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerDataService.SavePlayer(player)
		end
	end)
end

return PlayerDataService
