local Config = {}

Config.StartingCash = 500
Config.MaxToolDistance = 28

Config.ActionCooldowns = {
	PressureWasher = 0.08,
	FoamCannon = 0.12,
	WashMitt = 0.10,
	DryingTowel = 0.10,
}

Config.Job = {
	BasePayout = 125,
	MaxTip = 40,
	CompletionDirt = 4,
	CompletionSoap = 2,
	CompletionWater = 4,
	ResetDelay = 5,
}

Config.Vehicle = {
	StartingDirtMin = 72,
	StartingDirtMax = 100,
	CleanPaintColor = Color3.fromRGB(42, 44, 50),
	DirtColor = Color3.fromRGB(105, 83, 58),
	SoapColor = Color3.fromRGB(230, 235, 240),
}

return Config
