-- Aura RNG | Client bootstrap
-- Builds the shared ScreenGui, sets up the client context (profile state +
-- remotes + window registry), and initializes every UI module.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local net       = ReplicatedStorage:WaitForChild("Net")

local UI = script.Parent:WaitForChild("UI")

-- ── Resolve remotes by name ──────────────────────────────────────────────────
local RemoteList = require(ReplicatedStorage:WaitForChild("Remotes"))
local remotes = {}
for name in pairs(RemoteList) do
	remotes[name] = net:WaitForChild(name)
end

-- ── Shared ScreenGui ─────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraRNG"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = playerGui

-- ── Profile state + subscription ─────────────────────────────────────────────
local currentProfile = nil
local profileCallbacks = {}

local ctx = {
	player    = player,
	playerGui = playerGui,
	screenGui = screenGui,
	remotes   = remotes,
}

function ctx.getProfile()
	return currentProfile
end

function ctx.onProfile(fn)
	table.insert(profileCallbacks, fn)
	if currentProfile then
		task.spawn(fn, currentProfile)
	end
end

local function fireProfile()
	for _, fn in ipairs(profileCallbacks) do
		task.spawn(fn, currentProfile)
	end
end

remotes.UpdateProfile.OnClientEvent:Connect(function(snapshot)
	currentProfile = snapshot
	fireProfile()
end)

-- ── Window registry (only one modal open at a time) ──────────────────────────
local windows = {}
function ctx.registerWindow(name, controller)
	windows[name] = controller
end
function ctx.openWindow(name)
	for n, w in pairs(windows) do
		if n ~= name and w.isOpen() then w.hide() end
	end
	local target = windows[name]
	if target then target.toggle() end
end

-- ── Initialize UI modules ────────────────────────────────────────────────────
-- Notifications first (provides ctx.notify used by others).
require(UI:WaitForChild("Notifications")).Init(ctx)
require(UI:WaitForChild("MainHUD")).Init(ctx)
require(UI:WaitForChild("RollReveal")).Init(ctx)
require(UI:WaitForChild("Inventory")).Init(ctx)
require(UI:WaitForChild("Shop")).Init(ctx)
require(UI:WaitForChild("Capsules")).Init(ctx)
require(UI:WaitForChild("Index")).Init(ctx)
require(UI:WaitForChild("Trade")).Init(ctx)

-- Welcome toast once the profile arrives.
local welcomed = false
ctx.onProfile(function()
	if not welcomed then
		welcomed = true
		ctx.notify("Welcome to Aura RNG! Press 🎲 or Space to roll.", "success")
	end
end)

print("[Aura RNG] Client UI loaded.")
