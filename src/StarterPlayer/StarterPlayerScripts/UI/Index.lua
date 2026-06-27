-- Aura RNG | Index window
-- The full catalogue of every aura, ordered rarest-first, showing each aura's
-- rarity and how many exist globally. Auras you've discovered are highlighted;
-- undiscovered ones are masked as "???".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local Util     = require(ReplicatedStorage:WaitForChild("Util"))

local Theme    = require(script.Parent:WaitForChild("Theme"))
local C        = require(script.Parent:WaitForChild("Components"))
local AuraCard = require(script.Parent:WaitForChild("AuraCard"))

local Index = {}

function Index.Init(ctx)
	local _, content, controller = C.window(ctx.screenGui, "📖 Aura Index", UDim2.fromOffset(820, 540))
	ctx.registerWindow("Index", controller)

	local header = C.label({
		Text = string.format("%d auras · 1 in 2  →  1 in 1Q", AuraData.Count),
		TextColor3 = Theme.Color.SubText, TextSize = 14,
		Size = UDim2.new(1, -180, 0, 24), ZIndex = 7,
	})
	header.Parent = content

	local progressLbl = C.label({
		Text = "Discovered 0 / " .. AuraData.Count,
		Font = Theme.FontBold, TextColor3 = Theme.Color.Good, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(0, 170, 0, 24), Position = UDim2.new(1, -170, 0, 0), ZIndex = 7,
	})
	progressLbl.Parent = content

	local grid = C.scrollGrid({
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 32),
		ZIndex = 7,
	}, UDim2.fromOffset(140, 168), 12, 6)
	grid.Parent = content

	local globalCounts = {}

	local function rebuild()
		local profile = ctx.getProfile()
		local known = {}
		if profile then
			for _, item in ipairs(profile.inventory or {}) do known[item.id] = true end
			if profile.stats and profile.stats.rarest then known[profile.stats.rarest] = true end
		end

		for _, ch in ipairs(grid:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end

		local discovered = 0
		-- Rarest first.
		for i = AuraData.Count, 1, -1 do
			local aura = AuraData.List[i]
			local isKnown = known[aura.id] == true
			if isKnown then discovered += 1 end
			local card = AuraCard.build(aura, {
				size = UDim2.fromOffset(140, 168),
				showExists = globalCounts[aura.id] or globalCounts[tostring(aura.id)] or 0,
				dimIfUnknown = true,
				known = isKnown,
			})
			card.LayoutOrder = AuraData.Count - i
			for _, d in ipairs(card:GetDescendants()) do
				if d:IsA("GuiObject") then d.ZIndex = 8 end
			end
			card.ZIndex = 8
			card.Parent = grid
		end

		progressLbl.Text = string.format("Discovered %d / %d", discovered, AuraData.Count)
	end

	ctx.onProfile(function()
		if controller.isOpen() then rebuild() end
	end)

	local origShow = controller.show
	controller.show = function()
		origShow()
		-- Pull the latest global counts, then build.
		task.spawn(function()
			local ok, counts = pcall(function()
				return ctx.remotes.GlobalCounts:InvokeServer()
			end)
			if ok and type(counts) == "table" then
				globalCounts = counts
			end
			rebuild()
		end)
	end
end

return Index
