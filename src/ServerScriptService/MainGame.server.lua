-- Take & Brainrot | MainGame Server
-- Initializes the game, sets up RemoteEvents and player data

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- DataStore
local PointsStore = DataStoreService:GetDataStore("TakeAndBrainrot_Points_v1")

-- In-memory player data
local PlayerData = {}

-- Remote events folder
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local function makeRemote(name, isFunction)
    local existing = RemoteEvents:FindFirstChild(name)
    if existing then return existing end
    local r = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
    r.Name = name
    r.Parent = RemoteEvents
    return r
end

-- Create all remotes
local Remotes = {
    UpdatePoints       = makeRemote("UpdatePoints"),
    Notification       = makeRemote("Notification"),
    AdminCommand       = makeRemote("AdminCommand"),
    EventStart         = makeRemote("EventStart"),
    EventEnd           = makeRemote("EventEnd"),
    EggPickup          = makeRemote("EggPickup"),
    OpenAdminPanel     = makeRemote("OpenAdminPanel"),
    ServerAnnouncement = makeRemote("ServerAnnouncement"),
    GetPlayerData      = makeRemote("GetPlayerData", true),
    ConveyorUpdate     = makeRemote("ConveyorUpdate"),
}

-- Load player data from DataStore
local function loadPlayerData(player)
    local success, data = pcall(function()
        return PointsStore:GetAsync("player_" .. player.UserId)
    end)

    PlayerData[player.UserId] = {
        points   = (success and data and data.points) or 0,
        warnings = (success and data and data.warnings) or {},
        banned   = (success and data and data.banned) or false,
        joinTime = os.time(),
    }

    Remotes.UpdatePoints:FireClient(player, PlayerData[player.UserId].points)
end

-- Save player data to DataStore
local function savePlayerData(player)
    local data = PlayerData[player.UserId]
    if not data then return end

    pcall(function()
        PointsStore:SetAsync("player_" .. player.UserId, {
            points   = data.points,
            warnings = data.warnings,
            banned   = data.banned,
        })
    end)
end

-- Public API used by other server scripts
local GameAPI = {}
_G.GameAPI = GameAPI

function GameAPI.GetData(player)
    return PlayerData[player.UserId]
end

function GameAPI.AddPoints(player, amount)
    local data = PlayerData[player.UserId]
    if not data then return end
    data.points = math.max(0, data.points + amount)
    Remotes.UpdatePoints:FireClient(player, data.points)
end

function GameAPI.SetPoints(player, amount)
    local data = PlayerData[player.UserId]
    if not data then return end
    data.points = math.max(0, amount)
    Remotes.UpdatePoints:FireClient(player, data.points)
end

function GameAPI.Notify(player, msg, color)
    Remotes.Notification:FireClient(player, msg, color or "White")
end

function GameAPI.Announce(msg, color)
    Remotes.ServerAnnouncement:FireAllClients(msg, color or "Yellow")
end

-- RemoteFunction: return player data to client
Remotes.GetPlayerData.OnServerInvoke = function(player)
    return PlayerData[player.UserId]
end

-- Egg pickup
Remotes.EggPickup.OnServerEvent:Connect(function(player, eggValue)
    GameAPI.AddPoints(player, eggValue + GameConfig.Economy.PickupEggBonus)
    GameAPI.Notify(player, "You picked up an egg! +" .. (eggValue + GameConfig.Economy.PickupEggBonus) .. " points", "Green")
end)

-- Player join / leave
Players.PlayerAdded:Connect(function(player)
    loadPlayerData(player)

    player.CharacterAdded:Connect(function(char)
        -- Give a leaderstats board
        local ls = player:FindFirstChild("leaderstats")
        if not ls then
            ls = Instance.new("Folder")
            ls.Name = "leaderstats"
            ls.Parent = player
        end

        local pts = ls:FindFirstChild("Points") or Instance.new("IntValue")
        pts.Name = "Points"
        pts.Parent = ls

        -- Keep leaderstats in sync
        local data = PlayerData[player.UserId]
        if data then pts.Value = data.points end

        -- Hook points changes to leaderstats
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            local d = PlayerData[player.UserId]
            if not d then conn:Disconnect() return end
            pts.Value = d.points
        end)
    end)

    GameAPI.Announce(player.Name .. " joined Take & Brainrot!", "Cyan")
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    PlayerData[player.UserId] = nil
end)

-- Auto-save every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

print("[Take & Brainrot] Main game server loaded. Version " .. GameConfig.VERSION)
