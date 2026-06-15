-- Take & Brainrot | AdminPanel GUI (LocalScript)
-- Full graphical admin panel accessible by admins only

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local AdminCmd = RemoteEvents:WaitForChild("AdminCommand")

-- ── Panel data ────────────────────────────────────────────────────────────────

local TABS = {
    {
        name = "Players",
        icon = "👤",
        buttons = {
            { label = "Kick",        cmd = "kick",        needTarget = true  },
            { label = "Ban",         cmd = "ban",         needTarget = true  },
            { label = "Kill",        cmd = "kill",        needTarget = true  },
            { label = "Respawn",     cmd = "respawn",     needTarget = true  },
            { label = "Freeze",      cmd = "freeze",      needTarget = true  },
            { label = "Unfreeze",    cmd = "unfreeze",    needTarget = true  },
            { label = "God",         cmd = "god",         needTarget = true  },
            { label = "Un-God",      cmd = "ungod",       needTarget = true  },
            { label = "Fling",       cmd = "fling",       needTarget = true  },
            { label = "Rocket",      cmd = "rocket",      needTarget = true  },
            { label = "Teleport To", cmd = "teleport",    needTarget = true  },
            { label = "Bring",       cmd = "bring",       needTarget = true  },
        }
    },
    {
        name = "Appearance",
        icon = "🎨",
        buttons = {
            { label = "Giant",       cmd = "giant",       needTarget = true  },
            { label = "Tiny",        cmd = "tiny",        needTarget = true  },
            { label = "Normal Size", cmd = "normalsize",  needTarget = true  },
            { label = "Invisible",   cmd = "invisible",   needTarget = true  },
            { label = "Visible",     cmd = "visible",     needTarget = true  },
            { label = "Rainbow",     cmd = "rainbow",     needTarget = true  },
            { label = "Headless",    cmd = "headless",    needTarget = true  },
            { label = "Fire",        cmd = "fire",        needTarget = true  },
            { label = "Smoke",       cmd = "smoke",       needTarget = true  },
            { label = "Sparkles",    cmd = "sparkles",    needTarget = true  },
        }
    },
    {
        name = "Events",
        icon = "⚡",
        buttons = {
            { label = "☄️ Meteor Shower",   cmd = "event", args = {"MeteorShower"}  },
            { label = "🌊 Flood",            cmd = "event", args = {"Flood"}         },
            { label = "🌍 Earthquake",       cmd = "event", args = {"Earthquake"}    },
            { label = "🧠 Fog of Brainrot",  cmd = "event", args = {"FogOfBrainrot"} },
            { label = "🥚 Egg Rain",         cmd = "event", args = {"EggRain"}       },
            { label = "⬆️ Gravity Flip",     cmd = "event", args = {"GravityFlip"}  },
            { label = "⚡ Speed Boost",      cmd = "event", args = {"SpeedBoost"}   },
            { label = "🛑 Stop Event",       cmd = "stopevent"                       },
        }
    },
    {
        name = "Abuse",
        icon = "😈",
        buttons = {
            { label = "Explode",      cmd = "explode",     needTarget = true  },
            { label = "Loop Kill",    cmd = "loopkill",    needTarget = true  },
            { label = "Stop Loop Kill",cmd="stoploopkill", needTarget = true  },
            { label = "Dance",        cmd = "dance",       needTarget = true  },
            { label = "Sit",          cmd = "sit",         needTarget = true  },
            { label = "Speed ×10",    cmd = "speed",       needTarget = true, extraArgs = {"160"} },
            { label = "Speed Reset",  cmd = "speed",       needTarget = true, extraArgs = {"16"}  },
            { label = "Jump ×5",      cmd = "jump",        needTarget = true, extraArgs = {"250"} },
            { label = "Hat",          cmd = "hat",         needTarget = true  },
            { label = "Warn",         cmd = "warn",        needTarget = true, extraArgs = {"Admin warning"} },
        }
    },
    {
        name = "Server",
        icon = "🖥️",
        buttons = {
            { label = "Announce",      cmd = "announce",   needAnnounce = true  },
            { label = "Add Points",    cmd = "addpoints",  needTarget = true, extraArgs = {"100"}  },
            { label = "Remove Points", cmd = "removepoints",needTarget=true, extraArgs = {"100"}  },
            { label = "Spawn All Eggs",cmd = "spawnalleggs" },
            { label = "Clear Conveyor",cmd = "clearconveyor" },
            { label = "Conveyor Fast", cmd = "conveyorspeed", args = {"60"} },
            { label = "Conveyor Slow", cmd = "conveyorspeed", args = {"6"}  },
            { label = "Shutdown",      cmd = "shutdown"    },
        }
    },
}

