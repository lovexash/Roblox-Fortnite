-- Aura RNG | TradeSystem
-- Player-to-player aura trading. A trade session is created after an invite is
-- accepted; each side adds auras to their offer, both confirm, and after a
-- short countdown (during which any change cancels the confirm) the auras are
-- swapped atomically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AuraData   = require(ReplicatedStorage:WaitForChild("AuraData"))
local Core       = require(script.Parent:WaitForChild("Core"))

local Remotes = Core.Remotes

-- userId -> sessionId; sessionId -> session table
local sessionOf = {}
local sessions  = {}
local invites   = {} -- targetUserId -> fromUserId (pending)

local function newSession(a, b)
	return {
		id = tostring(a) .. "_" .. tostring(b) .. "_" .. tostring(os.clock()),
		players = { a, b },
		offers  = { [a] = {}, [b] = {} },  -- list of aura ids (duplicates allowed)
		confirm = { [a] = false, [b] = false },
		countdown = nil,
	}
end

local function otherUser(session, userId)
	return session.players[1] == userId and session.players[2] or session.players[1]
end

-- How many of `auraId` a player has already placed in the current offer.
local function offeredCount(session, userId, auraId)
	local n = 0
	for _, id in ipairs(session.offers[userId]) do
		if id == auraId then n += 1 end
	end
	return n
end

