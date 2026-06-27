-- Aura RNG | CapsuleData
-- Robux capsules: each capsule rolls one (or more) auras with a heavy luck
-- boost, biased toward the tiers listed. Buy with Robux (developer product) or
-- with in-game coins where a coinPrice is set.
--
-- `productId` is a placeholder developer-product id — replace with your own.
-- `luck` is the effective luck applied to the roll, making rare auras far more
-- likely than a normal free roll.

local AuraData = require(script.Parent:WaitForChild("AuraData"))

local CapsuleData = {}

-- Helper: collect aura ids whose rarity falls in [min, max].
local function idsInRange(minR, maxR)
	local ids = {}
	for _, aura in ipairs(AuraData.List) do
		if aura.rarity >= minR and aura.rarity <= maxR then
			ids[#ids + 1] = aura.id
		end
	end
	return ids
end

CapsuleData.List = {
	{
		id = "basic",
		name = "Basic Capsule",
		icon = "🥚",
		color = Color3.fromRGB(150, 200, 255),
		robux = 25,
		coinPrice = 2500,        -- can also be bought with coins
		productId = 0,
		luck = 25,
		rolls = 1,
		pool = idsInRange(2, 100000),       -- common → legendary
		desc = "A solid starter pull with a luck boost.",
	},
	{
		id = "lucky",
		name = "Lucky Capsule",
		icon = "🍀",
		color = Color3.fromRGB(120, 240, 130),
		robux = 75,
		coinPrice = 25000,
		productId = 0,
		luck = 150,
		rolls = 1,
		pool = idsInRange(1000, 10000000),  -- rare → mythic
		desc = "Heavy luck. Greatly favors Legendary+ auras.",
	},
	{
		id = "mythic",
		name = "Mythic Capsule",
		icon = "🔮",
		color = Color3.fromRGB(255, 90, 200),
		robux = 199,
		productId = 0,
		luck = 600,
		rolls = 1,
		pool = idsInRange(100000, 1000000000), -- legendary → divine
		desc = "Guaranteed bias toward Mythic and Exotic auras.",
	},
	{
		id = "celestial",
		name = "Celestial Capsule",
		icon = "🌌",
		color = Color3.fromRGB(140, 200, 255),
		robux = 499,
		productId = 0,
		luck = 1500,
		rolls = 1,
		pool = idsInRange(10000000, 100000000000), -- exotic → celestial
		desc = "The big one. Aims for Celestial-tier power.",
	},
	{
		id = "transcendent",
		name = "Transcendent Capsule",
		icon = "✨",
		color = Color3.fromRGB(255, 120, 255),
		robux = 999,
		productId = 0,
		luck = 4000,
		rolls = 1,
		pool = idsInRange(1000000000, 1e18),       -- divine → quantum
		desc = "Reaches for Transcendent and beyond. 1 in 1Q is possible.",
	},
	{
		id = "multi",
		name = "Mega 10x Capsule",
		icon = "🎁",
		color = Color3.fromRGB(255, 200, 60),
		robux = 299,
		productId = 0,
		luck = 300,
		rolls = 10,                                 -- ten auras at once
		pool = idsInRange(100, 100000000),
		desc = "Ten luck-boosted rolls in a single capsule.",
	},
}

CapsuleData.ById = {}
for _, cap in ipairs(CapsuleData.List) do
	CapsuleData.ById[cap.id] = cap
end

return CapsuleData