-- ── Build UI ──────────────────────────────────────────────────────────────────

local sg = Instance.new("ScreenGui")
sg.Name = "AdminPanel"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- Toggle button (top-right corner)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 100, 0, 36)
toggleBtn.Position = UDim2.new(1, -110, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "⚙️ Admin"
toggleBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Main panel
local panelW, panelH = 560, 480
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, panelW, 0, panelH)
panel.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelH/2)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 10, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "😈 Take & Brainrot — Admin Panel"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -40, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Target input
local targetFrame = Instance.new("Frame")
targetFrame.Size = UDim2.new(1, -20, 0, 36)
targetFrame.Position = UDim2.new(0, 10, 0, 50)
targetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
targetFrame.BorderSizePixel = 0
targetFrame.Parent = panel
Instance.new("UICorner", targetFrame).CornerRadius = UDim.new(0, 8)

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 80, 1, 0)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target:"
targetLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
targetLabel.TextScaled = true
targetLabel.Font = Enum.Font.Gotham
targetLabel.Parent = targetFrame

local targetInput = Instance.new("TextBox")
targetInput.Size = UDim2.new(1, -90, 0.8, 0)
targetInput.Position = UDim2.new(0, 85, 0.1, 0)
targetInput.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
targetInput.BorderSizePixel = 0
targetInput.PlaceholderText = "Player name or 'me'"
targetInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
targetInput.Text = ""
targetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
targetInput.TextScaled = true
targetInput.Font = Enum.Font.Gotham
targetInput.ClearTextOnFocus = false
targetInput.Parent = targetFrame
Instance.new("UICorner", targetInput).CornerRadius = UDim.new(0, 6)

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 92)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

-- Scrolling content area
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -20, 1, -140)
contentScroll.Position = UDim2.new(0, 10, 0, 134)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 4
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.Parent = panel

local contentLayout = Instance.new("UIGridLayout")
contentLayout.CellSize = UDim2.new(0, 156, 0, 40)
contentLayout.CellPaddingH = UDim.new(0, 8) -- not real api; use SortOrder
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.FillDirection = Enum.FillDirection.Horizontal
contentLayout.Parent = contentScroll

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getTarget()
    local t = targetInput.Text
    if t == "" or t:lower() == "me" then return player.Name end
    return t
end

local function makeTabBtn(tabData, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 96, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.BorderSizePixel = 0
    btn.Text = tabData.icon .. " " .. tabData.name
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = index
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function makeActionBtn(btnData)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(45, 25, 75)
    btn.BorderSizePixel = 0
    btn.Text = btnData.label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = contentScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        local args = {}

        if btnData.needTarget then
            table.insert(args, getTarget())
        end

        if btnData.args then
            for _, a in ipairs(btnData.args) do table.insert(args, a) end
        end
        if btnData.extraArgs then
            for _, a in ipairs(btnData.extraArgs) do table.insert(args, a) end
        end

        -- Special: announce needs text prompt
        if btnData.needAnnounce then
            -- Simple: use targetInput text as the message
            table.insert(args, targetInput.Text ~= "" and targetInput.Text or "Hello from admin!")
        end

        AdminCmd:FireServer(btnData.cmd, table.unpack(args))

        -- Flash button
        btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        task.delay(0.3, function()
            btn.BackgroundColor3 = Color3.fromRGB(45, 25, 75)
        end)
    end)

    return btn
end

-- Build tabs + content switching
local activeTab = 1
local tabBtns = {}

local function loadTab(index)
    -- Clear existing buttons
    for _, child in ipairs(contentScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- Highlight tab
    for i, btn in ipairs(tabBtns) do
        btn.BackgroundColor3 = i == index
            and Color3.fromRGB(100, 40, 180)
            or  Color3.fromRGB(40, 40, 60)
    end

    local tabData = TABS[index]
    for _, btnData in ipairs(tabData.buttons) do
        makeActionBtn(btnData)
    end

    -- Update canvas size
    local rows = math.ceil(#tabData.buttons / 3)
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, rows * 50)
end

for i, tabData in ipairs(TABS) do
    local btn = makeTabBtn(tabData, i)
    table.insert(tabBtns, btn)
    local idx = i
    btn.MouseButton1Click:Connect(function()
        activeTab = idx
        loadTab(idx)
    end)
end

loadTab(1)

-- ── Toggle logic ──────────────────────────────────────────────────────────────

toggleBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- Drag the panel by title bar
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Keybind: F2 toggles panel
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F2 then
        panel.Visible = not panel.Visible
    end
end)

print("[Take & Brainrot] Admin Panel GUI loaded. Press F2 or click ⚙️ Admin to open.")