local function buildOfferList(session, userId)
	-- Collapse the offer into {id, count} pairs for the client.
	local counts = {}
	for _, id in ipairs(session.offers[userId]) do
		counts[id] = (counts[id] or 0) + 1
	end
	local out = {}
	for id, count in pairs(counts) do
		out[#out + 1] = { id = id, count = count }
	end
	return out
end

local function pushSession(session)
	for _, userId in ipairs(session.players) do
		local player = Players:GetPlayerByUserId(userId)
		local other  = Players:GetPlayerByUserId(otherUser(session, userId))
		if player then
			Remotes.TradeUpdate:FireClient(player, {
				active     = true,
				otherName  = other and other.Name or "?",
				otherId    = otherUser(session, userId),
				yourOffer  = buildOfferList(session, userId),
				theirOffer = buildOfferList(session, otherUser(session, userId)),
				yourConfirm  = session.confirm[userId],
				theirConfirm = session.confirm[otherUser(session, userId)],
				countdown  = session.countdown,
			})
		end
	end
end

local function endSession(session, reason)
	for _, userId in ipairs(session.players) do
		sessionOf[userId] = nil
		local player = Players:GetPlayerByUserId(userId)
		if player then
			Remotes.TradeUpdate:FireClient(player, { active = false, reason = reason })
			if reason then Core.Notify(player, reason, "info") end
		end
	end
	sessions[session.id] = nil
end

local function resetConfirms(session)
	session.confirm[session.players[1]] = false
	session.confirm[session.players[2]] = false
	session.countdown = nil
end

-- Are the two players close enough to trade?
local function inRange(a, b)
	local pa = Players:GetPlayerByUserId(a)
	local pb = Players:GetPlayerByUserId(b)
	if not (pa and pb) then return false end
	local ca, cb = pa.Character, pb.Character
	local ra = ca and ca:FindFirstChild("HumanoidRootPart")
	local rb = cb and cb:FindFirstChild("HumanoidRootPart")
	if not (ra and rb) then return false end
	return (ra.Position - rb.Position).Magnitude <= GameConfig.Trade.MaxRange
end

-- ── Invite ───────────────────────────────────────────────────────────────────
Remotes.TradeRequest.OnServerEvent:Connect(function(player, targetUserId)
	targetUserId = tonumber(targetUserId)
	if not targetUserId or targetUserId == player.UserId then return end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return end
	if sessionOf[player.UserId] or sessionOf[targetUserId] then
		Core.Notify(player, "One of you is already in a trade.", "error")
		return
	end
	if not inRange(player.UserId, targetUserId) then
		Core.Notify(player, "You must be near that player to trade.", "error")
		return
	end
	invites[targetUserId] = player.UserId
	Remotes.TradeInvite:FireClient(target, { fromId = player.UserId, fromName = player.Name })
	Core.Notify(player, "Trade request sent to " .. target.Name .. ".", "info")
end)

-- ── Respond ──────────────────────────────────────────────────────────────────
Remotes.TradeRespond.OnServerEvent:Connect(function(player, fromUserId, accept)
	fromUserId = tonumber(fromUserId)
	if invites[player.UserId] ~= fromUserId then return end
	invites[player.UserId] = nil
	local from = Players:GetPlayerByUserId(fromUserId)
	if not from then return end
	if not accept then
		Core.Notify(from, player.Name .. " declined the trade.", "info")
		return
	end
	if sessionOf[player.UserId] or sessionOf[fromUserId] then return end

	local session = newSession(fromUserId, player.UserId)
	sessions[session.id] = session
	sessionOf[fromUserId] = session.id
	sessionOf[player.UserId] = session.id
	pushSession(session)
end)

-- ── Offer (add/remove an aura) ───────────────────────────────────────────────
Remotes.TradeOffer.OnServerEvent:Connect(function(player, auraId, add)
	local sid = sessionOf[player.UserId]
	local session = sid and sessions[sid]
	if not session then return end
	if not AuraData.ById[auraId] then return end
	local profile = Core.GetProfile(player)
	if not profile then return end

	resetConfirms(session)

	if add then
		if #session.offers[player.UserId] >= GameConfig.Trade.MaxItemsPerSide then
			Core.Notify(player, "Offer is full.", "error")
			return
		end
		local owned = profile.inventory[auraId] or 0
		if offeredCount(session, player.UserId, auraId) >= owned then
			Core.Notify(player, "You don't have more of that aura to offer.", "error")
			return
		end
		table.insert(session.offers[player.UserId], auraId)
	else
		-- remove one instance
		for i, id in ipairs(session.offers[player.UserId]) do
			if id == auraId then
				table.remove(session.offers[player.UserId], i)
				break
			end
		end
	end
	pushSession(session)
end)

-- ── Confirm / complete ───────────────────────────────────────────────────────
local function offersStillValid(session)
	for _, userId in ipairs(session.players) do
		local profile = Core.GetProfile(Players:GetPlayerByUserId(userId) or {})
		if not profile then return false end
		local need = {}
		for _, id in ipairs(session.offers[userId]) do need[id] = (need[id] or 0) + 1 end
		for id, count in pairs(need) do
			if (profile.inventory[id] or 0) < count then return false end
		end
	end
	return true
end

local function completeTrade(session)
	if not offersStillValid(session) then
		endSession(session, "Trade failed: an offered aura was no longer available.")
		return
	end
	local a, b = session.players[1], session.players[2]
	local pa = Players:GetPlayerByUserId(a)
	local pb = Players:GetPlayerByUserId(b)
	if not (pa and pb) then
		endSession(session, "Trade cancelled: a player left.")
		return
	end

	-- Remove each side's offer, then grant to the other side.
	for _, id in ipairs(session.offers[a]) do Core.RemoveAura(pa, id, 1) end
	for _, id in ipairs(session.offers[b]) do Core.RemoveAura(pb, id, 1) end
	for _, id in ipairs(session.offers[a]) do Core.AddAura(pb, id, 1) end
	for _, id in ipairs(session.offers[b]) do Core.AddAura(pa, id, 1) end

	Core.Push(pa)
	Core.Push(pb)
	Core.Notify(pa, "Trade complete!", "success")
	Core.Notify(pb, "Trade complete!", "success")
	endSession(session)
end

Remotes.TradeConfirm.OnServerEvent:Connect(function(player, state)
	local sid = sessionOf[player.UserId]
	local session = sid and sessions[sid]
	if not session then return end
	session.confirm[player.UserId] = state and true or false

	if session.confirm[session.players[1]] and session.confirm[session.players[2]] then
		-- Both confirmed: start the countdown guard.
		session.countdown = GameConfig.Trade.ConfirmCountdown
		pushSession(session)
		task.spawn(function()
			local token = session.countdown
			for t = GameConfig.Trade.ConfirmCountdown, 1, -1 do
				if not sessions[session.id] then return end
				if not (session.confirm[session.players[1]] and session.confirm[session.players[2]]) then
					session.countdown = nil
					pushSession(session)
					return
				end
				session.countdown = t
				pushSession(session)
				task.wait(1)
			end
			if sessions[session.id]
				and session.confirm[session.players[1]]
				and session.confirm[session.players[2]] then
				completeTrade(session)
			end
		end)
	else
		pushSession(session)
	end
end)

-- ── Cancel / cleanup ─────────────────────────────────────────────────────────
Remotes.TradeCancel.OnServerEvent:Connect(function(player)
	local sid = sessionOf[player.UserId]
	local session = sid and sessions[sid]
	if session then
		endSession(session, player.Name .. " cancelled the trade.")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	invites[player.UserId] = nil
	local sid = sessionOf[player.UserId]
	if sid and sessions[sid] then
		endSession(sessions[sid], player.Name .. " left the trade.")
	end
end)

print("[Aura RNG] TradeSystem ready.")
