local ToolData = {
	PressureWasher = {
		Label = "Pressure Washer",
		Shortcut = "1",
		Hint = "Pre-rinse dirt and rinse away soap.",
		DirtRemoval = 11,
		SoapRemoval = 22,
		WaterAdd = 38,
	},
	FoamCannon = {
		Label = "Foam Cannon",
		Shortcut = "2",
		Hint = "Cover the paint with foam before contact washing.",
		SoapAdd = 34,
		WaterAdd = 8,
	},
	WashMitt = {
		Label = "Wash Mitt",
		Shortcut = "3",
		Hint = "Agitate lubricated paint. Dry contact can add swirls.",
		DirtRemoval = 18,
		SoapUse = 5,
		MinimumSoap = 8,
		DryContactSwirls = 3,
	},
	DryingTowel = {
		Label = "Drying Towel",
		Shortcut = "4",
		Hint = "Dry only after the panel is clean and fully rinsed.",
		WaterRemoval = 34,
		MaximumSoap = 5,
		DirtyPaintSwirls = 4,
	},
}

return ToolData
