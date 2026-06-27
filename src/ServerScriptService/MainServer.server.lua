-- Aura RNG | MainServer (bootstrap)
-- Initializes Core, wires up gamepass ownership, the daily bonus, and a small
-- admin /give command for testing.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Core       = require(script.Parent:WaitForChild("Core"))

Core.Init()

-- ── Gamepass ownership ───────────────────────────────────────────────────────
local function applyGamepasses(player)
	local profile = Core.GetProfile(player)
	if not profile then return end
	for name, info in pairs(GameConfig.Monetization.Gamepasses) do
		if info.id and info.id > 0 then
			local owns = false
			local ok, res = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, info.id)
			end)
			if ok then owns = res end
			if owns and not profile.gamepasses[name] then
				profile.gamepasses[name] = true
				profile.luckBonus += (info.luck or 0)
				if name == "VIP" then profile.coinMult = math.max(profile.coinMult, 2) end
			end
		end
	end
	Core.Push(player)
end

-- Grant a gamepass live when purchased mid-session.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then return end
	local profile = Core.GetProfile(player)
	if not profile then return end
	for name, info in pairs(GameConfig.Monetization.Gamepasses) do
		if info.id == passId and not profile.gamepasses[name] then
			profile.gamepasses[name] = true
			profile.luckBonus += (info.luck or 0)
			if name == "VIP" then profile.coinMult = math.max(profile.coinMult, 2) end
			Core.Notify(player, "Unlocked " .. info.name .. "!", "success")
			Core.Push(player)
		end
	end
end)

-- ── Daily bonus ──────────────────────────────────────────────────────────────
local function tryDailyBonus(player)
	local profile = Core.GetProfile(player)
	if not profile then return end
	local now = os.time()
	if now - (profile.lastDaily or 0) >= 86400 then
		profile.lastDaily = now
		Core.AddCoins(player, GameConfig.Economy.DailyBonus)
		Core.Notify(player, "Daily bonus: +" .. GameConfig.Economy.DailyBonus .. " coins!", "success")
		Core.Push(player)
	end
end

-- ── Admin test command ───────────────────────────────────────────────────────
local function isAdmin(player)
	for _, id in ipairs(GameConfig.Admins) do
		if id == player.UserId then return true end
	end
	return false
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1) -- let Core load the profile first
	applyGamepasses(player)
	tryDailyBonus(player)

	player.Chatted:Connect(function(message)
		if not isAdmin(player) then return end
		local cmd, arg = message:match("^/(%a+)%s*(%S*)")
		if cmd == "give" then
			Core.AddCoins(player, tonumber(arg) or 100000)
			Core.Notify(player, "Granted coins.", "success")
			Core.Push(player)
		elseif cmd == "luck" then
			local p = Core.GetProfile(player)
			if p then p.luckBonus += (tonumber(arg) or 100); Core.Push(player) end
		end
	end)
end)

print("[" .. GameConfig.GAME_NAME .. "] MainServer ready.")
