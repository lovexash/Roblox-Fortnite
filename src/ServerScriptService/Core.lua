-- Aura RNG | Core (ServerScriptService ModuleScript)
-- Owns all server state: remotes, player profiles, the DataStore, and the
-- global "how many of each aura exists" counters. Every other server script
-- requires this module to read/modify state safely.

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local DataStoreService   = game:GetService("DataStoreService")
local RunService         = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AuraData   = require(ReplicatedStorage:WaitForChild("AuraData"))
local ShopData   = require(ReplicatedStorage:WaitForChild("ShopData"))
local RemoteList = require(ReplicatedStorage:WaitForChild("Remotes"))

local Core = {}

-- ── Remotes ──────────────────────────────────────────────────────────────────
local remotesFolder = ReplicatedStorage:FindFirstChild("Net")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Net"
	remotesFolder.Parent = ReplicatedStorage
end

Core.Remotes = {}
for name, isFunction in pairs(RemoteList) do
	local r = remotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
		r.Name = name
		r.Parent = remotesFolder
	end
	Core.Remotes[name] = r
end

-- ── DataStore ────────────────────────────────────────────────────────────────
local playerStore = DataStoreService:GetDataStore(GameConfig.DataStore.PlayerKey)
local globalStore = DataStoreService:GetDataStore(GameConfig.DataStore.GlobalKey)

local Profiles = {}        -- [userId] = profile table
Core.Profiles = Profiles

-- Global existence counts (approximate, merged across servers on save).
local GlobalCounts = {}    -- [auraId] = total ever rolled
local GlobalDeltas = {}    -- pending increments since last save
Core.GlobalCounts = GlobalCounts

-- ── Profile helpers ──────────────────────────────────────────────────────────
local function defaultProfile()
	return {
		coins      = GameConfig.Economy.StartingCoins,
		luckBonus  = 0,                 -- permanent additive luck (gamepasses/admin)
		equipped   = nil,               -- aura id
		inventory  = {},                -- [auraId] = count
		potions    = {},                -- list of { id, expires }
		gamepasses = {},                -- [name] = true
		coinMult   = 1,                 -- VIP etc.
		stats      = { rolls = 0, rarest = nil },
		lastDaily  = 0,
	}
end

function Core.GetProfile(player)
	return Profiles[player.UserId]
end

-- Compute the player's current effective luck (base + permanent + potions).
function Core.GetLuck(player)
	local p = Profiles[player.UserId]
	if not p then return GameConfig.Roll.BaseLuck end
	local luck = GameConfig.Roll.BaseLuck + (p.luckBonus or 0)
	local now = os.time()
	for _, potion in ipairs(p.potions) do
		if potion.expires > now then
			local def = ShopData.ById[potion.id]
			if def and def.luckMult then
				luck *= def.luckMult
			end
		end
	end
	return math.min(luck, GameConfig.Potions.MaxStackedLuck)
end

-- Roll cooldown for this player in seconds (Fast gamepass / haste potion).
function Core.GetRollCooldown(player)
	local p = Profiles[player.UserId]
	local cd = GameConfig.Roll.BaseCooldown
	if p and p.gamepasses.FastRoll then
		cd = GameConfig.Roll.FastCooldown
	end
	if p then
		local now = os.time()
		for _, potion in ipairs(p.potions) do
			if potion.expires > now then
				local def = ShopData.ById[potion.id]
				if def and def.rollSpeedMult then
					cd *= def.rollSpeedMult
				end
			end
		end
	end
	return cd
end

