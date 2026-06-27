-- Aura RNG | UI Theme
-- Shared palette, fonts, and spacing for a consistent, professional look.

local Theme = {}

Theme.Font       = Enum.Font.GothamMedium
Theme.FontBold   = Enum.Font.GothamBold
Theme.FontBlack  = Enum.Font.GothamBlack

Theme.Color = {
	Bg        = Color3.fromRGB(18, 18, 28),
	Panel     = Color3.fromRGB(26, 26, 40),
	PanelLight = Color3.fromRGB(36, 36, 54),
	Card      = Color3.fromRGB(32, 32, 50),
	Stroke    = Color3.fromRGB(60, 60, 90),
	Accent    = Color3.fromRGB(120, 130, 255),
	Accent2   = Color3.fromRGB(180, 110, 255),
	Good      = Color3.fromRGB(90, 220, 130),
	Bad       = Color3.fromRGB(255, 90, 100),
	Warn      = Color3.fromRGB(255, 200, 70),
	Gold      = Color3.fromRGB(255, 205, 70),
	Text      = Color3.fromRGB(235, 238, 250),
	SubText   = Color3.fromRGB(165, 170, 195),
}

Theme.Corner = UDim.new(0, 12)
Theme.CornerSm = UDim.new(0, 8)

return Theme
