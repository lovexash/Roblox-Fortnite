-- Aura RNG | AuraData
-- The master list of every aura in the game plus the rolling logic.
--
-- Each aura is defined by:
--   name   : display name
--   rarity : the "1 in X" denominator (e.g. 1000 means a 1/1000 base chance)
--   c1, c2 : the two gradient colors used everywhere this aura is shown
--
-- Auras are ordered from most common to rarest. Their numeric id is their
-- index in this list, which is stable as long as you only append.

local AuraData = {}

-- ── Tier definitions ──────────────────────────────────────────────────────────
-- Tiers are derived from rarity so we never have to keep them in sync by hand.
AuraData.Tiers = {
	{ name = "Common",       max = 99,        color = Color3.fromRGB(180, 185, 195) },
	{ name = "Uncommon",     max = 999,       color = Color3.fromRGB(120, 220, 130) },
	{ name = "Rare",         max = 9999,      color = Color3.fromRGB(80,  150, 255) },
	{ name = "Epic",         max = 99999,     color = Color3.fromRGB(180, 90,  255) },
	{ name = "Legendary",    max = 999999,    color = Color3.fromRGB(255, 190, 40)  },
	{ name = "Mythic",       max = 9999999,   color = Color3.fromRGB(255, 90,  120) },
	{ name = "Exotic",       max = 99999999,  color = Color3.fromRGB(0,   230, 200) },
	{ name = "Divine",       max = 999999999, color = Color3.fromRGB(255, 240, 150) },
	{ name = "Celestial",    max = 99999999999,  color = Color3.fromRGB(140, 200, 255) },
	{ name = "Transcendent", max = 999999999999999, color = Color3.fromRGB(255, 120, 255) },
	{ name = "Quantum",      max = math.huge, color = Color3.fromRGB(255, 255, 255) },
}

