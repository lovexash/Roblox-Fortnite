-- Take & Brainrot | AdminAbuse Server
-- Extra fun abuse tools that go beyond basic admin
-- These are strictly server-sided and triggered via chat or AdminPanel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local function notify(player, msg, color)
    if _G.GameAPI then _G.GameAPI.Notify(player, msg, color) end
end

local function announce(msg, color)
    if _G.GameAPI then _G.GameAPI.Announce(msg, color) end
end

-- Registered abuse actions (called by AdminSystem or panel)
local AbuseActions = {}
_G.AbuseActions = AbuseActions

-- ── Catapult: launch all players at once ─────────────────────────────────────
function AbuseActions.catapultAll()
    announce("😈 EVERYONE GETS LAUNCHED!", "Red")
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(
                    math.random(-300, 300),
                    math.random(200, 500),
                    math.random(-300, 300)
                )
            end
        end
    end
end

-- ── Disco Mode: constantly change every player's body colour ─────────────────
local discoActive = false
function AbuseActions.discoStart()
    if discoActive then return end
    discoActive = true
    announce("🪩 DISCO MODE ACTIVATED!", "White")
    task.spawn(function()
        local hue = 0
        while discoActive do
            task.wait(0.07)
            hue = (hue + 0.04) % 1
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.Color = Color3.fromHSV((hue + math.random()*0.15) % 1, 1, 1)
                        end
                    end
                end
            end
        end
    end)
end

function AbuseActions.discoStop()
    discoActive = false
    announce("🪩 Disco mode off.", "White")
end

-- ── Gravity chaos: randomize gravity every second ────────────────────────────
local gravityChaosActive = false
function AbuseActions.gravityChaosStart(duration)
    if gravityChaosActive then return end
    gravityChaosActive = true
    announce("🌀 GRAVITY CHAOS!", "Purple")
    local endTime = os.clock() + (duration or 20)
    task.spawn(function()
        while gravityChaosActive and os.clock() < endTime do
            task.wait(1)
            game.Workspace.Gravity = math.random(-300, 500)
        end
        game.Workspace.Gravity = 196.2
        gravityChaosActive = false
        announce("🌀 Gravity restored.", "Green")
    end)
end

-- ── Part Bomb: spawn hundreds of falling parts ────────────────────────────────
function AbuseActions.partBomb(amount)
    amount = math.clamp(amount or 50, 1, 200)
    announce("💣 PART BOMB! " .. amount .. " parts incoming!", "Orange")
    for i = 1, amount do
        task.spawn(function()
            task.wait(math.random() * 2)
            local p = Instance.new("Part")
            p.Size = Vector3.new(math.random(1,6), math.random(1,6), math.random(1,6))
            p.Color = Color3.fromHSV(math.random(), 1, 1)
            p.Material = Enum.Material.Neon
            p.Position = Vector3.new(math.random(-50,50), 80, math.random(-50,50))
            p.Parent = game.Workspace
            Debris:AddItem(p, 15)
        end)
    end
end

-- ── Shrink/Grow all: cycle everyone through sizes ────────────────────────────
function AbuseActions.sizeWave()
    announce("📏 SIZE WAVE!", "Cyan")
    task.spawn(function()
        for _, size in ipairs({0.2, 5, 1}) do
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then char:ScaleTo(size) end
            end
            task.wait(4)
        end
    end)
end

-- ── Chaos Mode: combine multiple abuses ──────────────────────────────────────
function AbuseActions.chaosMode()
    announce("💀 CHAOS MODE ACTIVATED! 💀", "Red")
    task.spawn(function()
        AbuseActions.partBomb(80)
        task.wait(1)
        AbuseActions.catapultAll()
        task.wait(2)
        AbuseActions.discoStart()
        AbuseActions.gravityChaosStart(15)
        task.wait(15)
        AbuseActions.discoStop()
        announce("💀 Chaos Mode ended.", "Orange")
    end)
end

-- ── Headless all ─────────────────────────────────────────────────────────────
function AbuseActions.headlessAll()
    announce("👻 HEADLESS EVERYONE!", "White")
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then head.Transparency = 1 end
        end
    end
end

-- ── Noclip all ───────────────────────────────────────────────────────────────
local noclipPlayers = {}
local noclipConn

local function updateNoclip()
    if not noclipConn then
        noclipConn = game:GetService("RunService").Stepped:Connect(function()
            for uid, _ in pairs(noclipPlayers) do
                local player = Players:GetPlayerByUserId(uid)
                if player then
                    local char = player.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end
        end)
    end
end

function AbuseActions.noclip(player)
    if noclipPlayers[player.UserId] then
        noclipPlayers[player.UserId] = nil
        notify(player, "Noclip OFF", "Orange")
    else
        noclipPlayers[player.UserId] = true
        updateNoclip()
        notify(player, "Noclip ON 👻", "Cyan")
    end
end

-- ── Give everyone max speed burst ────────────────────────────────────────────
function AbuseActions.speedBurstAll(duration)
    announce("⚡ EVERYONE GETS SPEED BURST!", "Yellow")
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 200 end
        end
    end
    task.wait(duration or 10)
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
    announce("⚡ Speed burst ended.", "Yellow")
end

-- ── Wrap chat command for abuse actions ──────────────────────────────────────
-- These use the same prefix but are handled here (lower priority than AdminSystem)
local prefix = GameConfig.Admin.CommandPrefix

local function getLevel(player)
    local uid = player.UserId
    for _, id in ipairs(GameConfig.Admin.Owners) do
        if id == uid then return 3 end
    end
    for _, id in ipairs(GameConfig.Admin.Admins) do
        if id == uid then return 2 end
    end
    return 0
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if msg:sub(1, #prefix) ~= prefix then return end
        if getLevel(player) < 2 then return end  -- Admin+ only

        local parts = {}
        for w in msg:sub(#prefix+1):gmatch("%S+") do table.insert(parts, w) end
        if #parts == 0 then return end

        local cmd = parts[1]:lower()
        local arg1 = tonumber(parts[2])

        if cmd == "catapultall"    then AbuseActions.catapultAll()
        elseif cmd == "disco"      then AbuseActions.discoStart()
        elseif cmd == "discooff"   then AbuseActions.discoStop()
        elseif cmd == "partbomb"   then AbuseActions.partBomb(arg1)
        elseif cmd == "sizewave"   then AbuseActions.sizeWave()
        elseif cmd == "chaos"      then AbuseActions.chaosMode()
        elseif cmd == "headlessall"then AbuseActions.headlessAll()
        elseif cmd == "speedburst" then AbuseActions.speedBurstAll(arg1)
        elseif cmd == "gravitychaos" then AbuseActions.gravityChaosStart(arg1)
        elseif cmd == "noclip"     then
            local target = Players:FindFirstChild(parts[2] or "")
            if target then AbuseActions.noclip(target)
            else AbuseActions.noclip(player) end
        end
    end)
end)

print("[Take & Brainrot] Admin Abuse system loaded.")
