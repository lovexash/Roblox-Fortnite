-- Aura RNG | RollReveal
-- The dramatic center reveal that plays whenever RollResult arrives. Handles
-- single rolls (with a suspenseful rarity "spin") and multi-roll capsules
-- (a row of result cards). Rarer auras get a longer, flashier reveal.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local Util     = require(ReplicatedStorage:WaitForChild("Util"))

local Theme    = require(script.Parent:WaitForChild("Theme"))
local C        = require(script.Parent:WaitForChild("Components"))
local AuraCard = require(script.Parent:WaitForChild("AuraCard"))

local RollReveal = {}

function RollReveal.Init(ctx)
	local sg = ctx.screenGui

	-- Full-screen flash used for high-rarity reveals.
	local flash = C.frame({
		Name = "RevealFlash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 30,
	})
	flash.Parent = sg
	flash.Active = false

	-- ── Single reveal card ──────────────────────────────────────────────────
	local card = C.frame({
		Name = "RevealCard",
		Size = UDim2.fromOffset(340, 180),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Color.Bg,
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 31,
	})
	card.Parent = sg
	C.corner(card, UDim.new(0, 16))
	local cardStroke = C.stroke(card, Theme.Color.Accent, 2.5, 1)

	local orb = C.frame({
		Size = UDim2.fromOffset(80, 80),
		Position = UDim2.new(0.5, 0, 0, -30),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 32,
	})
	orb.Parent = card
	C.corner(orb, UDim.new(1, 0))
	local orbGrad = C.gradient(orb, Theme.Color.Accent, Theme.Color.Accent2, 60)
	C.stroke(orb, Color3.new(1, 1, 1), 3, 0.3)

	local nameLbl = C.label({
		Text = "", Font = Theme.FontBlack, TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 38), Position = UDim2.fromOffset(10, 58), ZIndex = 32,
	})
	nameLbl.Parent = card

	local rarityLbl = C.label({
		Text = "", Font = Theme.FontBold, TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 98), ZIndex = 32,
	})
	rarityLbl.Parent = card

	local subLbl = C.label({
		Text = "", TextSize = 14, TextColor3 = Theme.Color.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 126), ZIndex = 32,
	})
	subLbl.Parent = card

	local newTag = C.label({
		Text = "✨ NEW ✨", Font = Theme.FontBlack, TextSize = 16,
		TextColor3 = Theme.Color.Gold, TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 148),
		Visible = false, ZIndex = 32,
	})
	newTag.Parent = card

	-- Track which auras the player has already seen (for the NEW tag).
	local seen = {}
	ctx.onProfile(function(profile)
		for _, item in ipairs(profile.inventory or {}) do
			seen[item.id] = true
		end
	end)

	local revealToken = 0

	local function playSingle(data)
		revealToken += 1
		local myToken = revealToken
		local aura = AuraData.ById[data.id]
		if not aura then return end
		local tier = AuraData.GetTier(aura.rarity)
		local isNew = not seen[aura.id]
		seen[aura.id] = true

		-- Longer suspense for rarer auras (capped).
		local suspense = math.clamp(math.log10(aura.rarity) * 0.12, 0.25, 1.1)

		card.Visible = true
		card.BackgroundTransparency = 0.05
		cardStroke.Color = tier.color
		cardStroke.Transparency = 0
		newTag.Visible = false
		nameLbl.TextColor3 = tier.color
		rarityLbl.TextColor3 = tier.color

		-- Suspense "spin": flash random rarities before landing.
		nameLbl.Text = "ROLLING…"
		subLbl.Text = ""
		local spinStart = os.clock()
		task.spawn(function()
			while os.clock() - spinStart < suspense and myToken == revealToken do
				local r = AuraData.List[math.random(1, AuraData.Count)]
				orbGrad.Color = ColorSequence.new(r.c1, r.c2)
				rarityLbl.Text = Util.FormatRarity(r.rarity)
				rarityLbl.TextColor3 = AuraData.GetTier(r.rarity).color
				task.wait(0.05)
			end
		end)
		task.wait(suspense)
		if myToken ~= revealToken then return end

		-- Land on the real aura.
		orbGrad.Color = ColorSequence.new(aura.c1, aura.c2)
		nameLbl.Text = aura.name
		rarityLbl.Text = Util.FormatRarity(aura.rarity)
		rarityLbl.TextColor3 = tier.color
		subLbl.Text = string.format("%s · 🌐 %s exist · +%s 💰",
			tier.name, Util.Commas(data.exists or 0), Util.Abbreviate(data.coins or 0))
		newTag.Visible = isNew

		-- Pop + (for rare auras) screen flash.
		card.Size = UDim2.fromOffset(300, 180)
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back),
			{ Size = UDim2.fromOffset(340, 180) }):Play()
		if aura.rarity >= 100000 then
			flash.BackgroundColor3 = tier.color
			flash.BackgroundTransparency = 0.2
			TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		end

		-- Hold, then fade out.
		task.wait(aura.rarity >= 1000000 and 2.4 or 1.4)
		if myToken ~= revealToken then return end
		local out = TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		TweenService:Create(cardStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		out:Play()
		out.Completed:Wait()
		if myToken == revealToken then card.Visible = false end
	end

	-- ── Multi reveal (capsule) ──────────────────────────────────────────────
	local multi = C.frame({
		Name = "MultiReveal",
		Size = UDim2.fromOffset(720, 220),
		Position = UDim2.new(0.5, 0, 0.45, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Color.Bg,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 31,
	})
	multi.Parent = sg
	C.corner(multi, UDim.new(0, 16))
	C.stroke(multi, Theme.Color.Gold, 2.5)
	local multiTitle = C.label({
		Text = "🎁 Capsule Opened!", Font = Theme.FontBlack, TextSize = 22,
		TextColor3 = Theme.Color.Gold, TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 8), ZIndex = 32,
	})
	multiTitle.Parent = multi
	local multiRow = C.frame({
		Size = UDim2.new(1, -20, 1, -48), Position = UDim2.fromOffset(10, 40),
		BackgroundTransparency = 1, ZIndex = 32,
	})
	multiRow.Parent = multi
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = multiRow

	local function playMulti(data)
		revealToken += 1
		for _, ch in ipairs(multiRow:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end
		-- Sort best-first.
		local results = data.results or {}
		table.sort(results, function(a, b) return a.rarity > b.rarity end)
		for i, res in ipairs(results) do
			local aura = AuraData.ById[res.id]
			if aura then
				local mcard = AuraCard.build(aura, {
					size = UDim2.fromOffset(110, 140),
					showExists = res.exists,
				})
				mcard.ZIndex = 33
				for _, d in ipairs(mcard:GetDescendants()) do
					if d:IsA("GuiObject") then d.ZIndex = 33 end
				end
				mcard.LayoutOrder = i
				mcard.Parent = multiRow
				seen[aura.id] = true
			end
		end
		multi.Visible = true
		multi.Size = UDim2.fromOffset(640, 220)
		TweenService:Create(multi, TweenInfo.new(0.25, Enum.EasingStyle.Back),
			{ Size = UDim2.fromOffset(720, 220) }):Play()
		task.wait(3.5)
		multi.Visible = false
	end

	-- ── Hook the remote ─────────────────────────────────────────────────────
	ctx.remotes.RollResult.OnClientEvent:Connect(function(data)
		if data.multi then
			playMulti(data)
		else
			playSingle(data)
		end
	end)
end

return RollReveal
