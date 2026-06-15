-- Take & Brainrot | AdminSystem Server
-- Handles all admin command parsing and execution

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminConfig"))
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ── Permission helpers ────────────────────────────────────────────────────────

local function getLevel(player)
    local uid = player.UserId
    for _, id in ipairs(GameConfig.Admin.Owners) do
        if id == uid then return AdminConfig.Levels.Owner end
    end
    for _, id in ipairs(GameConfig.Admin.Admins) do
        if id == uid then return AdminConfig.Levels.Admin end
    end
    return AdminConfig.Levels.Player
end

local function hasPermission(player, cmdName)
    local def = AdminConfig.Commands[cmdName]
    if not def then return false end
    return getLevel(player) >= def.level
end

-- ── Player finding ────────────────────────────────────────────────────────────

local function findPlayer(query)
    query = query:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == query or p.DisplayName:lower() == query then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #query) == query then return p end
    end
    return nil
end

-- ── Notification shortcut ─────────────────────────────────────────────────────

local function notify(player, msg, color)
    if _G.GameAPI then _G.GameAPI.Notify(player, msg, color) end
end

-- ── Command implementations ───────────────────────────────────────────────────

local Cmds = {}

-- kick
function Cmds.kick(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found: " .. (args[1] or "?"), "Red") return end
    local reason = table.concat(args, " ", 2) or "Kicked by admin"
    target:Kick("[Take & Brainrot] " .. reason)
    notify(caller, "Kicked " .. target.Name, "Orange")
end

-- ban  (persistent via DataStore via MainGame API)
function Cmds.ban(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local reason = table.concat(args, " ", 2) or "Banned by admin"
    local data = _G.GameAPI and _G.GameAPI.GetData(target)
    if data then data.banned = true end
    target:Kick("[Take & Brainrot] You are banned. Reason: " .. reason)
    notify(caller, "Banned " .. target.Name, "Red")
end

-- mute / unmute (stored in-memory)
local mutedPlayers = {}
function Cmds.mute(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    mutedPlayers[target.UserId] = true
    notify(caller, "Muted " .. target.Name, "Orange")
    notify(target, "You have been muted by an admin.", "Red")
end
function Cmds.unmute(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    mutedPlayers[target.UserId] = nil
    notify(caller, "Unmuted " .. target.Name, "Green")
    notify(target, "You have been unmuted.", "Green")
end

-- warn
local warnings = {}
function Cmds.warn(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local reason = table.concat(args, " ", 2) or "No reason given"
    warnings[target.UserId] = (warnings[target.UserId] or 0) + 1
    notify(target, "⚠️ WARNING #" .. warnings[target.UserId] .. ": " .. reason, "Orange")
    notify(caller, "Warned " .. target.Name .. " (" .. warnings[target.UserId] .. " total)", "Yellow")
    if warnings[target.UserId] >= 3 then
        target:Kick("[Take & Brainrot] Auto-kicked: 3 warnings.")
    end
end

-- teleport / goto / bring
function Cmds.teleport(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local callerChar = caller.Character
    local targetChar = target.Character
    if not callerChar or not targetChar then notify(caller, "Character not found.", "Red") return end
    callerChar:PivotTo(targetChar:GetPivot() + Vector3.new(3, 0, 0))
    notify(caller, "Teleported to " .. target.Name, "Cyan")
end
Cmds.goto = Cmds.teleport

function Cmds.bring(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local callerChar = caller.Character
    local targetChar = target.Character
    if not callerChar or not targetChar then notify(caller, "Character not found.", "Red") return end
    targetChar:PivotTo(callerChar:GetPivot() + Vector3.new(3, 0, 0))
    notify(caller, "Brought " .. target.Name, "Cyan")
    notify(target, "You were brought by " .. caller.Name, "Cyan")
end

-- fling
function Cmds.fling(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.Velocity = Vector3.new(math.random(-200,200), 300, math.random(-200,200))
    notify(caller, "Flung " .. target.Name .. " 🚀", "Orange")
end

-- freeze / unfreeze
function Cmds.freeze(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored = true end
    end
    notify(caller, "Froze " .. target.Name .. " 🥶", "Cyan")
    notify(target, "You have been frozen by an admin! 🥶", "Cyan")
end

function Cmds.unfreeze(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored = false end
    end
    notify(caller, "Unfroze " .. target.Name, "Green")
    notify(target, "You have been unfrozen.", "Green")
end

-- kill / respawn
function Cmds.kill(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    notify(caller, "Killed " .. target.Name + " 💀", "Red")
end

function Cmds.respawn(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    target:LoadCharacter()
    notify(caller, "Respawned " .. target.Name, "Green")
end

-- god / ungod
local godPlayers = {}
function Cmds.god(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        godPlayers[target.UserId] = true
    end
    notify(caller, target.Name .. " is now a god ✨", "Yellow")
    notify(target, "You have been given GOD mode! ✨", "Yellow")
end
function Cmds.ungod(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = 100
        hum.Health = 100
    end
    godPlayers[target.UserId] = nil
    notify(caller, "Removed god from " .. target.Name, "Orange")
end

-- size: giant / tiny / normalsize
function Cmds.giant(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    char:ScaleTo(5)
    notify(caller, target.Name .. " is now GIANT 🦕", "Orange")
end
function Cmds.tiny(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    char:ScaleTo(0.3)
    notify(caller, target.Name .. " is now tiny 🐜", "Cyan")
end
function Cmds.normalsize(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    char:ScaleTo(1)
    notify(caller, "Reset " .. target.Name .. "'s size", "Green")
end

-- speed / jump
function Cmds.speed(caller, args)
    local target = findPlayer(args[1])
    local val = tonumber(args[2]) or 16
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = math.clamp(val, 0, 500) end
    notify(caller, "Set " .. target.Name .. "'s speed to " .. val, "Cyan")
end
function Cmds.jump(caller, args)
    local target = findPlayer(args[1])
    local val = tonumber(args[2]) or 50
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = math.clamp(val, 0, 500) end
    notify(caller, "Set " .. target.Name .. "'s jump to " .. val, "Cyan")
end

-- invisible / visible
function Cmds.invisible(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then part.Transparency = 1 end
    end
    notify(caller, target.Name .. " is now invisible 👻", "White")
end
function Cmds.visible(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Transparency = 0
        elseif part:IsA("Decal") then part.Transparency = 0 end
    end
    notify(caller, target.Name .. " is now visible", "Green")
end

-- fire / smoke / sparkles
local function addEffect(target, effectClass, caller, label)
    local char = target.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- remove existing
    for _, c in ipairs(hrp:GetChildren()) do
        if c:IsA(effectClass) then c:Destroy() end
    end
    local fx = Instance.new(effectClass)
    fx.Parent = hrp
    notify(caller, "Added " .. label .. " to " .. target.Name, "Orange")
end

function Cmds.fire(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    addEffect(target, "Fire", caller, "🔥 fire")
end
function Cmds.smoke(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    addEffect(target, "Smoke", caller, "💨 smoke")
end
function Cmds.sparkles(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    addEffect(target, "Sparkles", caller, "✨ sparkles")
end

-- explode
function Cmds.explode(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local e = Instance.new("Explosion")
    e.Position = hrp.Position
    e.BlastRadius = 15
    e.BlastPressure = 500000
    e.Parent = game.Workspace
    notify(caller, "💥 Exploded " .. target.Name, "Red")
end

-- rocket
function Cmds.rocket(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.Velocity = Vector3.new(0, 500, 0)
    notify(caller, "🚀 Launched " .. target.Name, "Orange")
end

-- loop kill
local loopKillThreads = {}
function Cmds.loopkill(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    if loopKillThreads[target.UserId] then
        notify(caller, target.Name .. " is already being loop killed.", "Orange")
        return
    end
    loopKillThreads[target.UserId] = task.spawn(function()
        while loopKillThreads[target.UserId] do
            task.wait(0.5)
            local char = target.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end
    end)
    notify(caller, "💀 Loop killing " .. target.Name, "Red")
end
function Cmds.stoploopkill(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    if loopKillThreads[target.UserId] then
        task.cancel(loopKillThreads[target.UserId])
        loopKillThreads[target.UserId] = nil
    end
    notify(caller, "Stopped loop kill on " .. target.Name, "Green")
end

-- rainbow
function Cmds.rainbow(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    task.spawn(function()
        local hue = 0
        for _ = 1, 100 do
            task.wait(0.05)
            hue = (hue + 0.03) % 1
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Color = Color3.fromHSV(hue, 1, 1)
                end
            end
        end
    end)
    notify(caller, "🌈 Rainbow on " .. target.Name, "White")
end

-- headless
function Cmds.headless(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then head.Transparency = 1 end
    notify(caller, target.Name .. " is now headless 💀", "Orange")
end

-- sit / dance (force animations)
function Cmds.sit(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
    notify(caller, "Made " .. target.Name .. " sit 🪑", "Cyan")
end

-- Points management
function Cmds.addpoints(caller, args)
    local target = findPlayer(args[1])
    local amount = tonumber(args[2]) or 100
    if not target then notify(caller, "Player not found.", "Red") return end
    if _G.GameAPI then _G.GameAPI.AddPoints(target, amount) end
    notify(caller, "Gave " .. amount .. " pts to " .. target.Name, "Green")
end
function Cmds.removepoints(caller, args)
    local target = findPlayer(args[1])
    local amount = tonumber(args[2]) or 100
    if not target then notify(caller, "Player not found.", "Red") return end
    if _G.GameAPI then _G.GameAPI.AddPoints(target, -amount) end
    notify(caller, "Removed " .. amount .. " pts from " .. target.Name, "Orange")
end
function Cmds.setpoints(caller, args)
    local target = findPlayer(args[1])
    local amount = tonumber(args[2]) or 0
    if not target then notify(caller, "Player not found.", "Red") return end
    if _G.GameAPI then _G.GameAPI.SetPoints(target, amount) end
    notify(caller, "Set " .. target.Name .. "'s points to " .. amount, "Yellow")
end

-- Events
function Cmds.event(caller, args)
    local eventName = args[1] or ""
    if _G.EventsAPI then
        local ok, err = _G.EventsAPI.StartEvent(eventName)
        if ok then
            notify(caller, "Started event: " .. eventName, "Green")
        else
            notify(caller, err or "Failed to start event", "Red")
            -- List available
            local list = _G.EventsAPI.ListEvents()
            notify(caller, "Available: " .. table.concat(list, ", "), "White")
        end
    end
end
function Cmds.stopevent(caller, args)
    if _G.EventsAPI then _G.EventsAPI.StopEvent() end
    notify(caller, "Stopped current event", "Orange")
end

-- Announce / PM
function Cmds.announce(caller, args)
    local msg = table.concat(args, " ")
    if _G.GameAPI then _G.GameAPI.Announce("[ADMIN] " .. msg, "Yellow") end
end
function Cmds.pm(caller, args)
    local target = findPlayer(args[1])
    if not target then notify(caller, "Player not found.", "Red") return end
    local msg = table.concat(args, " ", 2)
    notify(target, "[PM from " .. caller.Name .. "] " .. msg, "Pink")
    notify(caller, "[PM to " .. target.Name .. "] " .. msg, "Pink")
end

-- Conveyor
function Cmds.conveyorspeed(caller, args)
    local val = tonumber(args[1]) or 16
    if _G.ConveyorAPI then _G.ConveyorAPI.SetSpeed(val) end
    notify(caller, "Conveyor speed set to " .. val, "Cyan")
end
function Cmds.spawnalleggs(caller, args)
    if _G.ConveyorAPI then _G.ConveyorAPI.SpawnAll() end
    notify(caller, "Spawned all egg types!", "Yellow")
end
function Cmds.clearconveyor(caller, args)
    if _G.ConveyorAPI then _G.ConveyorAPI.ClearAll() end
    notify(caller, "Cleared all eggs from conveyor", "Orange")
end

-- Shutdown
function Cmds.shutdown(caller, args)
    if _G.GameAPI then _G.GameAPI.Announce("🔴 Server is shutting down... Goodbye!", "Red") end
    task.wait(3)
    for _, p in ipairs(Players:GetPlayers()) do p:Kick("Server shutting down.") end
end

-- Info commands
function Cmds.cmds(caller, args)
    local level = getLevel(caller)
    local lines = {"=== Take & Brainrot Commands ==="}
    for name, def in pairs(AdminConfig.Commands) do
        if level >= def.level then
            table.insert(lines, "!" .. name .. " - " .. def.desc)
        end
    end
    notify(caller, table.concat(lines, "\n"), "White")
end

function Cmds.admins(caller, args)
    local onlineAdmins = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if getLevel(p) >= AdminConfig.Levels.Mod then
            table.insert(onlineAdmins, p.Name .. " [Lv" .. getLevel(p) .. "]")
        end
    end
    notify(caller, "Online Admins: " .. (next(onlineAdmins) and table.concat(onlineAdmins, ", ") or "None"), "Cyan")
end

function Cmds.info(caller, args)
    notify(caller, string.format(
        "🎮 %s v%s | Players: %d | Event: %s",
        GameConfig.GAME_NAME,
        GameConfig.VERSION,
        #Players:GetPlayers(),
        (_G.EventsAPI and _G.EventsAPI.GetCurrent()) or "None"
    ), "White")
end

function Cmds.ping(caller, args)
    notify(caller, "Pong! Server is alive ✅", "Green")
end

-- ── Chat listener ─────────────────────────────────────────────────────────────

local prefix = GameConfig.Admin.CommandPrefix

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if msg:sub(1, #prefix) ~= prefix then return end

        local parts = {}
        for word in msg:sub(#prefix + 1):gmatch("%S+") do
            table.insert(parts, word)
        end
        if #parts == 0 then return end

        local cmdName = parts[1]:lower()
        local args = {}
        for i = 2, #parts do table.insert(args, parts[i]) end

        -- Permission check
        if not AdminConfig.Commands[cmdName] then return end
        if not hasPermission(player, cmdName) then
            notify(player, "❌ You don't have permission to use !" .. cmdName, "Red")
            return
        end

        -- Run command
        local fn = Cmds[cmdName]
        if fn then
            local ok, err = pcall(fn, player, args)
            if not ok then
                notify(player, "Command error: " .. tostring(err), "Red")
                warn("[AdminSystem] Command error in !" .. cmdName .. ": " .. tostring(err))
            end
        end
    end)
end)

-- Remote command from AdminPanel GUI
RemoteEvents:WaitForChild("AdminCommand").OnServerEvent:Connect(function(player, cmdName, ...)
    if not AdminConfig.Commands[cmdName] then return end
    if not hasPermission(player, cmdName) then return end
    local fn = Cmds[cmdName]
    if fn then
        local args = {...}
        pcall(fn, player, args)
    end
end)

print("[Take & Brainrot] Admin system loaded. " .. #(function() local n=0 for _ in pairs(Cmds) do n=n+1 end return {n} end)()[1] .. " commands registered.")
