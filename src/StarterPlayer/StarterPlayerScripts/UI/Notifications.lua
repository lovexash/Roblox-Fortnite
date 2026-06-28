-- Aura RNG | Notifications
-- A stacked toast system in the top-right. Driven by the Notify remote and by
-- local calls through ctx.notify().

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent:WaitForChild("Theme"))
local C     = require(script.Parent:WaitForChild("Components"))

local Notifications = {}

local KIND_COLOR = {
	info    = Theme.Color.Accent,
	success = Theme.Color.Good,
	error   = Theme.Color.Bad,
	warn    = Theme.Color.Warn,
}

function Notifications.Init(ctx)
	local holder = C.frame({
		Name = "Notifications",
		Size = UDim2.fromOffset(320, 600),
		Position = UDim2.new(1, -16, 0, 90),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
	})
	holder.Parent = ctx.screenGui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = holder

	local order = 0
	local function push(message, kind)
		order += 1
		local accent = KIND_COLOR[kind] or KIND_COLOR.info
		local toast = C.frame({
			Name = "Toast",
			Size = UDim2.fromOffset(300, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Color.Panel,
			LayoutOrder = -order,
			ZIndex = 51,
		})
		C.corner(toast)
		C.stroke(toast, accent, 1.5, 0.2)

		local stripe = C.frame({
			Size = UDim2.new(0, 4, 1, -12),
			Position = UDim2.fromOffset(6, 6),
			BackgroundColor3 = accent,
			ZIndex = 52,
		})
		stripe.Parent = toast
		C.corner(stripe, UDim.new(0, 2))

		local text = C.label({
			Text = message,
			TextWrapped = true,
			TextSize = 15,
			Size = UDim2.new(1, -28, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.fromOffset(18, 0),
			ZIndex = 52,
		})
		text.Parent = toast
		C.padding(text, 10)
		toast.Parent = holder

		-- Slide / fade in.
		toast.Position = UDim2.fromOffset(60, 0)
		toast.BackgroundTransparency = 1
		TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
			{ BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0) }):Play()

		task.delay(4.2, function()
			local fade = TweenService:Create(toast, TweenInfo.new(0.3),
				{ BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			toast:Destroy()
		end)
	end

	ctx.notify = push
	ctx.remotes.Notify.OnClientEvent:Connect(push)
end

return Notifications
