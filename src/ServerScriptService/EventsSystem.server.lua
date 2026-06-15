-- Take & Brainrot | EventsSystem Server
-- Manages all in-game events with full effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local EventStart = RemoteEvents:WaitForChild("EventStart")
local EventEnd   = RemoteEvents:WaitForChild("EventEnd")

local workspace = game.Workspace

local currentEvent = nil
local eventThread  = nil

-- ── Helper ───────────────────────────────────────────────────────────────────

local function notify(msg, color)
    if _G.GameAPI then _G.GameAPI.Announce(msg, color) end
    RemoteEvents.ServerAnnouncement:FireAllClients(msg, color or "White")
end

local function rewardAll(amount, reason)
    for _, player in ipairs(Players:GetPlayers()) do
        if _G.GameAPI then _G.GameAPI.AddPoints(player, amount) end
    end
    notify("All players earned +" .. amount .. " pts (" .. reason .. ")", "Gold")
end

local function randomPart(size, color, material)
    local p = Instance.new("Part")
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = false
    return p
end

-- ── Individual event logic ────────────────────────────────────────────────────

local Events = {}

-- 1. METEOR SHOWER
function Events.MeteorShower(duration)
    notify("☄️ METEOR SHOWER! Run for cover!", "Red")
    EventStart:FireAllClients("MeteorShower", duration)

    local originalAmbient = Lighting.Ambient
    Lighting.Ambient = Color3.fromRGB(80, 20, 0)

    local endTime = os.clock() + duration
    local spawnConn

    spawnConn = task.spawn(function()
        while os.clock() < endTime do
            task.wait(1.2)
            local center = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.new(0,0,0)
            for i = 1, 3 do
                task.spawn(function()
                    local x = math.random(-60, 60)
                    local z = math.random(-60, 60)
                    local meteor = randomPart(Vector3.new(math.random(2,5), math.random(2,5), math.random(2,5)),
                        Color3.fromRGB(255, 80, 20), Enum.Material.Neon)
                    meteor.Position = Vector3.new(x, 120, z)
                    meteor.Velocity = Vector3.new(math.random(-10,10), -80, math.random(-10,10))
                    meteor.Parent = workspace
                    Debris:AddItem(meteor, 6)

                    -- Explosion on land
                    meteor.Touched:Connect(function(hit)
                        if hit.Anchored then
                            local e = Instance.new("Explosion")
                            e.Position = meteor.Position
                            e.BlastRadius = 8
                            e.BlastPressure = 300000
                            e.Parent = workspace
                            Debris:AddItem(e, 2)
                            meteor:Destroy()
                        end
                    end)
                end)
            end
        end
    end)

    task.wait(duration)
    Lighting.Ambient = originalAmbient
    EventEnd:FireAllClients("MeteorShower")
    rewardAll(GameConfig.Economy.EventParticipationBonus, "survived Meteor Shower")
end

-- 2. FLOOD
function Events.Flood(duration)
    notify("🌊 FLOOD EVENT! The water is rising!", "Blue")
    EventStart:FireAllClients("Flood", duration)

    local water = Instance.new("Part")
    water.Name = "FloodWater"
    water.Size = Vector3.new(300, 1, 300)
    water.Position = Vector3.new(0, -5, 0)
    water.Anchored = true
    water.Material = Enum.Material.Water
    water.Color = Color3.fromRGB(0, 100, 200)
    water.Transparency = 0.4
    water.CanCollide = true
    water.Parent = workspace

    -- Rise
    local riseTween = TweenService:Create(water,
        TweenInfo.new(duration * 0.6, Enum.EasingStyle.Sine),
        { Position = Vector3.new(0, 20, 0) })
    riseTween:Play()

    task.wait(duration)

    -- Drain
    local drainTween = TweenService:Create(water,
        TweenInfo.new(5, Enum.EasingStyle.Sine),
        { Position = Vector3.new(0, -20, 0) })
    drainTween:Play()
    drainTween.Completed:Connect(function() water:Destroy() end)

    EventEnd:FireAllClients("Flood")
    rewardAll(GameConfig.Economy.EventParticipationBonus, "survived the Flood")
end

-- 3. EARTHQUAKE
function Events.Earthquake(duration)
    notify("🌍 EARTHQUAKE! Hold on tight!", "Orange")
    EventStart:FireAllClients("Earthquake", duration)

    local endTime = os.clock() + duration
    task.spawn(function()
        while os.clock() < endTime do
            task.wait(0.1)
            local shake = Vector3.new(math.random(-3,3), math.random(0,2), math.random(-3,3))
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = hrp.CFrame + shake * 0.5
                    end
                end
            end
        end
    end)

    task.wait(duration)
    EventEnd:FireAllClients("Earthquake")
    rewardAll(GameConfig.Economy.EventParticipationBonus, "survived Earthquake")
end

-- 4. FOG OF BRAINROT
function Events.FogOfBrainrot(duration)
    notify("🧠 FOG OF BRAINROT! You can barely see!", "Purple")
    EventStart:FireAllClients("FogOfBrainrot", duration)

    local orig = Lighting.FogEnd
    Lighting.FogColor = Color3.fromRGB(150, 0, 255)
    TweenService:Create(Lighting, TweenInfo.new(3), { FogEnd = 20 }):Play()

    -- Random screen effects sent to all clients
    for _, player in ipairs(Players:GetPlayers()) do
        if _G.GameAPI then
            _G.GameAPI.Notify(player, "Your brain is rotting... 🧠", "Purple")
        end
    end

    task.wait(duration)
    TweenService:Create(Lighting, TweenInfo.new(5), { FogEnd = orig }):Play()
    EventEnd:FireAllClients("FogOfBrainrot")
    rewardAll(GameConfig.Economy.EventParticipationBonus, "survived Fog of Brainrot")
