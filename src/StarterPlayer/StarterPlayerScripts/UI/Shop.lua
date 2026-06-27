-- Aura RNG | Shop window (potions, bought with coins)
-- Lists luck/haste potions. Shows active potions with remaining time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))
local Util     = require(ReplicatedStorage:WaitForChild("Util"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local C     = require(script.Parent:WaitForChild("Components"))

local Shop = {}

function Shop.Init(ctx)
	local _, content, controller = C.window(ctx.screenGui, "🛒 Potion Shop", UDim2.fromOffset(560, 480))
	ctx.registerWindow("Shop", controller)

	local activeLbl = C.label({
		Text = "No active potions.", TextColor3 = Theme.Color.SubText, TextSize = 14,
		Size = UDim2.new(1, 0, 0, 22), ZIndex = 7,
	})
	activeLbl.Parent = content

	local list = C.scrollList({
		Size = UDim2.new(1, 0, 1, -30),
		Position = UDim2.fromOffset(0, 28),
		ZIndex = 7,
	}, nil, 10)
	list.Parent = content

	for _, potion in ipairs(ShopData.Potions) do
		local row = C.frame({
			Size = UDim2.new(1, -6, 0, 76),
			BackgroundColor3 = Theme.Color.Card,
			ZIndex = 8,
		})
		C.corner(row)
		C.stroke(row, potion.color, 1.5, 0.3)

		local icon = C.label({
			Text = potion.icon, TextSize = 34,
			Size = UDim2.fromOffset(56, 76), Position = UDim2.fromOffset(8, 0),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 9,
		})
		icon.Parent = row
		local name = C.label({
			Text = potion.name, Font = Theme.FontBold, TextSize = 17, TextColor3 = potion.color,
			Size = UDim2.new(1, -240, 0, 24), Position = UDim2.fromOffset(70, 12), ZIndex = 9,
		})
		name.Parent = row
		local desc = C.label({
			Text = potion.desc, TextSize = 13, TextColor3 = Theme.Color.SubText,
			Size = UDim2.new(1, -240, 0, 20), Position = UDim2.fromOffset(70, 38), ZIndex = 9,
		})
		desc.Parent = row

		local buy = C.button({
			Size = UDim2.fromOffset(150, 48),
			Position = UDim2.new(1, -160, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
			Text = "💰 " .. Util.Abbreviate(potion.price), TextSize = 16, ZIndex = 9,
		}, { color = Theme.Color.Good })
		buy.Parent = row
		buy.MouseButton1Click:Connect(function()
			ctx.remotes.BuyPotion:FireServer(potion.id)
		end)

		row.Parent = list
	end

	-- Show active potions with a live countdown.
	local function refreshActive()
		local profile = ctx.getProfile()
		if not profile then return end
		local parts = {}
		for _, p in ipairs(profile.potions or {}) do
			local def = ShopData.ById[p.id]
			if def then
				parts[#parts + 1] = string.format("%s %s (%s)", def.icon, def.name, Util.Clock(p.remaining))
			end
		end
		activeLbl.Text = #parts > 0 and ("Active: " .. table.concat(parts, "  ·  ")) or "No active potions."
	end
	ctx.onProfile(refreshActive)

	-- Tick the countdown locally between profile pushes.
	task.spawn(function()
		while true do
			task.wait(1)
			if controller.isOpen() then
				local profile = ctx.getProfile()
				if profile then
					for _, p in ipairs(profile.potions or {}) do
						p.remaining = math.max(0, (p.remaining or 0) - 1)
					end
					refreshActive()
				end
			end
		end
	end)

	local origShow = controller.show
	controller.show = function() origShow(); refreshActive() end
end

return Shop
