-- Aura RNG | UI Components
-- Small factory helpers so every screen builds consistent, polished widgets.

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent:WaitForChild("Theme"))

local C = {}

function C.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or Theme.Corner
	c.Parent = parent
	return c
end

function C.stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Color.Stroke
	s.Thickness = thickness or 1.5
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function C.gradient(parent, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

function C.padding(parent, px)
	local p = Instance.new("UIPadding")
	local u = UDim.new(0, px or 10)
	p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = u, u, u, u
	p.Parent = parent
	return p
end

function C.label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Theme.Font
	l.TextColor3 = Theme.Color.Text
	l.TextScaled = false
	l.TextSize = 16
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	for k, v in pairs(props or {}) do l[k] = v end
	return l
end

function C.frame(props)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.Color.Panel
	f.BorderSizePixel = 0
	for k, v in pairs(props or {}) do f[k] = v end
	return f
end

-- A styled text button with hover feedback.
function C.button(props, opts)
	opts = opts or {}
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = opts.color or Theme.Color.Accent
	b.BorderSizePixel = 0
	b.Font = Theme.FontBold
	b.TextColor3 = opts.textColor or Color3.fromRGB(255, 255, 255)
	b.TextSize = 16
	b.Text = ""
	for k, v in pairs(props or {}) do b[k] = v end
	C.corner(b, opts.corner or Theme.CornerSm)

	local base = b.BackgroundColor3
	local hover = opts.hover or base:Lerp(Color3.new(1, 1, 1), 0.12)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = hover }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.08), { Size = b.Size - UDim2.fromOffset(2, 2) }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.08), { Size = b.Size }):Play()
	end)
	return b
end

-- A scrolling list container with a vertical UIListLayout.
function C.scrollList(props, padding, gap)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = Theme.Color.Accent
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	for k, v in pairs(props or {}) do s[k] = v end
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap or 8)
	layout.Parent = s
	if padding then C.padding(s, padding) end
	return s, layout
end

-- A scrolling grid container.
function C.scrollGrid(props, cellSize, gap, padding)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = Theme.Color.Accent
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	for k, v in pairs(props or {}) do s[k] = v end
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cellSize or UDim2.fromOffset(120, 140)
	grid.CellPadding = UDim2.fromOffset(gap or 10, gap or 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = s
	if padding then C.padding(s, padding) end
	return s, grid
end

-- Standard modal panel with a title bar and close button. Returns the window
-- frame, the content area, and a show/hide controller.
function C.window(parent, titleText, size)
	local screen = Instance.new("Frame")
	screen.Name = "Backdrop"
	screen.Size = UDim2.fromScale(1, 1)
	screen.BackgroundColor3 = Color3.new(0, 0, 0)
	screen.BackgroundTransparency = 0.45
	screen.Visible = false
	screen.Active = true -- swallow clicks meant for the dimmed HUD behind it
	screen.ZIndex = 5
	screen.Parent = parent

	local win = C.frame({
		Name = "Window",
		Size = size or UDim2.fromOffset(720, 460),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Color.Bg,
		ZIndex = 6,
	})
	win.Parent = screen
	C.corner(win, UDim.new(0, 16))
	C.stroke(win, Theme.Color.Stroke, 2)

	local title = C.frame({
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Color.Panel,
		ZIndex = 7,
	})
	title.Parent = win
	C.corner(title, UDim.new(0, 16))

	local titleLabel = C.label({
		Text = titleText,
		Font = Theme.FontBlack,
		TextSize = 22,
		TextColor3 = Theme.Color.Text,
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.fromOffset(20, 0),
		ZIndex = 8,
	})
	titleLabel.Parent = title

	local close = C.button({
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.new(1, -46, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "✕",
		TextSize = 20,
		ZIndex = 8,
	}, { color = Theme.Color.Bad })
	close.Parent = title

	local content = C.frame({
		Name = "Content",
		Size = UDim2.new(1, -24, 1, -66),
		Position = UDim2.fromOffset(12, 58),
		BackgroundTransparency = 1,
		ZIndex = 7,
	})
	content.Parent = win

	local controller = {}
	function controller.show()
		screen.Visible = true
		win.Size = (size or UDim2.fromOffset(720, 460)) - UDim2.fromOffset(40, 40)
		TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Back),
			{ Size = size or UDim2.fromOffset(720, 460) }):Play()
	end
	function controller.hide()
		screen.Visible = false
	end
	function controller.toggle()
		if screen.Visible then controller.hide() else controller.show() end
	end
	function controller.isOpen() return screen.Visible end

	close.MouseButton1Click:Connect(controller.hide)

	return win, content, controller, title
end

return C