function AuraData.GetTier(rarity)
	for _, tier in ipairs(AuraData.Tiers) do
		if rarity <= tier.max then
			return tier
		end
	end
	return AuraData.Tiers[#AuraData.Tiers]
end

-- ── The aura list ─────────────────────────────────────────────────────────────
local C = Color3.fromRGB
local list = {
	-- Common
	{ name = "Common",        rarity = 2,     c1 = C(170,175,185), c2 = C(120,125,135) },
	{ name = "Uncommon",      rarity = 4,     c1 = C(150,210,150), c2 = C(90,160,90)   },
	{ name = "Good",          rarity = 5,     c1 = C(120,230,160), c2 = C(60,170,110)  },
	{ name = "Natural",       rarity = 8,     c1 = C(180,210,120), c2 = C(110,150,60)  },
	{ name = "Rare",          rarity = 16,    c1 = C(90,160,255),  c2 = C(40,90,200)   },
	{ name = "Crystallized",  rarity = 32,    c1 = C(150,220,255), c2 = C(80,150,220)  },
	{ name = "Divinius",      rarity = 64,    c1 = C(220,200,255), c2 = C(150,120,230) },
	{ name = "Forbidden",     rarity = 90,    c1 = C(120,40,40),   c2 = C(40,10,10)    },
	-- Uncommon
	{ name = "Emerald",       rarity = 200,   c1 = C(40,230,120),  c2 = C(10,140,70)   },
	{ name = "Sapphire",      rarity = 320,   c1 = C(40,120,255),  c2 = C(10,50,180)   },
	{ name = "Ruby",          rarity = 500,   c1 = C(255,60,80),   c2 = C(160,10,30)   },
	{ name = "Topaz",         rarity = 800,   c1 = C(255,200,60),  c2 = C(200,130,10)  },
	-- Rare
	{ name = "Diamond",       rarity = 1000,  c1 = C(190,240,255), c2 = C(120,200,255) },
	{ name = "Gilded",        rarity = 1600,  c1 = C(255,215,90),  c2 = C(190,140,20)  },
	{ name = "Aquatic",       rarity = 2048,  c1 = C(40,200,230),  c2 = C(10,110,170)  },
	{ name = "Magnetic",      rarity = 2500,  c1 = C(200,80,80),   c2 = C(80,80,200)   },
	{ name = "Precious",      rarity = 4096,  c1 = C(255,160,220),  c2 = C(200,80,160) },
	{ name = "Undead",        rarity = 6000,  c1 = C(120,160,90),  c2 = C(50,70,40)    },
	{ name = "Wind",          rarity = 8000,  c1 = C(200,255,235),  c2 = C(140,210,200)},
	-- Epic
	{ name = "Glacier",       rarity = 10000, c1 = C(150,230,255), c2 = C(70,160,210)  },
	{ name = "Hazard",        rarity = 16000, c1 = C(230,230,60),  c2 = C(40,40,40)    },
	{ name = "Flushed",       rarity = 24000, c1 = C(255,150,160), c2 = C(220,80,90)   },
	{ name = "Bleeding",      rarity = 32000, c1 = C(255,40,40),   c2 = C(90,0,0)      },
	{ name = "Aether",        rarity = 50000, c1 = C(150,120,255), c2 = C(70,40,170)   },
	{ name = "Lunar",         rarity = 64000, c1 = C(200,210,255), c2 = C(110,120,180) },
	{ name = "Solar",         rarity = 80000, c1 = C(255,180,40),  c2 = C(255,90,10)   },
	-- Legendary
	{ name = "Starlight",     rarity = 100000,  c1 = C(255,255,200), c2 = C(150,160,255) },
	{ name = "Galaxy",        rarity = 200000,  c1 = C(120,70,220),  c2 = C(30,20,80)    },
	{ name = "Nebula",        rarity = 320000,  c1 = C(255,90,200),  c2 = C(80,40,160)   },
	{ name = "Permafrost",    rarity = 500000,  c1 = C(190,250,255), c2 = C(90,180,230)  },
	{ name = "Ascended",      rarity = 750000,  c1 = C(255,250,180), c2 = C(255,200,80)  },
	-- Mythic
	{ name = "Celestial",     rarity = 1000000,  c1 = C(170,210,255), c2 = C(255,200,255) },
	{ name = "Twilight",      rarity = 2000000,  c1 = C(255,140,90),  c2 = C(80,40,140)   },
	{ name = "Comet",         rarity = 4000000,  c1 = C(120,200,255), c2 = C(255,255,255) },
	{ name = "Stormal",       rarity = 6000000,  c1 = C(180,210,255), c2 = C(40,60,120)   },
	{ name = "Undefined",     rarity = 10000000, c1 = C(255,0,255),   c2 = C(0,255,255)   },
	-- Exotic
	{ name = "Gargantua",     rarity = 25000000,  c1 = C(80,40,160),  c2 = C(10,5,40)     },
	{ name = "Quantum",       rarity = 50000000,  c1 = C(0,255,210),  c2 = C(120,0,255)   },
	{ name = "Archangel",     rarity = 100000000, c1 = C(255,250,220), c2 = C(255,210,120) },
	-- Divine
	{ name = "Apostolos",     rarity = 250000000, c1 = C(255,240,170), c2 = C(140,120,255) },
	{ name = "Oblivion",      rarity = 500000000, c1 = C(140,20,40),   c2 = C(10,0,10)     },
	{ name = "Matrix",        rarity = 1000000000, c1 = C(40,255,80),  c2 = C(0,40,0)      },
	-- Celestial
	{ name = "Equinox",       rarity = 5000000000,  c1 = C(20,20,30),   c2 = C(255,255,255) },
	{ name = "Singularity",   rarity = 10000000000, c1 = C(120,0,255),  c2 = C(0,0,0)       },
	{ name = "Hypernova",     rarity = 50000000000, c1 = C(255,130,40),  c2 = C(255,255,200)},
	{ name = "Genesis",       rarity = 100000000000, c1 = C(255,255,255), c2 = C(120,200,255) },
	-- Transcendent
	{ name = "Abyssal Void",  rarity = 500000000000,  c1 = C(60,0,120),  c2 = C(0,0,0)      },
	{ name = "Chronos",       rarity = 1000000000000, c1 = C(200,255,230), c2 = C(120,180,160) },
	{ name = "Aeternum",      rarity = 10000000000000, c1 = C(255,230,140), c2 = C(180,40,200) },
	{ name = "Omniscient",    rarity = 100000000000000, c1 = C(255,255,255), c2 = C(180,140,255) },
	-- Quantum (1 in 1 Quadrillion)
	{ name = "Quadromancer",  rarity = 1000000000000000, c1 = C(255,255,255), c2 = C(0,255,255) },
}

-- Finalize: assign ids, tiers, derived sell values, and precompute weights.
AuraData.List = list
AuraData.ById = {}

local totalWeight = 0
for i, aura in ipairs(list) do
	aura.id = i
	aura.tier = AuraData.GetTier(aura.rarity).name
	-- Sell/earn value grows with rarity but is dampened so it stays sane.
	aura.value = math.max(5, math.floor(math.sqrt(aura.rarity) * 1.5))
	aura.weight = 1 / aura.rarity
	totalWeight += aura.weight
	AuraData.ById[i] = aura
end
AuraData.TotalWeight = totalWeight
AuraData.Count = #list

-- Pick a single aura using the base weights (1 / rarity).
local function pickOnce()
	local r = math.random() * AuraData.TotalWeight
	local acc = 0
	for _, aura in ipairs(AuraData.List) do
		acc += aura.weight
		if r <= acc then
			return aura
		end
	end
	return AuraData.List[1]
end

-- Roll for an aura. `luck` performs that many draws and keeps the rarest one,
-- which is how luck boosts / potions improve the odds of rare auras.
function AuraData.Roll(luck)
	luck = math.max(1, math.floor(tonumber(luck) or 1))
	luck = math.min(luck, 5000) -- safety cap so a roll never stalls the server
	local best = pickOnce()
	for _ = 2, luck do
		local candidate = pickOnce()
		if candidate.rarity > best.rarity then
			best = candidate
		end
	end
	return best
end

-- Roll restricted to a pool of aura ids (used by capsules that bias toward a
-- particular set of auras). Still respects luck the same way.
function AuraData.RollFromPool(poolIds, luck)
	luck = math.max(1, math.floor(tonumber(luck) or 1))
	luck = math.min(luck, 5000)
	-- Build a local weighted set.
	local pool, total = {}, 0
	for _, id in ipairs(poolIds) do
		local aura = AuraData.ById[id]
		if aura then
			total += aura.weight
			pool[#pool + 1] = aura
		end
	end
	if #pool == 0 then return AuraData.Roll(luck) end

	local function drawPool()
		local r = math.random() * total
		local acc = 0
		for _, aura in ipairs(pool) do
			acc += aura.weight
			if r <= acc then return aura end
		end
		return pool[1]
	end

	local best = drawPool()
	for _ = 2, luck do
		local candidate = drawPool()
		if candidate.rarity > best.rarity then best = candidate end
	end
	return best
end

return AuraData
