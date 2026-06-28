-- Aura RNG | ShopData
-- The coin shop: luck potions and utility items bought with in-game coins.
-- Potions grant a temporary luck multiplier for a duration (seconds).

local ShopData = {}

ShopData.Potions = {
	{
		id = "luck_small",
		name = "Lucky Potion I",
		icon = "🧪",
		color = Color3.fromRGB(120, 240, 140),
		price = 1000,
		luckMult = 2,       -- doubles your luck
		duration = 120,     -- for 2 minutes
		desc = "x2 luck for 2 minutes.",
	},
	{
		id = "luck_big",
		name = "Lucky Potion II",
		icon = "⚗️",
		color = Color3.fromRGB(80, 200, 255),
		price = 5000,
		luckMult = 5,
		duration = 180,
		desc = "x5 luck for 3 minutes.",
	},
	{
		id = "luck_super",
		name = "Fortune Elixir",
		icon = "🍯",
		color = Color3.fromRGB(255, 200, 60),
		price = 25000,
		luckMult = 15,
		duration = 240,
		desc = "x15 luck for 4 minutes.",
	},
	{
		id = "speed",
		name = "Haste Potion",
		icon = "💨",
		color = Color3.fromRGB(180, 230, 255),
		price = 3000,
		rollSpeedMult = 0.5, -- halves roll cooldown
		duration = 180,
		desc = "Roll twice as fast for 3 minutes.",
	},
}

ShopData.ById = {}
for _, p in ipairs(ShopData.Potions) do
	ShopData.ById[p.id] = p
end

return ShopData
