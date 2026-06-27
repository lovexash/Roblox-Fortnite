-- Aura RNG | AuraCard
-- Builds the standard visual card/badge for an aura, reused by the inventory,
-- index, trade window, and roll reveal so auras always look consistent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local Util     = require(ReplicatedStorage:WaitForChild("Util"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local C     = require(script.Parent:WaitForChild("Components"))

local AuraCard = {}

-- A compact tile representing one aura.
-- opts: { count = n, showExists = n, dimIfUnknown = bool, known = bool }
function AuraCard.build(aura, opts)
	opts = opts or {}
	local tier = AuraData.GetTier(aura.rarity)

	local card = C.frame({
		Name = "Aura_" .. aura.id,
		BackgroundColor3 = Theme.Color.Card,
		Size = opts.size or UDim2.fromOffset(130, 150),
	})
	C.corner(card)
	C.stroke(card, tier.color, 2, 0.2)

	-- The aura "orb": a gradient circle that shows the aura's colors.
	local orb = C.frame({
		Name = "Orb",
		Size = UDim2.fromOffset(70, 70),
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	orb.Parent = card
	C.corner(orb, UDim.new(1, 0))
	C.gradient(orb, aura.c1, aura.c2, 60)
	C.stroke(orb, Color3.new(1, 1, 1), 2, 0.4)

	local glow = Instance.new("ImageLabel")
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://4996891970" -- soft radial glow
	glow.ImageColor3 = tier.color
	glow.ImageTransparency = 0.3
	glow.Size = UDim2.fromScale(2, 2)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Parent = orb

	-- Name.
	local name = C.label({
		Text = aura.name,
		Font = Theme.FontBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -8, 0, 18),
		Position = UDim2.fromOffset(4, 92),
	})
	name.Parent = card

	-- Rarity.
	local rarity = C.label({
		Text = Util.FormatRarity(aura.rarity),
		TextSize = 12,
		TextColor3 = tier.color,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -8, 0, 14),
		Position = UDim2.fromOffset(4, 110),
	})
	rarity.Parent = card

	-- Optional footer line: owned count or global "exists".
	if opts.count then
		local badge = C.frame({
			Name = "Count",
			Size = UDim2.fromOffset(34, 20),
			Position = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Theme.Color.Bg,
		})
		badge.Parent = card
		C.corner(badge, UDim.new(0, 6))
		local cl = C.label({
			Text = "x" .. opts.count,
			TextSize = 13,
			Font = Theme.FontBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
		})
		cl.Parent = badge
	end

	if opts.showExists ~= nil then
		local existsLbl = C.label({
			Text = "🌐 " .. Util.Commas(opts.showExists) .. " exist",
			TextSize = 11,
			TextColor3 = Theme.Color.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, -8, 0, 14),
			Position = UDim2.fromOffset(4, 126),
		})
		existsLbl.Parent = card
	end

	-- Tier label chip at the bottom for context.
	if opts.showTier then
		local chip = C.label({
			Text = tier.name:upper(),
			TextSize = 10,
			TextColor3 = tier.color,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, -8, 0, 12),
			Position = UDim2.fromOffset(4, 128),
		})
		chip.Parent = card
	end

	if opts.dimIfUnknown and not opts.known then
		orb.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		for _, g in ipairs(orb:GetChildren()) do
			if g:IsA("UIGradient") then g:Destroy() end
		end
		name.Text = "???"
		name.TextColor3 = Theme.Color.SubText
		glow.ImageTransparency = 0.85
	end

	return card
end

return AuraCard
