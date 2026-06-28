-- Aura RNG | ShopSystem
-- Inventory actions (equip / sell) plus the coin shop (potions), the capsule
-- shop (coins or Robux), and Robux developer-product receipts.

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AuraData    = require(ReplicatedStorage:WaitForChild("AuraData"))
local ShopData    = require(ReplicatedStorage:WaitForChild("ShopData"))
local CapsuleData = require(ReplicatedStorage:WaitForChild("CapsuleData"))
local Core        = require(script.Parent:WaitForChild("Core"))

-- ── Equip ────────────────────────────────────────────────────────────────────
Core.Remotes.EquipAura.OnServerEvent:Connect(function(player, auraId)
	if auraId ~= nil and not AuraData.ById[auraId] then return end
	if Core.EquipAura(player, auraId) then
		Core.Push(player)
	end
end)

-- ── Sell / delete ────────────────────────────────────────────────────────────
Core.Remotes.DeleteAura.OnServerEvent:Connect(function(player, auraId, qty)
	local aura = AuraData.ById[auraId]
	if not aura then return end
	qty = math.max(1, math.floor(tonumber(qty) or 1))
	local profile = Core.GetProfile(player)
	if not profile then return end
	qty = math.min(qty, profile.inventory[auraId] or 0)
	if qty <= 0 then return end

	if Core.RemoveAura(player, auraId, qty) then
		local payout = math.floor(aura.value * GameConfig.Economy.SellMultiplier) * qty
		Core.AddCoins(player, payout)
		Core.Notify(player, string.format("Sold %dx %s for %d coins.", qty, aura.name, payout), "info")
		Core.Push(player)
	end
end)

-- ── Potions (coins) ──────────────────────────────────────────────────────────
Core.Remotes.BuyPotion.OnServerEvent:Connect(function(player, potionId)
	local def = ShopData.ById[potionId]
	if not def then return end
	local profile = Core.GetProfile(player)
	if not profile then return end
	if profile.coins < def.price then
		Core.Notify(player, "Not enough coins.", "error")
		return
	end
	Core.AddCoins(player, -def.price)
	-- Refresh/extend the same potion rather than stacking duplicates.
	local now = os.time()
	local found
	for _, active in ipairs(profile.potions) do
		if active.id == potionId then found = active break end
	end
	if found then
		found.expires = math.max(found.expires, now) + def.duration
	else
		profile.potions[#profile.potions + 1] = { id = potionId, expires = now + def.duration }
	end
	Core.Notify(player, def.name .. " active!", "success")
	Core.Push(player)
end)

-- ── Capsules ─────────────────────────────────────────────────────────────────
local function openCapsule(player, capsule)
	local results = {}
	for _ = 1, (capsule.rolls or 1) do
		local aura = AuraData.RollFromPool(capsule.pool, capsule.luck)
		Core.AddAura(player, aura.id, 1)
		Core.IncrementGlobal(aura.id, 1)
		results[#results + 1] = {
			id = aura.id, rarity = aura.rarity, exists = Core.GetGlobalCounts()[aura.id] or 0,
		}
		-- Auto-equip the best one pulled.
		local profile = Core.GetProfile(player)
		local equipped = profile.equipped and AuraData.ById[profile.equipped]
		if not equipped or aura.rarity > equipped.rarity then
			Core.EquipAura(player, aura.id)
		end
	end
	Core.Remotes.RollResult:FireClient(player, {
		multi   = true,
		capsule = capsule.id,
		luck    = capsule.luck,
		results = results,
	})
	Core.Push(player)
end

-- Coin purchase path.
Core.Remotes.BuyCapsule.OnServerEvent:Connect(function(player, capsuleId)
	local capsule = CapsuleData.ById[capsuleId]
	if not capsule or not capsule.coinPrice then return end
	local profile = Core.GetProfile(player)
	if not profile then return end
	if profile.coins < capsule.coinPrice then
		Core.Notify(player, "Not enough coins for this capsule.", "error")
		return
	end
	Core.AddCoins(player, -capsule.coinPrice)
	openCapsule(player, capsule)
end)

-- Robux prompt path (client asks server to prompt a purchase).
Core.Remotes.PromptProduct.OnServerEvent:Connect(function(player, kind, key)
	if kind == "capsule" then
		local capsule = CapsuleData.ById[key]
		if capsule and capsule.productId and capsule.productId > 0 then
			MarketplaceService:PromptProductPurchase(player, capsule.productId)
		else
			Core.Notify(player, "This capsule's Robux id isn't configured yet.", "error")
		end
	elseif kind == "gamepass" then
		local info = GameConfig.Monetization.Gamepasses[key]
		if info and info.id and info.id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, info.id)
		else
			Core.Notify(player, "This pass's id isn't configured yet.", "error")
		end
	elseif kind == "product" then
		local info = GameConfig.Monetization.Products[key]
		if info and info.id and info.id > 0 then
			MarketplaceService:PromptProductPurchase(player, info.id)
		else
			Core.Notify(player, "This product's id isn't configured yet.", "error")
		end
	end
end)

-- ── Receipt processing for developer products ───────────────────────────────
-- Build a productId -> handler lookup from config + capsules.
local productHandlers = {}
for key, info in pairs(GameConfig.Monetization.Products) do
	if info.id and info.id > 0 then
		productHandlers[info.id] = function(player)
			Core.AddCoins(player, info.coins or 0)
			Core.Notify(player, "Purchased " .. info.name .. "!", "success")
			Core.Push(player)
		end
	end
end
for _, capsule in ipairs(CapsuleData.List) do
	if capsule.productId and capsule.productId > 0 then
		productHandlers[capsule.productId] = function(player)
			openCapsule(player, capsule)
		end
	end
end

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local handler = productHandlers[receipt.ProductId]
	if handler then
		local ok = pcall(handler, player)
		if ok then
			Core.SavePlayer(player) -- persist the granted purchase immediately
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Unknown product: grant so the player isn't charged repeatedly.
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

print("[Aura RNG] ShopSystem ready.")
