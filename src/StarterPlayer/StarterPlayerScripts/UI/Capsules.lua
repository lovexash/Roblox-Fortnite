-- Aura RNG | Capsules window
-- The Robux capsule shop. Each capsule rolls luck-boosted auras. Buy with Robux
-- (prompts a developer-product purchase) or with coins where available. Also
-- surfaces the gamepasses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CapsuleData = require(ReplicatedStorage:WaitForChild("CapsuleData"))
local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Util        = require(ReplicatedStorage:WaitForChild("Util"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local C     = require(script.Parent:WaitForChild("Components"))

local Capsules = {}

function Capsules.Init(ctx)
	local _, content, controller = C.window(ctx.screenGui, "🎁 Capsules & Passes", UDim2.fromOffset(620, 520))
	ctx.registerWindow("Capsules", controller)

	local list = C.scrollList({
		Size = UDim2.fromScale(1, 1),
		ZIndex = 7,
	}, nil, 10)
	list.Parent = content

	-- ── Capsule rows ────────────────────────────────────────────────────────
	for i, cap in ipairs(CapsuleData.List) do
		local row = C.frame({
			Size = UDim2.new(1, -6, 0, 92),
			BackgroundColor3 = Theme.Color.Card,
			LayoutOrder = i,
			ZIndex = 8,
		})
		C.corner(row)
		C.stroke(row, cap.color, 2, 0.2)

		local icon = C.label({
			Text = cap.icon, TextSize = 40,
			Size = UDim2.fromOffset(64, 92), Position = UDim2.fromOffset(8, 0),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 9,
		})
		icon.Parent = row
		local name = C.label({
			Text = cap.name, Font = Theme.FontBold, TextSize = 18, TextColor3 = cap.color,
			Size = UDim2.new(1, -290, 0, 24), Position = UDim2.fromOffset(78, 12), ZIndex = 9,
		})
		name.Parent = row
		local desc = C.label({
			Text = cap.desc, TextSize = 13, TextColor3 = Theme.Color.SubText, TextWrapped = true,
			Size = UDim2.new(1, -290, 0, 40), Position = UDim2.fromOffset(78, 38),
			TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 9,
		})
		desc.Parent = row
		local luckTag = C.label({
			Text = string.format("🍀 x%s luck · %d roll%s", Util.Abbreviate(cap.luck),
				cap.rolls or 1, (cap.rolls or 1) > 1 and "s" or ""),
			TextSize = 12, TextColor3 = Theme.Color.Good,
			Size = UDim2.new(1, -290, 0, 16), Position = UDim2.fromOffset(78, 70), ZIndex = 9,
		})
		luckTag.Parent = row

		-- Robux buy button.
		local robuxBtn = C.button({
			Size = UDim2.fromOffset(140, 36),
			Position = UDim2.new(1, -150, 0, 12),
			Text = "R$ " .. cap.robux, TextSize = 16, ZIndex = 9,
		}, { color = Color3.fromRGB(0, 170, 90) })
		robuxBtn.Parent = row
		robuxBtn.MouseButton1Click:Connect(function()
			ctx.remotes.PromptProduct:FireServer("capsule", cap.id)
		end)

		-- Optional coin buy button.
		if cap.coinPrice then
			local coinBtn = C.button({
				Size = UDim2.fromOffset(140, 36),
				Position = UDim2.new(1, -150, 0, 52),
				Text = "💰 " .. Util.Abbreviate(cap.coinPrice), TextSize = 15, ZIndex = 9,
			}, { color = Theme.Color.Gold })
			coinBtn.Parent = row
			coinBtn.MouseButton1Click:Connect(function()
				ctx.remotes.BuyCapsule:FireServer(cap.id)
			end)
		end

		row.Parent = list
	end

	-- ── Gamepass section ────────────────────────────────────────────────────
	local header = C.label({
		Text = "👑 Gamepasses", Font = Theme.FontBlack, TextSize = 18, TextColor3 = Theme.Color.Gold,
		Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 100, ZIndex = 8,
	})
	header.Parent = list

	local idx = 101
	for key, info in pairs(GameConfig.Monetization.Gamepasses) do
		local row = C.frame({
			Size = UDim2.new(1, -6, 0, 60),
			BackgroundColor3 = Theme.Color.Card,
			LayoutOrder = idx, ZIndex = 8,
		})
		idx += 1
		C.corner(row)
		C.stroke(row, Theme.Color.Gold, 1.5, 0.4)
		local name = C.label({
			Text = info.name, Font = Theme.FontBold, TextSize = 16,
			Size = UDim2.new(1, -170, 0, 22), Position = UDim2.fromOffset(14, 8), ZIndex = 9,
		})
		name.Parent = row
		local desc = C.label({
			Text = info.desc, TextSize = 12, TextColor3 = Theme.Color.SubText,
			Size = UDim2.new(1, -170, 0, 18), Position = UDim2.fromOffset(14, 32), ZIndex = 9,
		})
		desc.Parent = row
		local btn = C.button({
			Size = UDim2.fromOffset(140, 40),
			Position = UDim2.new(1, -150, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
			Text = "Get Pass", TextSize = 15, ZIndex = 9,
		}, { color = Color3.fromRGB(0, 170, 90) })
		btn.Parent = row
		btn.MouseButton1Click:Connect(function()
			ctx.remotes.PromptProduct:FireServer("gamepass", key)
		end)

		-- Mark owned passes.
		ctx.onProfile(function(profile)
			if profile.gamepasses and profile.gamepasses[key] then
				btn.Text = "✓ Owned"
				btn.BackgroundColor3 = Theme.Color.Stroke
			end
		end)

		row.Parent = list
	end

	-- Coin top-up products.
	local cHeader = C.label({
		Text = "💰 Coin Packs", Font = Theme.FontBlack, TextSize = 18, TextColor3 = Theme.Color.Gold,
		Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 200, ZIndex = 8,
	})
	cHeader.Parent = list
	local pidx = 201
	for key, info in pairs(GameConfig.Monetization.Products) do
		local row = C.frame({
			Size = UDim2.new(1, -6, 0, 52),
			BackgroundColor3 = Theme.Color.Card, LayoutOrder = pidx, ZIndex = 8,
		})
		pidx += 1
		C.corner(row)
		local name = C.label({
			Text = "💰 " .. info.name, Font = Theme.FontBold, TextSize = 16,
			Size = UDim2.new(1, -160, 1, 0), Position = UDim2.fromOffset(14, 0), ZIndex = 9,
		})
		name.Parent = row
		local btn = C.button({
			Size = UDim2.fromOffset(140, 36),
			Position = UDim2.new(1, -150, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
			Text = "Buy", TextSize = 15, ZIndex = 9,
		}, { color = Color3.fromRGB(0, 170, 90) })
		btn.Parent = row
		btn.MouseButton1Click:Connect(function()
			ctx.remotes.PromptProduct:FireServer("product", key)
		end)
		row.Parent = list
	end
end

return Capsules
