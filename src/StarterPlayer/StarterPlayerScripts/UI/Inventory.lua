-- Aura RNG | Inventory window
-- Shows every aura the player owns as a grid. Click a card to equip it; click
-- the 💰 corner button to sell one copy for coins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local Util     = require(ReplicatedStorage:WaitForChild("Util"))

local Theme    = require(script.Parent:WaitForChild("Theme"))
local C        = require(script.Parent:WaitForChild("Components"))
local AuraCard = require(script.Parent:WaitForChild("AuraCard"))

local Inventory = {}

function Inventory.Init(ctx)
	local _, content, controller = C.window(ctx.screenGui, "🎒 Inventory", UDim2.fromOffset(760, 500))
	ctx.registerWindow("Inventory", controller)

	-- Header summary.
	local summary = C.label({
		Text = "Loading…", TextColor3 = Theme.Color.SubText, TextSize = 15,
		Size = UDim2.new(1, -180, 0, 24), Position = UDim2.fromOffset(4, 0), ZIndex = 7,
	})
	summary.Parent = content

	-- Sort toggle.
	local sortByRarity = true
	local sortBtn = C.button({
		Size = UDim2.fromOffset(160, 28),
		Position = UDim2.new(1, -160, 0, 0),
		Text = "Sort: Rarity ▼", TextSize = 13, ZIndex = 8,
	}, { color = Theme.Color.PanelLight })
	sortBtn.Parent = content

	local grid = C.scrollGrid({
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 34),
		ZIndex = 7,
	}, UDim2.fromOffset(130, 152), 10, 6)
	grid.Parent = content

	local function rebuild()
		local profile = ctx.getProfile()
		if not profile then return end
		for _, ch in ipairs(grid:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end

		local items = {}
		for _, item in ipairs(profile.inventory or {}) do
			local aura = AuraData.ById[item.id]
			if aura then items[#items + 1] = { aura = aura, count = item.count } end
		end
		if sortByRarity then
			table.sort(items, function(a, b) return a.aura.rarity > b.aura.rarity end)
		else
			table.sort(items, function(a, b) return a.count > b.count end)
		end

		local totalCount = 0
		for _, it in ipairs(items) do totalCount += it.count end
		summary.Text = string.format("%d unique · %s total auras", #items, Util.Commas(totalCount))

		for i, it in ipairs(items) do
			local card = AuraCard.build(it.aura, { count = it.count, showTier = true })
			card.LayoutOrder = i
			for _, d in ipairs(card:GetDescendants()) do
				if d:IsA("GuiObject") then d.ZIndex = 8 end
			end
			card.ZIndex = 8

			-- Equipped highlight.
			if profile.equipped == it.aura.id then
				local s = card:FindFirstChildOfClass("UIStroke")
				if s then s.Color = Theme.Color.Good; s.Thickness = 3 end
			end

			local hit = Instance.new("TextButton")
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.Size = UDim2.fromScale(1, 1)
			hit.ZIndex = 9
			hit.Parent = card
			hit.MouseButton1Click:Connect(function()
				ctx.remotes.EquipAura:FireServer(it.aura.id)
			end)

			-- Sell-one button (top-right corner).
			local sell = C.button({
				Size = UDim2.fromOffset(26, 22),
				Position = UDim2.new(1, -32, 0, 6),
				Text = "💰", TextSize = 12, ZIndex = 10,
			}, { color = Theme.Color.Gold, corner = UDim.new(0, 6) })
			sell.Parent = card
			sell.MouseButton1Click:Connect(function()
				ctx.remotes.DeleteAura:FireServer(it.aura.id, 1)
			end)

			card.Parent = grid
		end

		if #items == 0 then
			summary.Text = "Your inventory is empty — go roll some auras! 🎲"
		end
	end

	sortBtn.MouseButton1Click:Connect(function()
		sortByRarity = not sortByRarity
		sortBtn.Text = sortByRarity and "Sort: Rarity ▼" or "Sort: Count ▼"
		rebuild()
	end)

	ctx.onProfile(function()
		if controller.isOpen() then rebuild() end
	end)

	local origShow = controller.show
	controller.show = function()
		origShow()
		rebuild()
	end
end

return Inventory
