-- Aura RNG | Trade window
-- Two modes inside one window:
--   • Lobby  – lists nearby players you can invite to trade.
--   • Session – your offer vs. their offer, add/remove from your inventory,
--               confirm with a safety countdown.
-- Incoming invites surface as a small accept/decline popup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraData   = require(ReplicatedStorage:WaitForChild("AuraData"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Util       = require(ReplicatedStorage:WaitForChild("Util"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local C     = require(script.Parent:WaitForChild("Components"))

local LocalPlayer = Players.LocalPlayer

local Trade = {}

local function distanceTo(other)
	local a = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local b = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
	if not (a and b) then return math.huge end
	return (a.Position - b.Position).Magnitude
end

function Trade.Init(ctx)
	local _, content, controller = C.window(ctx.screenGui, "🤝 Trade", UDim2.fromOffset(760, 520))
	ctx.registerWindow("Trade", controller)

	-- ── Lobby view ──────────────────────────────────────────────────────────
	local lobby = C.frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7 })
	lobby.Parent = content
	local lobbyTitle = C.label({
		Text = "Nearby players (within " .. GameConfig.Trade.MaxRange .. " studs):",
		TextColor3 = Theme.Color.SubText, TextSize = 15,
		Size = UDim2.new(1, 0, 0, 24), ZIndex = 8,
	})
	lobbyTitle.Parent = lobby
	local lobbyList = C.scrollList({
		Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 28), ZIndex = 8,
	}, nil, 8)
	lobbyList.Parent = lobby

	local function refreshLobby()
		for _, ch in ipairs(lobbyList:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end
		local found = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and distanceTo(plr) <= GameConfig.Trade.MaxRange then
				found += 1
				local row = C.frame({
					Size = UDim2.new(1, -6, 0, 50), BackgroundColor3 = Theme.Color.Card, ZIndex = 9,
				})
				C.corner(row)
				local name = C.label({
					Text = "👤 " .. plr.DisplayName .. "  (@" .. plr.Name .. ")",
					Font = Theme.FontBold, TextSize = 16,
					Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(12, 0), ZIndex = 10,
				})
				name.Parent = row
				local btn = C.button({
					Size = UDim2.fromOffset(130, 36),
					Position = UDim2.new(1, -140, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
					Text = "Invite", TextSize = 15, ZIndex = 10,
				}, { color = Theme.Color.Accent })
				btn.Parent = row
				btn.MouseButton1Click:Connect(function()
					ctx.remotes.TradeRequest:FireServer(plr.UserId)
				end)
				row.Parent = lobbyList
			end
		end
		if found == 0 then
			lobbyTitle.Text = "No players nearby. Walk up to someone on the Trading Plaza!"
		else
			lobbyTitle.Text = "Nearby players (within " .. GameConfig.Trade.MaxRange .. " studs):"
		end
	end

	-- ── Session view ────────────────────────────────────────────────────────
	local session = C.frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 7 })
	session.Parent = content

	local function makeColumn(titleText, xScale)
		local col = C.frame({
			Size = UDim2.new(0.5, -8, 1, -100),
			Position = UDim2.new(xScale, xScale == 0 and 0 or 8, 0, 0),
			BackgroundColor3 = Theme.Color.Panel, ZIndex = 8,
		})
		C.corner(col)
		local t = C.label({
			Text = titleText, Font = Theme.FontBold, TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 6), ZIndex = 9,
		})
		t.Parent = col
		local grid = C.scrollGrid({
			Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 32), ZIndex = 9,
		}, UDim2.fromOffset(96, 110), 6, 4)
		grid.Parent = col
		return col, t, grid
	end

	local _, yourTitle, yourGrid = makeColumn("Your Offer", 0)
	local _, theirTitle, theirGrid = makeColumn("Their Offer", 0.5)

	-- Inventory strip to add auras from.
	local invStrip = C.frame({
		Size = UDim2.new(1, 0, 0, 56), Position = UDim2.new(0, 0, 1, -94),
		AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Color.Bg, ZIndex = 8,
	})
	invStrip.Parent = session
	C.corner(invStrip)
	local invScroll = Instance.new("ScrollingFrame")
	invScroll.BackgroundTransparency = 1
	invScroll.BorderSizePixel = 0
	invScroll.Size = UDim2.new(1, -8, 1, -8)
	invScroll.Position = UDim2.fromOffset(4, 4)
	invScroll.ScrollingDirection = Enum.ScrollingDirection.X
	invScroll.ScrollBarThickness = 4
	invScroll.CanvasSize = UDim2.new()
	invScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	invScroll.ZIndex = 9
	invScroll.Parent = invStrip
	local invLayout = Instance.new("UIListLayout")
	invLayout.FillDirection = Enum.FillDirection.Horizontal
	invLayout.Padding = UDim.new(0, 6)
	invLayout.Parent = invScroll

	-- Confirm / cancel bar.
	local confirmBtn = C.button({
		Size = UDim2.fromOffset(220, 34), Position = UDim2.new(0, 0, 1, -34),
		Text = "✓ Confirm Trade", TextSize = 16, ZIndex = 9,
	}, { color = Theme.Color.Good })
	confirmBtn.Parent = session
	local statusLbl = C.label({
		Text = "", TextSize = 14, TextColor3 = Theme.Color.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 280, 0, 34), Position = UDim2.new(0.5, -140, 1, -34), ZIndex = 9,
	})
	statusLbl.Parent = session
	local cancelBtn = C.button({
		Size = UDim2.fromOffset(140, 34), Position = UDim2.new(1, -140, 1, -34),
		Text = "✕ Cancel", TextSize = 16, ZIndex = 9,
	}, { color = Theme.Color.Bad })
	cancelBtn.Parent = session

	local myConfirmed = false
	confirmBtn.MouseButton1Click:Connect(function()
		myConfirmed = not myConfirmed
		ctx.remotes.TradeConfirm:FireServer(myConfirmed)
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		ctx.remotes.TradeCancel:FireServer()
	end)

	-- Build a small aura chip.
	local function chip(aura, parent, onClick, countText)
		local f = C.frame({ Size = UDim2.fromOffset(90, 100), BackgroundColor3 = Theme.Color.Card, ZIndex = 10 })
		C.corner(f, UDim.new(0, 8))
		C.stroke(f, AuraData.GetTier(aura.rarity).color, 1.5, 0.3)
		local orb = C.frame({
			Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, 0, 0, 8),
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 11,
		})
		orb.Parent = f
		C.corner(orb, UDim.new(1, 0))
		C.gradient(orb, aura.c1, aura.c2, 60)
		local n = C.label({
			Text = aura.name, TextSize = 11, Font = Theme.FontBold,
			TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -4, 0, 14), Position = UDim2.fromOffset(2, 52), ZIndex = 11,
		})
		n.Parent = f
		local r = C.label({
			Text = countText or Util.FormatRarity(aura.rarity), TextSize = 10,
			TextColor3 = Theme.Color.SubText, TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, -4, 0, 12), Position = UDim2.fromOffset(2, 68), ZIndex = 11,
		})
		r.Parent = f
		if onClick then
			local b = Instance.new("TextButton")
			b.BackgroundTransparency = 1
			b.Text = ""
			b.Size = UDim2.fromScale(1, 1)
			b.ZIndex = 12
			b.Parent = f
			b.MouseButton1Click:Connect(onClick)
		end
		f.Parent = parent
		return f
	end

	-- Refresh the inventory strip (auras you can still add).
	local lastState = nil
	local function refreshInvStrip()
		for _, ch in ipairs(invScroll:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end
		local profile = ctx.getProfile()
		if not profile then return end
		-- Count what's already offered.
		local offered = {}
		if lastState then
			for _, o in ipairs(lastState.yourOffer or {}) do offered[o.id] = o.count end
		end
		for _, item in ipairs(profile.inventory or {}) do
			local remaining = item.count - (offered[item.id] or 0)
			if remaining > 0 then
				local aura = AuraData.ById[item.id]
				if aura then
					chip(aura, invScroll, function()
						ctx.remotes.TradeOffer:FireServer(item.id, true)
					end, "x" .. remaining .. " · add")
				end
			end
		end
	end

	local function renderSession(state)
		lastState = state
		yourTitle.Text = "Your Offer" .. (state.yourConfirm and "  ✓" or "")
		theirTitle.Text = (state.otherName or "Their") .. "'s Offer" .. (state.theirConfirm and "  ✓" or "")

		for _, ch in ipairs(yourGrid:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
		for _, ch in ipairs(theirGrid:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end

		for _, o in ipairs(state.yourOffer or {}) do
			local aura = AuraData.ById[o.id]
			if aura then
				chip(aura, yourGrid, function()
					ctx.remotes.TradeOffer:FireServer(o.id, false)
				end, "x" .. o.count .. " · remove")
			end
		end
		for _, o in ipairs(state.theirOffer or {}) do
			local aura = AuraData.ById[o.id]
			if aura then chip(aura, theirGrid, nil, "x" .. o.count) end
		end

		if state.countdown then
			statusLbl.Text = "Completing in " .. state.countdown .. "…"
			statusLbl.TextColor3 = Theme.Color.Warn
		elseif state.yourConfirm and state.theirConfirm then
			statusLbl.Text = "Both confirmed!"
			statusLbl.TextColor3 = Theme.Color.Good
		else
			statusLbl.Text = "Add auras, then confirm."
			statusLbl.TextColor3 = Theme.Color.SubText
		end
		myConfirmed = state.yourConfirm
		confirmBtn.Text = state.yourConfirm and "✓ Confirmed (click to unready)" or "✓ Confirm Trade"
		confirmBtn.BackgroundColor3 = state.yourConfirm and Theme.Color.Stroke or Theme.Color.Good

		refreshInvStrip()
	end

	local function showLobby()
		lobby.Visible = true
		session.Visible = false
		refreshLobby()
	end
	local function showSession(state)
		lobby.Visible = false
		session.Visible = true
		renderSession(state)
	end

	-- ── Remote hooks ────────────────────────────────────────────────────────
	ctx.remotes.TradeUpdate.OnClientEvent:Connect(function(state)
		if state.active then
			if not controller.isOpen() then controller.show() end
			showSession(state)
		else
			myConfirmed = false
			lastState = nil
			showLobby()
		end
	end)

	-- Incoming invite popup.
	local invitePopup = C.frame({
		Name = "TradeInvitePopup",
		Size = UDim2.fromOffset(320, 130),
		Position = UDim2.new(0.5, 0, 0, 80),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Color.Panel,
		Visible = false, ZIndex = 40,
	})
	invitePopup.Parent = ctx.screenGui
	C.corner(invitePopup)
	C.stroke(invitePopup, Theme.Color.Accent, 2)
	local inviteText = C.label({
		Text = "", TextSize = 16, Font = Theme.FontBold, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 56), Position = UDim2.fromOffset(10, 10), ZIndex = 41,
	})
	inviteText.Parent = invitePopup
	local accept = C.button({
		Size = UDim2.fromOffset(130, 40), Position = UDim2.fromOffset(20, 78),
		Text = "Accept", TextSize = 15, ZIndex = 41,
	}, { color = Theme.Color.Good })
	accept.Parent = invitePopup
	local decline = C.button({
		Size = UDim2.fromOffset(130, 40), Position = UDim2.new(1, -150, 0, 78),
		Text = "Decline", TextSize = 15, ZIndex = 41,
	}, { color = Theme.Color.Bad })
	decline.Parent = invitePopup

	local pendingFrom = nil
	ctx.remotes.TradeInvite.OnClientEvent:Connect(function(data)
		pendingFrom = data.fromId
		inviteText.Text = "👤 " .. data.fromName .. " wants to trade with you!"
		invitePopup.Visible = true
		task.delay(15, function()
			if pendingFrom == data.fromId then invitePopup.Visible = false; pendingFrom = nil end
		end)
	end)
	accept.MouseButton1Click:Connect(function()
		if pendingFrom then
			ctx.remotes.TradeRespond:FireServer(pendingFrom, true)
			pendingFrom = nil
			invitePopup.Visible = false
		end
	end)
	decline.MouseButton1Click:Connect(function()
		if pendingFrom then
			ctx.remotes.TradeRespond:FireServer(pendingFrom, false)
			pendingFrom = nil
			invitePopup.Visible = false
		end
	end)

	-- Refresh inventory strip / lobby when profile changes mid-trade.
	ctx.onProfile(function()
		if session.Visible then refreshInvStrip() end
		if lobby.Visible and controller.isOpen() then refreshLobby() end
	end)

	local origShow = controller.show
	controller.show = function()
		origShow()
		if not session.Visible then showLobby() end
	end
end

return Trade
