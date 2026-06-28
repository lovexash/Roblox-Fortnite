-- Aura RNG | MainHUD
-- Always-on HUD: currency + luck readout (top-left), equipped aura badge
-- (top-center), navigation buttons (left), and the big Roll Dice button with a
-- cooldown ring (bottom-center).

local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local Util     = require(ReplicatedStorage:WaitForChild("Util"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local C     = require(script.Parent:WaitForChild("Components"))

local MainHUD = {}

function MainHUD.Init(ctx)
	local sg = ctx.screenGui

	-- ── Top-left stat pills ─────────────────────────────────────────────────
	local statBar = C.frame({
		Name = "StatBar",
		Size = UDim2.fromOffset(360, 44),
		Position = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
	})
	statBar.Parent = sg
	local statLayout = Instance.new("UIListLayout")
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.Padding = UDim.new(0, 10)
	statLayout.Parent = statBar

	local function pill(icon, color)
		local f = C.frame({
			Size = UDim2.fromOffset(160, 44),
			BackgroundColor3 = Theme.Color.Panel,
		})
		C.corner(f)
		C.stroke(f, color, 1.5, 0.3)
		local ic = C.label({
			Text = icon, TextSize = 22, Size = UDim2.fromOffset(34, 44),
			Position = UDim2.fromOffset(10, 0), TextXAlignment = Enum.TextXAlignment.Center,
		})
		ic.Parent = f
		local val = C.label({
			Text = "0", Font = Theme.FontBold, TextSize = 18, TextColor3 = color,
			Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(46, 0),
		})
		val.Parent = f
		return f, val
	end

	local coinPill, coinVal = pill("💰", Theme.Color.Gold)
	coinPill.Parent = statBar
	local luckPill, luckVal = pill("🍀", Theme.Color.Good)
	luckPill.Parent = statBar

	-- ── Equipped aura badge (top-center) ────────────────────────────────────
	local equipBadge = C.frame({
		Name = "EquipBadge",
		Size = UDim2.fromOffset(260, 44),
		Position = UDim2.new(0.5, 0, 0, 16),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Color.Panel,
	})
	equipBadge.Parent = sg
	C.corner(equipBadge)
	local equipStroke = C.stroke(equipBadge, Theme.Color.Stroke, 2, 0.1)
	local equipOrb = C.frame({
		Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(10, 8),
		BackgroundColor3 = Color3.new(0.4, 0.4, 0.5),
	})
	equipOrb.Parent = equipBadge
	C.corner(equipOrb, UDim.new(1, 0))
	local equipGrad = C.gradient(equipOrb, Color3.new(0.4,0.4,0.5), Color3.new(0.2,0.2,0.3), 60)
	local equipLabel = C.label({
		Text = "No Aura Equipped", Font = Theme.FontBold, TextSize = 15,
		Size = UDim2.new(1, -50, 0, 22), Position = UDim2.fromOffset(46, 4),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	equipLabel.Parent = equipBadge
	local equipRarity = C.label({
		Text = "Roll to find one!", TextSize = 12, TextColor3 = Theme.Color.SubText,
		Size = UDim2.new(1, -50, 0, 14), Position = UDim2.fromOffset(46, 24),
	})
	equipRarity.Parent = equipBadge

	-- ── Side navigation ─────────────────────────────────────────────────────
	local nav = C.frame({
		Name = "Nav",
		Size = UDim2.fromOffset(64, 340),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
	})
	nav.Parent = sg
	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding = UDim.new(0, 10)
	navLayout.Parent = nav

	local navButtons = {
		{ icon = "🎒", name = "Inventory", tip = "Inventory" },
		{ icon = "🛒", name = "Shop",      tip = "Potion Shop" },
		{ icon = "🎁", name = "Capsules",  tip = "Capsules" },
		{ icon = "📖", name = "Index",     tip = "Aura Index" },
		{ icon = "🤝", name = "Trade",     tip = "Trade" },
	}
	for _, info in ipairs(navButtons) do
		local b = C.button({
			Size = UDim2.fromOffset(56, 56),
			Text = info.icon, TextSize = 26,
		}, { color = Theme.Color.Panel, corner = UDim.new(0, 14) })
		b.Parent = nav
		C.stroke(b, Theme.Color.Stroke, 1.5, 0.3)
		b.MouseButton1Click:Connect(function()
			ctx.openWindow(info.name)
		end)
	end

	-- ── Roll Dice button (bottom-center) ────────────────────────────────────
	local rollHolder = C.frame({
		Name = "RollHolder",
		Size = UDim2.fromOffset(220, 120),
		Position = UDim2.new(0.5, 0, 1, -24),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
	})
	rollHolder.Parent = sg

	local rollBtn = C.button({
		Name = "RollButton",
		Size = UDim2.fromOffset(200, 84),
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		Text = "",
	}, { color = Theme.Color.Accent, corner = UDim.new(0, 18) })
	rollBtn.Parent = rollHolder
	C.gradient(rollBtn, Theme.Color.Accent, Theme.Color.Accent2, 25)
	C.stroke(rollBtn, Color3.new(1, 1, 1), 2, 0.4)

	local diceIcon = C.label({
		Text = "🎲", TextSize = 40, Size = UDim2.fromOffset(56, 84),
		Position = UDim2.fromOffset(14, 0), TextXAlignment = Enum.TextXAlignment.Center,
	})
	diceIcon.Parent = rollBtn
	local rollText = C.label({
		Text = "ROLL", Font = Theme.FontBlack, TextSize = 28,
		Size = UDim2.new(1, -70, 0, 34), Position = UDim2.fromOffset(70, 16),
	})
	rollText.Parent = rollBtn
	local rollSub = C.label({
		Text = "Dice", TextSize = 13, TextColor3 = Color3.fromRGB(230, 230, 255),
		Size = UDim2.new(1, -70, 0, 16), Position = UDim2.fromOffset(70, 50),
	})
	rollSub.Parent = rollBtn

	-- Cooldown overlay bar.
	local cdBar = C.frame({
		Name = "Cooldown",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		ZIndex = 3,
	})
	cdBar.Parent = rollBtn
	C.corner(cdBar, UDim.new(0, 18))

	-- Auto-roll toggle (visible/active only with the gamepass).
	local autoBtn = C.button({
		Name = "AutoRoll",
		Size = UDim2.fromOffset(200, 26),
		Position = UDim2.fromOffset(0, 0),
		Text = "🔁 Auto Roll: OFF", TextSize = 13,
	}, { color = Theme.Color.Panel, corner = UDim.new(0, 10) })
	autoBtn.Parent = rollHolder
	C.stroke(autoBtn, Theme.Color.Stroke, 1, 0.4)

	-- ── Roll state / cooldown logic ─────────────────────────────────────────
	local cooldown = 1.0
	local nextReady = 0
	local autoOn = false

	local function tryRoll()
		if os.clock() < nextReady then return end
		nextReady = os.clock() + cooldown
		ctx.remotes.RollRequest:FireServer()

		-- Visual: pop the dice + run the cooldown bar.
		TweenService:Create(diceIcon, TweenInfo.new(0.1), { Rotation = diceIcon.Rotation + 360 }):Play()
		cdBar.Size = UDim2.fromScale(1, 1)
		TweenService:Create(cdBar, TweenInfo.new(cooldown, Enum.EasingStyle.Linear),
			{ Size = UDim2.fromScale(0, 1) }):Play()
	end

	rollBtn.MouseButton1Click:Connect(tryRoll)

	-- Spacebar also rolls.
	UserInput.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Space then
			tryRoll()
		end
	end)

	autoBtn.MouseButton1Click:Connect(function()
		local profile = ctx.getProfile()
		if not (profile and profile.gamepasses and profile.gamepasses.AutoRoll) then
			ctx.notify("Auto Roll requires the gamepass.", "warn")
			ctx.openWindow("Capsules")
			return
		end
		autoOn = not autoOn
		autoBtn.Text = "🔁 Auto Roll: " .. (autoOn and "ON" or "OFF")
		autoBtn.BackgroundColor3 = autoOn and Theme.Color.Good or Theme.Color.Panel
	end)

	-- Auto-roll loop.
	task.spawn(function()
		while true do
			if autoOn and os.clock() >= nextReady then
				tryRoll()
			end
			task.wait(0.1)
		end
	end)

	-- ── React to profile updates ────────────────────────────────────────────
	ctx.onProfile(function(profile)
		coinVal.Text = Util.Abbreviate(profile.coins or 0)
		luckVal.Text = "x" .. Util.Abbreviate(profile.luck or 1)
		cooldown = profile.cooldown or 1.0

		if profile.equipped and AuraData.ById[profile.equipped] then
			local aura = AuraData.ById[profile.equipped]
			local tier = AuraData.GetTier(aura.rarity)
			equipLabel.Text = aura.name
			equipLabel.TextColor3 = tier.color
			equipRarity.Text = Util.FormatRarity(aura.rarity) .. " · " .. tier.name
			equipGrad.Color = ColorSequence.new(aura.c1, aura.c2)
			equipOrb.BackgroundColor3 = Color3.new(1, 1, 1)
			equipStroke.Color = tier.color
		else
			equipLabel.Text = "No Aura Equipped"
			equipLabel.TextColor3 = Theme.Color.Text
			equipRarity.Text = "Roll to find one!"
		end
	end)
end

return MainHUD
