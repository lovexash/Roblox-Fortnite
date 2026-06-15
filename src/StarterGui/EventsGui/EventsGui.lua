-- Take & Brainrot | EventsGui (LocalScript)
-- Displays event countdowns, voting, and active event effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ── Event info panel (bottom-right) ──────────────────────────────────────────

local sg = Instance.new("ScreenGui")
sg.Name = "EventsGui"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local eventPanel = Instance.new("Frame")
eventPanel.Name = "EventPanel"
eventPanel.Size = UDim2.new(0, 260, 0, 80)
eventPanel.Position = UDim2.new(1, -270, 1, -100)
eventPanel.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
eventPanel.BackgroundTransparency = 0.15
eventPanel.BorderSizePixel = 0
eventPanel.Visible = false
eventPanel.Parent = sg
Instance.new("UICorner", eventPanel).CornerRadius = UDim.new(0, 12)

-- Accent stripe
local stripe = Instance.new("Frame")
stripe.Size = UDim2.new(0, 4, 1, -20)
stripe.Position = UDim2.new(0, 0, 0, 10)
stripe.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
stripe.BorderSizePixel = 0
stripe.Parent = eventPanel
Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 4)

local eventTitle = Instance.new("TextLabel")
eventTitle.Size = UDim2.new(1, -16, 0, 30)
eventTitle.Position = UDim2.new(0, 12, 0, 6)
eventTitle.BackgroundTransparency = 1
eventTitle.Text = "⚡ EVENT"
eventTitle.TextColor3 = Color3.fromRGB(255, 220, 50)
eventTitle.TextScaled = true
eventTitle.Font = Enum.Font.GothamBold
eventTitle.TextXAlignment = Enum.TextXAlignment.Left
eventTitle.Parent = eventPanel

local eventTimer = Instance.new("TextLabel")
eventTimer.Size = UDim2.new(1, -16, 0, 28)
eventTimer.Position = UDim2.new(0, 12, 0, 40)
eventTimer.BackgroundTransparency = 1
eventTimer.Text = "00:00 remaining"
eventTimer.TextColor3 = Color3.fromRGB(200, 200, 220)
eventTimer.TextScaled = true
eventTimer.Font = Enum.Font.Gotham
eventTimer.TextXAlignment = Enum.TextXAlignment.Left
eventTimer.Parent = eventPanel

-- Progress bar background
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -16, 0, 6)
progressBg.Position = UDim2.new(0, 8, 1, -12)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
progressBg.BorderSizePixel = 0
progressBg.Parent = eventPanel
Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 3)

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.fromScale(1, 1)
progressBar.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 3)

-- ── Event start flash ─────────────────────────────────────────────────────────

local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.fromScale(1, 1)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 100
flashFrame.Parent = sg

local function flashScreen(color)
    flashFrame.BackgroundColor3 = color
    TweenService:Create(flashFrame, TweenInfo.new(0.1), { BackgroundTransparency = 0.3 }):Play()
    task.wait(0.15)
    TweenService:Create(flashFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end

-- ── Event info mapping ────────────────────────────────────────────────────────

local eventInfo = {
    MeteorShower  = { title = "☄️ Meteor Shower",  color = Color3.fromRGB(255,80,20),  flash = Color3.fromRGB(255,100,50)  },
    Flood         = { title = "🌊 Flood",            color = Color3.fromRGB(50,100,220), flash = Color3.fromRGB(0,150,255)   },
    Earthquake    = { title = "🌍 Earthquake",       color = Color3.fromRGB(200,140,50), flash = Color3.fromRGB(200,150,80)  },
    FogOfBrainrot = { title = "🧠 Fog of Brainrot",  color = Color3.fromRGB(180,50,220), flash = Color3.fromRGB(150,0,200)   },
    EggRain       = { title = "🥚 Egg Rain",         color = Color3.fromRGB(230,200,50), flash = Color3.fromRGB(255,255,100) },
    GravityFlip   = { title = "⬆️ Gravity Flip",     color = Color3.fromRGB(50,200,220), flash = Color3.fromRGB(0,230,255)   },
    SpeedBoost    = { title = "⚡ Speed Boost",      color = Color3.fromRGB(255,230,50), flash = Color3.fromRGB(255,255,0)   },
}

-- ── Remote hooks ──────────────────────────────────────────────────────────────

local currentDuration = 30
local eventEndTime = 0

RemoteEvents:WaitForChild("EventStart").OnClientEvent:Connect(function(name, duration)
    local info = eventInfo[name] or { title = "⚡ " .. name, color = Color3.fromRGB(255,200,50), flash = Color3.fromRGB(255,255,255) }
    currentDuration = duration or 30
    eventEndTime = os.clock() + currentDuration

    -- Update panel
    eventTitle.Text = info.title
    stripe.BackgroundColor3 = info.color
    progressBar.BackgroundColor3 = info.color
    eventPanel.Visible = true

    flashScreen(info.flash)

    -- Animate in
    eventPanel.Position = UDim2.new(1, 10, 1, -100)
    TweenService:Create(eventPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back),
        { Position = UDim2.new(1, -270, 1, -100) }):Play()

    -- Countdown loop
    task.spawn(function()
        while os.clock() < eventEndTime and eventPanel.Visible do
            task.wait(0.5)
            local remaining = math.max(0, eventEndTime - os.clock())
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            eventTimer.Text = string.format("%02d:%02d remaining", mins, secs)
            progressBar.Size = UDim2.fromScale(remaining / currentDuration, 1)
        end
    end)
end)

RemoteEvents:WaitForChild("EventEnd").OnClientEvent:Connect(function()
    TweenService:Create(eventPanel, TweenInfo.new(0.4, Enum.EasingStyle.Sine),
        { Position = UDim2.new(1, 10, 1, -100) }).Completed:Connect(function()
        eventPanel.Visible = false
    end)
    TweenService:Create(eventPanel, TweenInfo.new(0.4, Enum.EasingStyle.Sine),
        { Position = UDim2.new(1, 10, 1, -100) }):Play()
end)

print("[Take & Brainrot] Events GUI loaded.")
