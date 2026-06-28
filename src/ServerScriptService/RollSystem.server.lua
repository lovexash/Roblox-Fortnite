-- Aura RNG | RollSystem
-- Handles roll requests: validates cooldown, computes luck, rolls an aura,
-- updates the player's inventory + coins + global counts, and reports back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AuraData   = require(ReplicatedStorage:WaitForChild("AuraData"))
local Core       = require(script.Parent:WaitForChild("Core"))

local lastRoll = {} -- [userId] = os.clock() of last successful roll

local function grantAura(player, aura, isCapsule)
	local profile = Core.GetProfile(player)
	if not profile then return end

	Core.AddAura(player, aura.id, 1)
	Core.IncrementGlobal(aura.id, 1)

	-- Coins for the roll.
	local coins = math.max(GameConfig.Roll.MinCoinsPerRoll, aura.value)
	coins = math.floor(coins * (profile.coinMult or 1))
	Core.AddCoins(player, coins)

	-- Auto-equip if this aura is rarer than whatever is equipped.
	local equipped = profile.equipped and AuraData.ById[profile.equipped]
	if not equipped or aura.rarity > equipped.rarity then
		Core.EquipAura(player, aura.id)
	end

	profile.stats.rolls = (profile.stats.rolls or 0) + 1
end

local function doRoll(player)
	local profile = Core.GetProfile(player)
	if not profile then return end

	-- Cooldown check.
	local now = os.clock()
	local cd = Core.GetRollCooldown(player)
	local last = lastRoll[player.UserId] or 0
	if now - last < cd then
		return -- too soon; ignore silently (client also gates this)
	end
	lastRoll[player.UserId] = now

	local luck = Core.GetLuck(player)
	local aura = AuraData.Roll(luck)
	grantAura(player, aura)

	local globalCount = (Core.GetGlobalCounts()[aura.id] or 0)
	Core.Remotes.RollResult:FireClient(player, {
		id      = aura.id,
		rarity  = aura.rarity,
		luck    = luck,
		exists  = globalCount,
		coins   = math.max(GameConfig.Roll.MinCoinsPerRoll, aura.value),
		multi   = false,
	})
	Core.Push(player)
end

Core.Remotes.RollRequest.OnServerEvent:Connect(doRoll)

print("[Aura RNG] RollSystem ready.")