end

-- 5. EGG RAIN
function Events.EggRain(duration)
    notify("🥚 EGG RAIN! Catch the eggs!", "Yellow")
    EventStart:FireAllClients("EggRain", duration)

    local endTime = os.clock() + duration
    local eggTypes = GameConfig.Conveyor.EggTypes

    task.spawn(function()
        while os.clock() < endTime do
            task.wait(0.5)
            task.spawn(function()
                local cfg = eggTypes[math.random(#eggTypes)]
                local egg = Instance.new("Part")
                egg.Name = "RainEgg"
                egg.Shape = Enum.PartType.Ball
                egg.Size = Vector3.new(1.4, 1.8, 1.4)
                egg.Color = cfg.color
                egg.Material = Enum.Material.SmoothPlastic
                egg.Position = Vector3.new(math.random(-40,40), 80, math.random(-40,40))
                egg.Parent = workspace
                Debris:AddItem(egg, 10)

                egg.Touched:Connect(function(hit)
                    local char = hit.Parent
                    local player = Players:GetPlayerFromCharacter(char)
                    if player and egg.Parent then
                        if _G.GameAPI then
                            _G.GameAPI.AddPoints(player, cfg.value)
                            _G.GameAPI.Notify(player, "Caught " .. cfg.name .. "! +" .. cfg.value, "Green")
                        end
                        egg:Destroy()
                    end
                end)
            end)
        end
    end)

    task.wait(duration)
    EventEnd:FireAllClients("EggRain")
    notify("🥚 Egg Rain has ended!", "Yellow")
end

-- 6. GRAVITY FLIP
function Events.GravityFlip(duration)
    notify("⬆️ GRAVITY FLIP! Everything is upside down!", "Cyan")
    EventStart:FireAllClients("GravityFlip", duration)

    workspace.Gravity = -GameConfig and -196.2 or -196.2

    task.wait(duration)

    workspace.Gravity = 196.2
    EventEnd:FireAllClients("GravityFlip")
    rewardAll(GameConfig.Economy.EventParticipationBonus, "survived Gravity Flip")
end

-- 7. SPEED BOOST
function Events.SpeedBoost(duration)
    notify("⚡ SPEED BOOST! Everyone gets super speed!", "Yellow")
    EventStart:FireAllClients("SpeedBoost", duration)

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 80 end
        end
    end

    task.wait(duration)

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end

    EventEnd:FireAllClients("SpeedBoost")
    rewardAll(GameConfig.Economy.EventParticipationBonus, "Speed Boost bonus")
end

-- ── Public API ────────────────────────────────────────────────────────────────

local EventsAPI = {}
_G.EventsAPI = EventsAPI

local eventMap = {
    meteorshower  = { fn = Events.MeteorShower,  dur = GameConfig.Events.Duration.MeteorShower  },
    flood         = { fn = Events.Flood,          dur = GameConfig.Events.Duration.Flood          },
    earthquake    = { fn = Events.Earthquake,     dur = GameConfig.Events.Duration.Earthquake     },
    fogofbrainrot = { fn = Events.FogOfBrainrot,  dur = GameConfig.Events.Duration.FogOfBrainrot  },
    eggrain       = { fn = Events.EggRain,        dur = GameConfig.Events.Duration.EggRain        },
    gravityflip   = { fn = Events.GravityFlip,    dur = GameConfig.Events.Duration.GravityFlip    },
    speedboost    = { fn = Events.SpeedBoost,     dur = GameConfig.Events.Duration.SpeedBoost     },
}

function EventsAPI.StartEvent(name)
    local key = name:lower():gsub(" ", "")
    local def = eventMap[key]
    if not def then return false, "Unknown event: " .. name end
    if currentEvent then return false, "An event is already running: " .. currentEvent end

    currentEvent = name
    eventThread = task.spawn(function()
        def.fn(def.dur)
        currentEvent = nil
        eventThread = nil
    end)
    return true
end

function EventsAPI.StopEvent()
    if eventThread then
        task.cancel(eventThread)
        eventThread = nil
    end
    -- Reset gravity just in case
    workspace.Gravity = 196.2
    -- Clear fog
    Lighting.FogEnd = 100000
    currentEvent = nil
    EventEnd:FireAllClients("Stopped")
    notify("🛑 The event has been stopped by an admin.", "Red")
end

function EventsAPI.GetCurrent()
    return currentEvent
end

function EventsAPI.ListEvents()
    local list = {}
    for k in pairs(eventMap) do table.insert(list, k) end
    return list
end

-- Auto random events
task.spawn(function()
    local eventNames = {}
    for k in pairs(eventMap) do table.insert(eventNames, k) end

    while true do
        task.wait(GameConfig.Events.CooldownTime)
        if not currentEvent then
            local pick = eventNames[math.random(#eventNames)]
            EventsAPI.StartEvent(pick)
        end
    end
end)

print("[Take & Brainrot] Events system loaded. " .. #(EventsAPI.ListEvents()) .. " events available.")
