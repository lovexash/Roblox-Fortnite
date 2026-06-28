-- Aura RNG | MapBuilder
-- Procedurally builds the world at runtime: the main spawn island with a glowing
-- roll altar, a ring of shop/index podiums, and a separate Trading Plaza with
-- trade pads. Everything is built from parts so no external assets are required.

local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function neon(props, parent)
	props.Material = Enum.Material.Neon
	return part(props, parent)
end

local function billboardSign(text, color, size, parent, pos)
	local anchor = part({
		Size = Vector3.new(0.2, 0.2, 0.2),
		Position = pos,
		Transparency = 1,
		CanCollide = false,
	}, parent)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, size or 360, 0, 80)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 250
	bb.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = bb
	return anchor
end

-- ── Root ─────────────────────────────────────────────────────────────────────
local existing = Workspace:FindFirstChild("AuraWorld")
if existing then existing:Destroy() end

local world = Instance.new("Model")
world.Name = "AuraWorld"
world.Parent = Workspace

-- ── Main spawn island ────────────────────────────────────────────────────────
local ISLAND_Y = 0
part({
	Name = "MainIsland",
	Size = Vector3.new(220, 6, 220),
	Position = Vector3.new(0, ISLAND_Y, 0),
	Color = Color3.fromRGB(38, 40, 60),
	Material = Enum.Material.SmoothPlastic,
}, world)

-- Decorative glowing rim.
neon({
	Name = "IslandRim",
	Size = Vector3.new(224, 1, 224),
	Position = Vector3.new(0, ISLAND_Y + 2.6, 0),
	Color = Color3.fromRGB(90, 130, 255),
}, world)

-- Spawn location.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, ISLAND_Y + 3.5, 70)
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = Color3.fromRGB(120, 200, 255)
spawn.Material = Enum.Material.Neon
spawn.Parent = world

-- ── Roll altar (centerpiece) ─────────────────────────────────────────────────
local altarBase = part({
	Name = "RollAltar",
	Size = Vector3.new(26, 2, 26),
	Position = Vector3.new(0, ISLAND_Y + 4, 0),
	Color = Color3.fromRGB(28, 30, 48),
	Material = Enum.Material.Slate,
}, world)
do
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Scale = Vector3.new(1, 1, 1)
	-- (Cylinder mesh on a part: rotate so it lies flat.)
	altarBase.Orientation = Vector3.new(0, 0, 90)
	mesh.Parent = altarBase
end

local pillar = neon({
	Name = "AltarCore",
	Size = Vector3.new(4, 10, 4),
	Position = Vector3.new(0, ISLAND_Y + 10, 0),
	Color = Color3.fromRGB(120, 180, 255),
	Transparency = 0.2,
}, world)
do
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(120, 180, 255)
	light.Range = 40
	light.Brightness = 4
	light.Parent = pillar
end

billboardSign("🎲  ROLL ALTAR  🎲", Color3.fromRGB(150, 200, 255), 420, world,
	Vector3.new(0, ISLAND_Y + 18, 0))
billboardSign("Press the 🎲 button to roll for an Aura!",
	Color3.fromRGB(200, 220, 255), 460, world, Vector3.new(0, ISLAND_Y + 15, 0))

-- A spinning ring around the core for flavor.
local ring = neon({
	Name = "AltarRing",
	Size = Vector3.new(16, 0.6, 16),
	Position = Vector3.new(0, ISLAND_Y + 8, 0),
	Color = Color3.fromRGB(160, 120, 255),
}, world)
local ringMesh = Instance.new("SpecialMesh")
ringMesh.MeshType = Enum.MeshType.Cylinder
ring.Orientation = Vector3.new(0, 0, 90)
ringMesh.Parent = ring
task.spawn(function()
	while ring.Parent do
		ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(1))
		task.wait(0.03)
	end
end)

