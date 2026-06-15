-- Take & Brainrot | ConveyorSystem Server
-- Spawns eggs on a conveyor belt and moves them forward

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local EggPickup = RemoteEvents:WaitForChild("EggPickup")
local Notification = RemoteEvents:WaitForChild("Notification")

-- ── Build conveyor in Workspace ─────────────────────────────────────────────

local workspace = game.Workspace

-- Parent folder for all conveyor parts
local ConveyorFolder = workspace:FindFirstChild("Conveyor") or Instance.new("Folder")
ConveyorFolder.Name = "Conveyor"
ConveyorFolder.Parent = workspace

-- Belt dimensions
local BELT_LENGTH = 60
local BELT_WIDTH  = 6
local BELT_HEIGHT = 2
local BELT_Y      = 2          -- height off ground
local BELT_START  = Vector3.new(-30, BELT_Y, 0)   -- eggs spawn here
local BELT_END    = Vector3.new(30,  BELT_Y, 0)   -- eggs fall off here

local function makePart(name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Color = color or Color3.fromRGB(80, 80, 80)
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = ConveyorFolder
    return p
end

-- Main belt surface
local belt = makePart("Belt", Vector3.new(BELT_LENGTH, 0.4, BELT_WIDTH),
    Vector3.new(0, BELT_Y - 0.2, 0),
    Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
belt.TopSurface = Enum.SurfaceType.Smooth

-- Side rails
makePart("LeftRail",  Vector3.new(BELT_LENGTH, 1, 0.4), Vector3.new(0, BELT_Y + 0.5, -BELT_WIDTH/2 - 0.2), Color3.fromRGB(60,60,60))
makePart("RightRail", Vector3.new(BELT_LENGTH, 1, 0.4), Vector3.new(0, BELT_Y + 0.5,  BELT_WIDTH/2 + 0.2), Color3.fromRGB(60,60,60))

-- Support legs
for i = -2, 2 do
    makePart("Leg_" .. i, Vector3.new(0.8, BELT_Y * 2, 0.8),
        Vector3.new(i * 12, 1, 0), Color3.fromRGB(60, 60, 60))
end

-- Moving belt texture (decoration arrows)
local surf = Instance.new("SpecialMesh")
surf.MeshType = Enum.MeshType.Brick
surf.Parent = belt

-- Glowing "TAKE & BRAINROT" sign above belt
local sign = makePart("Sign", Vector3.new(20, 4, 0.4),
    Vector3.new(0, BELT_Y + 5, 0), Color3.fromRGB(255, 80, 200), Enum.Material.Neon)
local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = sign
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.fromScale(1, 1)
lbl.BackgroundTransparency = 1
lbl.Text = "🎮 TAKE & BRAINROT 🎮"
lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
lbl.TextScaled = true
lbl.Font = Enum.Font.GothamBold
lbl.Parent = sg

-- ── Egg helpers ──────────────────────────────────────────────────────────────

local activeEggs = {}    -- { part = Part, value = number, tween = Tween }
local eggCount = 0

local function weightedRandom(types)
    local total = 0
    for _, t in ipairs(types) do total = total + t.weight end
    local r = math.random(1, total)
    local cum = 0
    for _, t in ipairs(types) do
        cum = cum + t.weight
        if r <= cum then return t end
    end
    return types[1]
end

local function destroyEgg(entry)
    if entry.tween then entry.tween:Cancel() end
    if entry.part and entry.part.Parent then entry.part:Destroy() end
    for i, e in ipairs(activeEggs) do
        if e == entry then table.remove(activeEggs, i) break end
    end
end

local function spawnEgg()
    if #activeEggs >= GameConfig.Conveyor.MaxEggsOnBelt then return end

    local eggType = weightedRandom(GameConfig.Conveyor.EggTypes)
    eggCount = eggCount + 1

    -- Egg body
    local egg = Instance.new("Part")
    egg.Name = "Egg_" .. eggCount
    egg.Size = Vector3.new(1.2, 1.6, 1.2)
    egg.Shape = Enum.PartType.Ball
    egg.Color = eggType.color
    egg.Material = Enum.Material.SmoothPlastic
    egg.CastShadow = true

    -- Slight random Z offset so eggs don't stack perfectly
    egg.Position = BELT_START + Vector3.new(0, 1, math.random(-2, 2))
    egg.Parent = workspace

    -- Name billboard
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 1.2, 0)
    bb.AlwaysOnTop = false
    bb.Parent = egg
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.fromScale(1, 1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggType.name .. " (" .. eggType.value .. "pts)"
    nameLabel.TextColor3 = eggType.color
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = bb

    -- Shimmer for special eggs
    if eggType.value >= 100 then
        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = egg
        selectionBox.Color3 = eggType.color
        selectionBox.LineThickness = 0.05
        selectionBox.Parent = egg
    end

    -- Tween across belt
    local duration = BELT_LENGTH / GameConfig.Conveyor.Speed
    local tween = TweenService:Create(egg,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Position = BELT_END + Vector3.new(0, 1, egg.Position.Z) })

    local entry = { part = egg, value = eggType.value, tween = tween }
    table.insert(activeEggs, entry)

    -- Touch to collect
    egg.Touched:Connect(function(hit)
        local char = hit.Parent
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        if not (entry.part and entry.part.Parent) then return end

        EggPickup:FireServer()   -- client fires; server awards points via MainGame
        -- Server-side award (direct call since we're on server)
        if _G.GameAPI then
            _G.GameAPI.AddPoints(player, eggType.value + 5)
            _G.GameAPI.Notify(player, "Picked up " .. eggType.name .. "! +" .. (eggType.value + 5) .. " pts", "Green")
        end
        destroyEgg(entry)
    end)

    tween:Play()
    tween.Completed:Connect(function()
        destroyEgg(entry)
    end)
end

-- Public API
local ConveyorAPI = {}
_G.ConveyorAPI = ConveyorAPI

function ConveyorAPI.SetSpeed(speed)
    GameConfig.Conveyor.Speed = math.clamp(speed, 1, 100)
end

function ConveyorAPI.ClearAll()
    for _, entry in ipairs(table.clone(activeEggs)) do
        destroyEgg(entry)
    end
end

function ConveyorAPI.SpawnAll()
    for _, eggType in ipairs(GameConfig.Conveyor.EggTypes) do
        spawnEgg()
    end
end

-- Main spawn loop
task.spawn(function()
    while true do
        task.wait(GameConfig.Conveyor.EggSpawnInterval)
        spawnEgg()
    end
end)

-- Animate belt color to simulate movement (cheap visual trick)
task.spawn(function()
    local hue = 0
    while true do
        task.wait(0.05)
        hue = (hue + 0.005) % 1
    end
end)

print("[Take & Brainrot] Conveyor system loaded.")
