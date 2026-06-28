-- Aura RNG | GameConfig
-- Central, tunable configuration for the whole game.

local GameConfig = {}

GameConfig.GAME_NAME = "Aura RNG"
GameConfig.VERSION = "1.0.0"

-- ── Rolling ──────────────────────────────────────────────────────────────────
GameConfig.Roll = {
	BaseCooldown = 1.0,    -- seconds between manual rolls at base
	FastCooldown = 0.35,   -- cooldown when the Fast Roll gamepass is owned
	BaseLuck = 1,          -- everyone starts with luck 1 (one draw per roll)
	RollRevealTime = 1.6,  -- how long the reveal animation plays on the client
	-- Coins awarded per roll = aura.value (see AuraData). A small floor keeps
	-- early rolls rewarding.
	MinCoinsPerRoll = 5,
}

-- ── Economy ──────────────────────────────────────────────────────────────────
GameConfig.Economy = {
	StartingCoins = 100,
	-- Coins gained when an aura is deleted/sold from the inventory equals
	-- aura.value * this multiplier.
	SellMultiplier = 1.0,
	DailyBonus = 500,
}

-- ── Luck / potions ───────────────────────────────────────────────────────────
GameConfig.Potions = {
	MaxStackedLuck = 5000,  -- absolute luck ceiling after all multipliers
}

-- ── Trading ──────────────────────────────────────────────────────────────────
GameConfig.Trade = {
	MaxRange = 30,          -- studs; players must be near each other to trade
	MaxItemsPerSide = 6,    -- auras offered per side
	ConfirmCountdown = 3,   -- seconds both must stay confirmed before completing
}

-- ── Gamepasses & Developer Products (replace ids with your own) ──────────────
-- These ids are placeholders. Create the passes/products in the Roblox
-- Creator Dashboard and paste their ids here.
GameConfig.Monetization = {
	Gamepasses = {
		FastRoll    = { id = 0, name = "⚡ Fast Roll",     luck = 0,  desc = "Roll 3x faster." },
		LuckII      = { id = 0, name = "🍀 Lucky II",      luck = 10, desc = "+10 permanent luck." },
		AutoRoll    = { id = 0, name = "🔁 Auto Roll",     luck = 0,  desc = "Hands-free auto rolling." },
		VIP         = { id = 0, name = "👑 VIP",           luck = 5,  desc = "+5 luck, VIP tag, 2x coins." },
	},
	-- Developer products grant coins or capsules on purchase.
	Products = {
		Coins10k    = { id = 0, name = "10,000 Coins",  coins = 10000 },
		Coins100k   = { id = 0, name = "100,000 Coins", coins = 100000 },
		-- Capsule products are keyed by capsule id in CapsuleData.
	},
}

-- ── Admin (for granting coins / testing) ─────────────────────────────────────
GameConfig.Admins = {
	-- Add your Roblox UserId here to unlock /give and test commands.
	0,
}

-- ── DataStore ────────────────────────────────────────────────────────────────
GameConfig.DataStore = {
	PlayerKey = "AuraRNG_Player_v1",
	GlobalKey = "AuraRNG_Global_v1",   -- stores "how many of each aura exist"
	AutoSaveInterval = 90,
	GlobalSaveInterval = 30,
}

return GameConfig