-- ── Podiums (shop / capsules / index) around the altar ───────────────────────
local podiums = {
	{ label = "🛒 POTION SHOP",  color = Color3.fromRGB(120, 240, 140), angle = 40 },
	{ label = "🎁 CAPSULES",      color = Color3.fromRGB(255, 200, 60),  angle = 100 },
	{ label = "📖 AURA INDEX",    color = Color3.fromRGB(160, 120, 255), angle = 160 },
	{ label = "🤝 TRADING PLAZA", color = Color3.fromRGB(255, 130, 200), angle = 220 },
}
for _, info in ipairs(podiums) do
	local rad = math.rad(info.angle)
	local x, z = math.cos(rad) * 60, math.sin(rad) * 60
	part({
		Name = "Podium",
		Size = Vector3.new(10, 4, 10),
		Position = Vector3.new(x, ISLAND_Y + 5, z),
		Color = Color3.fromRGB(30, 32, 50),
		Material = Enum.Material.SmoothPlastic,
	}, world)
	neon({
		Size = Vector3.new(10, 0.5, 10),
		Position = Vector3.new(x, ISLAND_Y + 7.2, z),
		Color = info.color,
	}, world)
	billboardSign(info.label, info.color, 320, world, Vector3.new(x, ISLAND_Y + 11, z))
end

-- ── Trading Plaza (separate raised platform) ─────────────────────────────────
local PLAZA = Vector3.new(0, 40, -340)
part({
	Name = "TradingPlaza",
	Size = Vector3.new(120, 6, 120),
	Position = PLAZA,
	Color = Color3.fromRGB(44, 34, 56),
	Material = Enum.Material.SmoothPlastic,
}, world)
neon({
	Size = Vector3.new(124, 1, 124),
	Position = PLAZA + Vector3.new(0, 2.6, 0),
	Color = Color3.fromRGB(255, 130, 200),
}, world)
billboardSign("✨ TRADING PLAZA ✨", Color3.fromRGB(255, 150, 220), 520, world,
	PLAZA + Vector3.new(0, 22, 0))
billboardSign("Stand near a player and open 🤝 Trade",
	Color3.fromRGB(255, 200, 230), 480, world, PLAZA + Vector3.new(0, 18, 0))

-- Trade pads (pairs of facing pads).
for i = -1, 1 do
	local px = i * 34
	for _, sign in ipairs({ -1, 1 }) do
		neon({
			Name = "TradePad",
			Size = Vector3.new(10, 0.4, 10),
			Position = PLAZA + Vector3.new(px, 3.4, sign * 10),
			Color = Color3.fromRGB(255, 160, 220),
			Transparency = 0.3,
		}, world)
	end
end

-- Decorative pillars around the plaza.
for a = 0, 330, 30 do
	local rad = math.rad(a)
	neon({
		Size = Vector3.new(3, 24, 3),
		Position = PLAZA + Vector3.new(math.cos(rad) * 55, 12, math.sin(rad) * 55),
		Color = Color3.fromRGB(120, 80, 200),
		Transparency = 0.4,
	}, world)
end

-- A bridge / teleport hint between island and plaza (purely visual walkway).
part({
	Name = "PlazaBridge",
	Size = Vector3.new(14, 1, 220),
	Position = Vector3.new(0, 22, -200),
	Color = Color3.fromRGB(36, 30, 50),
	Material = Enum.Material.SmoothPlastic,
	Transparency = 0.05,
}, world)

-- ── Atmosphere / lighting ────────────────────────────────────────────────────
Lighting.Brightness = 2
Lighting.ClockTime = 0           -- night, so neon pops
Lighting.Ambient = Color3.fromRGB(40, 40, 70)
Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 90)
Lighting.FogColor = Color3.fromRGB(20, 18, 40)
Lighting.FogEnd = 900
Lighting.FogStart = 250

local existingFx = Lighting:FindFirstChild("AuraAtmosphere")
if not existingFx then
	local atmos = Instance.new("Atmosphere")
	atmos.Name = "AuraAtmosphere"
	atmos.Density = 0.32
	atmos.Haze = 1.4
	atmos.Color = Color3.fromRGB(180, 190, 230)
	atmos.Decay = Color3.fromRGB(80, 70, 120)
	atmos.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.7
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local stars = Instance.new("Sky")
	stars.StarCount = 6000
	stars.Parent = Lighting
end

print("[Aura RNG] World built.")