-- ── Serialization for the client ─────────────────────────────────────────────
-- Send only ids/counts; the client resolves colors/names from AuraData locally.
local function snapshot(player)
	local p = Profiles[player.UserId]
	if not p then return nil end

	local inv = {}
	for id, count in pairs(p.inventory) do
		inv[#inv + 1] = { id = id, count = count }
	end

	local potions, now = {}, os.time()
	for _, potion in ipairs(p.potions) do
		if potion.expires > now then
			potions[#potions + 1] = { id = potion.id, remaining = potion.expires - now }
		end
	end

	return {
		coins      = p.coins,
		luck       = Core.GetLuck(player),
		luckBonus  = p.luckBonus,
		equipped   = p.equipped,
		inventory  = inv,
		potions    = potions,
		gamepasses = p.gamepasses,
		stats      = p.stats,
		cooldown   = Core.GetRollCooldown(player),
	}
end

function Core.Push(player)
	if not Profiles[player.UserId] then return end
	Core.Remotes.UpdateProfile:FireClient(player, snapshot(player))
end

function Core.Notify(player, message, kind)
	Core.Remotes.Notify:FireClient(player, message, kind or "info")
end

-- ── Inventory / economy mutators ─────────────────────────────────────────────
function Core.AddCoins(player, amount)
	local p = Profiles[player.UserId]
	if not p then return end
	p.coins = math.max(0, p.coins + math.floor(amount))
end

function Core.AddAura(player, auraId, count)
	local p = Profiles[player.UserId]
	if not p then return false end
	count = count or 1
	p.inventory[auraId] = (p.inventory[auraId] or 0) + count
	-- Track rarest ever obtained.
	local aura = AuraData.ById[auraId]
	if aura then
		local rarest = p.stats.rarest and AuraData.ById[p.stats.rarest]
		if not rarest or aura.rarity > rarest.rarity then
			p.stats.rarest = auraId
		end
	end
	return true
end

-- Remove `count` of an aura; returns true if successful. Auto-unequips if the
-- last copy is removed.
function Core.RemoveAura(player, auraId, count)
	local p = Profiles[player.UserId]
	if not p then return false end
	count = count or 1
	local have = p.inventory[auraId] or 0
	if have < count then return false end
	have -= count
	if have <= 0 then
		p.inventory[auraId] = nil
		if p.equipped == auraId then
			p.equipped = nil
			Core.ApplyAuraVisual(player)
		end
	else
		p.inventory[auraId] = have
	end
	return true
end

function Core.EquipAura(player, auraId)
	local p = Profiles[player.UserId]
	if not p then return false end
	if auraId ~= nil and (p.inventory[auraId] or 0) <= 0 then
		return false
	end
	p.equipped = auraId
	Core.ApplyAuraVisual(player)
	return true
end

-- ── Global counts ────────────────────────────────────────────────────────────
function Core.IncrementGlobal(auraId, amount)
	amount = amount or 1
	GlobalCounts[auraId] = (GlobalCounts[auraId] or 0) + amount
	GlobalDeltas[auraId] = (GlobalDeltas[auraId] or 0) + amount
end

function Core.GetGlobalCounts()
	return GlobalCounts
end

local function loadGlobal()
	local ok, data = pcall(function()
		return globalStore:GetAsync("counts")
	end)
	if ok and type(data) == "table" then
		for id, n in pairs(data) do
			GlobalCounts[tonumber(id) or id] = n
		end
	end
end

local function saveGlobal()
	if next(GlobalDeltas) == nil then return end
	local deltas = GlobalDeltas
	GlobalDeltas = {}
	local ok, merged = pcall(function()
		return globalStore:UpdateAsync("counts", function(old)
			old = old or {}
			for id, d in pairs(deltas) do
				old[id] = (old[id] or 0) + d
			end
			return old
		end)
	end)
	if ok and type(merged) == "table" then
		-- Adopt the authoritative merged totals.
		for id, n in pairs(merged) do
			GlobalCounts[tonumber(id) or id] = n
		end
	else
		-- Save failed: re-queue the deltas so we don't lose them.
		for id, d in pairs(deltas) do
			GlobalDeltas[id] = (GlobalDeltas[id] or 0) + d
		end
	end
end

-- ── Aura visual effect on the character ──────────────────────────────────────
function Core.ApplyAuraVisual(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Clear any previous effect.
	local existing = root:FindFirstChild("AuraEffect")
	if existing then existing:Destroy() end

	local p = Profiles[player.UserId]
	if not p or not p.equipped then return end
	local aura = AuraData.ById[p.equipped]
	if not aura then return end

	local holder = Instance.new("Attachment")
	holder.Name = "AuraEffect"
	holder.Parent = root

	local light = Instance.new("PointLight")
	light.Color = aura.c1
	light.Range = 14
	light.Brightness = 3
	light.Parent = holder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(aura.c1, aura.c2)
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new(0.6)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = math.clamp(5 + math.log10(aura.rarity) * 4, 8, 60)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = holder
end

-- ── Persistence ──────────────────────────────────────────────────────────────
local function loadPlayer(player)
	local profile = defaultProfile()
	local ok, data = pcall(function()
		return playerStore:GetAsync("u_" .. player.UserId)
	end)
	if ok and type(data) == "table" then
		profile.coins     = data.coins or profile.coins
		profile.luckBonus = data.luckBonus or 0
		profile.equipped  = data.equipped
		profile.inventory = data.inventory or {}
		profile.coinMult  = data.coinMult or 1
		profile.stats     = data.stats or profile.stats
		profile.lastDaily = data.lastDaily or 0
		-- Inventory keys come back as strings from JSON; normalize to numbers.
		local fixed = {}
		for id, count in pairs(profile.inventory) do
			fixed[tonumber(id) or id] = count
		end
		profile.inventory = fixed
		if profile.equipped then profile.equipped = tonumber(profile.equipped) or profile.equipped end
		if profile.stats.rarest then profile.stats.rarest = tonumber(profile.stats.rarest) or profile.stats.rarest end
	end
	Profiles[player.UserId] = profile
end

local function savePlayer(player)
	local p = Profiles[player.UserId]
	if not p then return end
	pcall(function()
		playerStore:SetAsync("u_" .. player.UserId, {
			coins     = p.coins,
			luckBonus = p.luckBonus,
			equipped  = p.equipped,
			inventory = p.inventory,
			coinMult  = p.coinMult,
			stats     = p.stats,
			lastDaily = p.lastDaily,
		})
	end)
end
Core.SavePlayer = savePlayer

-- ── Lifecycle ────────────────────────────────────────────────────────────────
local started = false
function Core.Init()
	if started then return end
	started = true

	loadGlobal()

	Players.PlayerAdded:Connect(function(player)
		loadPlayer(player)

		player.CharacterAdded:Connect(function()
			-- leaderstats for the default Roblox leaderboard.
			local ls = player:FindFirstChild("leaderstats")
			if not ls then
				ls = Instance.new("Folder")
				ls.Name = "leaderstats"
				ls.Parent = player
			end
			local coins = ls:FindFirstChild("Coins") or Instance.new("IntValue")
			coins.Name = "Coins"
			coins.Parent = ls

			task.wait(0.4)
			Core.ApplyAuraVisual(player)
			Core.Push(player)
		end)

		-- Keep the leaderboard coin value in sync.
		task.spawn(function()
			while Profiles[player.UserId] do
				local ls = player:FindFirstChild("leaderstats")
				local coins = ls and ls:FindFirstChild("Coins")
				local p = Profiles[player.UserId]
				if coins and p then coins.Value = p.coins end
				task.wait(1)
			end
		end)

		Core.Push(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player)
		Profiles[player.UserId] = nil
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
		saveGlobal()
	end)

	-- Auto-save loops.
	task.spawn(function()
		while true do
			task.wait(GameConfig.DataStore.AutoSaveInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				savePlayer(player)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.DataStore.GlobalSaveInterval)
			saveGlobal()
		end
	end)

	-- Provide global counts to clients on request.
	Core.Remotes.GlobalCounts.OnServerInvoke = function()
		return GlobalCounts
	end

	print(string.format("[%s] Core initialized (v%s). %d auras loaded.",
		GameConfig.GAME_NAME, GameConfig.VERSION, AuraData.Count))
end

return Core
