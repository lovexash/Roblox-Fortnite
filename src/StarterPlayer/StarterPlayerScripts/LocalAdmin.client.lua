-- Take & Brainrot | LocalAdmin Client
-- Handles notifications, event UI effects, and client-side visuals

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ── Notification system ───────────────────────────────────────────────────────

local function createNotif(msg, colorName)
    local colorMap = {
        Red = Color3.fromRGB(220,50,50),   Green = Color3.fromRGB(50,220,100),
        Blue = Color3.fromRGB(50,100,220), Yellow = Color3.fromRGB(230,200,50),
        Orange = Color3.fromRGB(240,140,40), Cyan = Color3.fromRGB(50,200,220),
        White = Color3.fromRGB(255,255,255), Purple = Color3.fromRGB(180,50,220),
        Pink = Color3.fromRGB(240,100,180),  Gold = Color3.fromRGB(255,200,50),
    }
    local color = colorMap[colorName] or colorMap.White

    -- Use Roblox built-in notification
    StarterGui:SetCore("SendNotification", {
        Title = "Take & Brainrot",
        Text  = msg,
        Duration = 5,
    })
end

-- ── Server announcement banner ────────────────────────────────────────────────

local function showAnnouncement(msg, colorName)
    local colorMap = {
        Red = Color3.fromRGB(220,50,50),   Green = Color3.fromRGB(50,220,100),
        Blue = Color3.fromRGB(50,100,220), Yellow = Color3.fromRGB(230,200,50),
        Orange = Color3.fromRGB(240,140,40), Cyan = Color3.fromRGB(50,200,220),
        White = Color3.fromRGB(255,255,255), Purple = Color3.fromRGB(180,50,220),
        Pink = Color3.fromRGB(240,100,180),  Gold = Color3.fromRGB(255,200,50),
        Cyan = Color3.fromRGB(0, 255, 255),
    }
    local color = colorMap[colorName] or colorMap.Yellow

    -- Find or create announce screen gui
    local sg = playerGui:FindFirstChild("AnnounceBanner")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "AnnounceBanner"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = playerGui
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.Position = UDim2.new(0, 0, -0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 4)
    accent.Position = UDim2.new(0, 0, 1, -4)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = msg
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = frame

    -- Animate in
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back),
        { Position = UDim2.new(0,0,0,0) }):Play()

    task.wait(4)

    -- Animate out
    local out = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Sine),
        { Position = UDim2.new(0,0,-0.12,0) })
    out:Play()
    out.Completed:Connect(function() frame:Destroy() end)
end

-- ── Points HUD ────────────────────────────────────────────────────────────────

local hud = Instance.new("ScreenGui")
hud.Name = "PointsHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(0, 180, 0, 50)
hudFrame.Position = UDim2.new(0.5, -90, 0, 8)
hudFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
hudFrame.BackgroundTransparency = 0.3
hudFrame.BorderSizePixel = 0
hudFrame.Parent = hud

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = hudFrame

local ptsLabel = Instance.new("TextLabel")
ptsLabel.Size = UDim2.fromScale(1, 1)
ptsLabel.BackgroundTransparency = 1
ptsLabel.Text = "🥚 Points: 0"
ptsLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
ptsLabel.TextScaled = true
ptsLabel.Font = Enum.Font.GothamBold
ptsLabel.Parent = hudFrame

-- ── Event banner ──────────────────────────────────────────────────────────────

local eventSg = Instance.new("ScreenGui")
eventSg.Name = "EventBanner"
eventSg.ResetOnSpawn = false
eventSg.Parent = playerGui

local eventLabel = Instance.new("TextLabel")
eventLabel.Size = UDim2.new(0, 300, 0, 40)
eventLabel.Position = UDim2.new(0.5, -150, 0, 70)
eventLabel.BackgroundTransparency = 1
eventLabel.Text = ""
eventLabel.TextColor3 = Color3.fromRGB(255, 100, 50)
eventLabel.TextScaled = true
eventLabel.Font = Enum.Font.GothamBold
eventLabel.TextStrokeTransparency = 0
eventLabel.Parent = eventSg

-- ── Remote event hooks ────────────────────────────────────────────────────────

RemoteEvents:WaitForChild("Notification").OnClientEvent:Connect(function(msg, color)
    createNotif(msg, color)
end)

RemoteEvents:WaitForChild("ServerAnnouncement").OnClientEvent:Connect(function(msg, color)
    showAnnouncement(msg, color)
end)

RemoteEvents:WaitForChild("UpdatePoints").OnClientEvent:Connect(function(points)
    ptsLabel.Text = "🥚 Points: " .. tostring(points)
end)

RemoteEvents:WaitForChild("EventStart").OnClientEvent:Connect(function(name, duration)
    local labels = {
        MeteorShower  = "☄️ METEOR SHOWER!",
        Flood         = "🌊 FLOOD!",
        Earthquake    = "🌍 EARTHQUAKE!",
        FogOfBrainrot = "🧠 FOG OF BRAINROT!",
        EggRain       = "🥚 EGG RAIN!",
        GravityFlip   = "⬆️ GRAVITY FLIP!",
        SpeedBoost    = "⚡ SPEED BOOST!",
    }
    eventLabel.Text = labels[name] or ("⚡ " .. name:upper() .. "!")

    -- Countdown
    task.spawn(function()
        local remaining = duration or 30
        while remaining > 0 do
            task.wait(1)
            remaining = remaining - 1
            if eventLabel.Text ~= "" then
                eventLabel.Text = (labels[name] or name) .. " (" .. remaining .. "s)"
            end
        end
    end)
end)

RemoteEvents:WaitForChild("EventEnd").OnClientEvent:Connect(function()
    eventLabel.Text = ""
end)

print("[Take & Brainrot] Local client loaded.")
