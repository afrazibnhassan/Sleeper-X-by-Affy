--[[
	SLEEPER X  |  Rivals
	by Affy
	RightShift = menu   K = aim toggle
]]

if getgenv().SleeperX then
	pcall(function() getgenv().SleeperX.Unload() end)
end

-- ── compat shims ────────────────────────────────────────────
local ok, Players = pcall(function() return game:GetService("Players") end)
if not ok then return end

local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local HttpService  = game:GetService("HttpService")

local okSS, SoundService = pcall(function() return game:GetService("SoundService") end)
local okRS, RS           = pcall(function() return game:GetService("ReplicatedStorage") end)
local okStats, Stats     = pcall(function() return game:GetService("Stats") end)
local okTP, Teleport     = pcall(function() return game:GetService("TeleportService") end)

local LP = Players.LocalPlayer

local RFT_EXCLUDE = Enum.RaycastFilterType.Exclude
	or Enum.RaycastFilterType.Blacklist

local HAS_DRAW = (typeof(Drawing) == "table") and (typeof(Drawing.new) == "function")

local function identity(level)
	local setter = setthreadidentity or set_thread_identity
		or (syn and syn.set_thread_identity) or (fluxus and fluxus.set_thread_identity)
	if setter then pcall(setter, level) end
end

local CONNS = {}
local function conn(c)
	if c then table.insert(CONNS, c) end
	return c
end

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function cam() return workspace.CurrentCamera end

-- ── defaults ────────────────────────────────────────────────

local DEFAULTS = {
	Aimbot = false, AimMode = "Hold", RequireRMB = true,
	Key = Enum.KeyCode.K,
	FOV = 180, FullFOV = false, DynamicFOV = false,
	Smooth = 0.40, Ease = "Quad", Humanize = 0.0,
	Prediction = 0.6, BulletSpeed = 800,
	AimPart = "Head", Sticky = false, Priority = "Crosshair",
	WallCheck = true, SilentAim = false,
	Trigger = false, TrigFOV = 14, TrigDelay = 0.05, TrigJitter = 0.02, TrigRate = 0.02,

	Rage = false,
	RageThroughWalls = true, RageFOV = 260,
	RageAutoFire = true, RagePredict = 0.9,

	FOVColor = Color3.fromRGB(90, 255, 140), FOVThick = 1, FOVTrans = 0.55,

	ESP = false, TeamCheck = true,
	Box2D = true, Box3D = false, Skeleton = false,
	HealthBar = true, NameTag = true, DistanceTag = true,
	Tracer = false, HeadDot = true, Offscreen = false,
	Chams = false, ChamsTrans = 0.55, ChamsOutlineTrans = 0.1,
	TargetHL = true,
	EspColor = Color3.fromRGB(90, 255, 140),
	AllyColor = Color3.fromRGB(120, 180, 255),
	TagSize = 13,
	Fullbright = false, NoFog = false,
	CamFOVOn = false, CamFOV = 70,

	Crosshair = false, CrossStyle = "Cross", CrossSize = 10, CrossGap = 4,
	CrossThick = 1, CrossColor = Color3.fromRGB(255, 255, 255), Hitmarker = true,

	InfJump = false, SpeedOn = false, WalkSpeed = 22,
	JumpPowerOn = false, JumpPower = 50,
	Fly = false, FlySpeed = 60, Noclip = false,
	AutoJump = false, AntiAFK = false,

	Watermark = true, PlayerList = false, BindList = false,

	Accent = 1, Opacity = 0.0,

	SkinsOn = false, Skins = {}, Wraps = {},
}

local function deepCopy(t)
	local o = {}
	for k, v in pairs(t) do
		if type(v) == "table" then o[k] = deepCopy(v) else o[k] = v end
	end
	return o
end

local CFG = deepCopy(DEFAULTS)

local ACCENTS = {
	Color3.fromRGB(90, 255, 140),
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(255, 100, 130),
	Color3.fromRGB(255, 215, 100),
	Color3.fromRGB(200, 130, 255),
	Color3.fromRGB(255, 255, 255),
}

local ACCENT = ACCENTS[1]

-- ── config file ─────────────────────────────────────────────

local CONFIG_FILE = "SleeperX_Rivals.json"
local hasFS = (typeof(writefile) == "function")
	and (typeof(readfile) == "function")
	and (typeof(isfile) == "function")

local function encodeCFG()
	local out = {}
	for k, v in pairs(CFG) do
		if type(v) == "Color3" then
			out[k] = { __c = true, v.R, v.G, v.B }
		elseif type(v) == "EnumItem" then
			out[k] = { __e = true, v.Name, tostring(v.EnumType) }
		else
			out[k] = v
		end
	end
	return HttpService:JSONEncode(out)
end

local function decodeInto(str)
	local data = HttpService:JSONDecode(str)
	for k, v in pairs(data) do
		if DEFAULTS[k] ~= nil then
			if type(v) == "table" and v.__c then
				CFG[k] = Color3.new(v[1], v[2], v[3])
			elseif type(v) == "table" and v.__e then
				local good, e = pcall(function() return Enum[v[3]][v[2]] end)
				if good then CFG[k] = e end
			else
				CFG[k] = v
			end
		end
	end
end

-- ── gui scaffolding ─────────────────────────────────────────

local BG     = Color3.fromRGB(15, 16, 20)
local PANEL  = Color3.fromRGB(23, 24, 30)
local LINE   = Color3.fromRGB(38, 41, 51)
local TEXT   = Color3.fromRGB(233, 237, 245)
local DIM    = Color3.fromRGB(120, 127, 142)
local OFF    = Color3.fromRGB(46, 49, 60)
local RED    = Color3.fromRGB(255, 110, 110)

local function guiParent()
	if gethui then
		local good, h = pcall(gethui)
		if good and h then return h end
	end
	local good, cg = pcall(function() return game:GetService("CoreGui") end)
	if good and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

local parent = guiParent()
for _, n in ipairs({ "SleeperX", "SleeperX_ESP", "SleeperX_Chams" }) do
	local o = parent:FindFirstChild(n)
	if o then o:Destroy() end
end

local function new(class, props, par)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if par then o.Parent = par end
	return o
end

local function tween(obj, props, t)
	TweenService:Create(
		obj,
		TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
end

local function corner(par, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, par)
end

local sg = new("ScreenGui", {
	Name = "SleeperX", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
}, parent)

local espGui = new("ScreenGui", {
	Name = "SleeperX_ESP", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 90,
}, parent)

-- ── notifications ───────────────────────────────────────────

local notifyHolder = new("Frame", {
	Size = UDim2.new(0, 210, 1, -40),
	Position = UDim2.new(1, -220, 0, 20),
	BackgroundTransparency = 1,
}, sg)
new("UIListLayout", {
	Padding = UDim.new(0, 5),
	VerticalAlignment = Enum.VerticalAlignment.Top,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, notifyHolder)

local function notify(msg, col)
	local f = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = PANEL, BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, notifyHolder)
	corner(f, 6)
	new("UIStroke", { Color = col or ACCENT, Thickness = 1, Transparency = 0.5 }, f)
	new("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1, Text = msg,
		Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, f)
	tween(f, { BackgroundTransparency = 0.05 }, 0.12)
	task.delay(2.6, function()
		if not f.Parent then return end
		tween(f, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }, 0.2)
		task.wait(0.22)
		if f.Parent then f:Destroy() end
	end)
end

-- ── window ──────────────────────────────────────────────────

local WIN_W, WIN_H = 620, 440

local win = new("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
	BackgroundColor3 = BG, BorderSizePixel = 0, Active = true,
}, sg)
corner(win, 12)
new("UIStroke", { Color = LINE, Thickness = 1, Transparency = 0.1 }, win)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(PANEL, BG) }, win)

local bar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, win)
corner(bar, 12)

new("TextLabel", {
	Size = UDim2.new(0, 240, 0, 16), Position = UDim2.new(0, 14, 0, 5),
	BackgroundTransparency = 1, Text = "SLEEPER  X",
	Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

new("TextLabel", {
	Size = UDim2.new(0, 240, 0, 12), Position = UDim2.new(0, 14, 0, 22),
	BackgroundTransparency = 1, Text = "by Affy  •  Rivals",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = ACCENT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local function barBtn(x, glyph, col)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, x, 0.5, -10),
		BackgroundColor3 = OFF, Text = glyph,
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = col,
		AutoButtonColor = false, BorderSizePixel = 0,
	}, bar)
	corner(b, 6)
	return b
end

local minBtn   = barBtn(-52, "-", TEXT)
local closeBtn = barBtn(-28, "x", RED)

local rail = new("Frame", {
	Size = UDim2.new(0, 110, 1, -50),
	Position = UDim2.new(0, 10, 0, 46),
	BackgroundColor3 = PANEL, BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
}, win)
corner(rail, 10)
new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, rail)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, rail)

local pages, tabButtons = {}, {}

local function makeTab(id, label)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = OFF, BackgroundTransparency = 1,
		Text = label, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = DIM, AutoButtonColor = false, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, rail)
	corner(b, 6)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)

	local page = new("ScrollingFrame", {
		Position = UDim2.new(0, 128, 0, 46),
		Size = UDim2.new(1, -138, 1, -56),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = LINE,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, win)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, page)

	pages[id] = page
	tabButtons[id] = b

	conn(b.MouseButton1Click:Connect(function()
		for id2, p2 in pairs(pages) do
			p2.Visible = false
			tabButtons[id2].BackgroundTransparency = 1
			tabButtons[id2].TextColor3 = DIM
		end
		page.Visible = true
		b.BackgroundTransparency = 0.15
		b.BackgroundColor3 = ACCENT
		b.TextColor3 = BG
	end))

	return page
end

-- ── components ──────────────────────────────────────────────

local order = 0
local function nextOrder() order = order + 1; return order end
local renders = {}

local function section(page, text)
	local h = new("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1, LayoutOrder = nextOrder(),
	}, page)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left,
	}, h)
	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -4),
		BackgroundColor3 = LINE, BorderSizePixel = 0,
	}, h)
	return h
end

local function label(page, text, col)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = col or DIM, TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, page)
end

local function toggle(page, text, key, onChange)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1, LayoutOrder = nextOrder(),
	}, page)

	new("TextLabel", {
		Size = UDim2.new(1, -46, 1, 0), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local sw = new("TextButton", {
		Size = UDim2.fromOffset(34, 17),
		Position = UDim2.new(1, -34, 0.5, -8),
		BackgroundColor3 = OFF, Text = "", AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	corner(sw, 9)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(11, 11),
		Position = UDim2.new(0, 3, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
	}, sw)
	corner(knob, 6)

	local function render(anim)
		local on = CFG[key] and true or false
		local pos = on and UDim2.new(1, -14, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
		local col = on and ACCENT or OFF
		if anim then
			tween(sw, { BackgroundColor3 = col })
			tween(knob, { Position = pos })
		else
			sw.BackgroundColor3 = col
			knob.Position = pos
		end
	end

	conn(sw.MouseButton1Click:Connect(function()
		CFG[key] = not CFG[key]
		render(true)
		if onChange then pcall(onChange, CFG[key]) end
	end))

	render(false)
	renders[key] = render
	return row
end

local function slider(page, text, key, min, max, dec, onChange)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1, LayoutOrder = nextOrder(),
	}, page)

	new("TextLabel", {
		Size = UDim2.new(1, -56, 0, 14), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local val = new("TextLabel", {
		Size = UDim2.new(0, 56, 0, 14), Position = UDim2.new(1, -56, 0, 0),
		BackgroundTransparency = 1, Text = "",
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)

	local track = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = OFF, Text = "", AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	corner(track, 3)

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 3)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(11, 11), Position = UDim2.new(0, 0, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
	}, track)
	corner(knob, 6)

	local function fmt(v)
		if dec == 0 then return tostring(math.floor(v + 0.5)) end
		return string.format("%." .. dec .. "f", v)
	end

	local function apply(v, silent)
		v = clamp(v, min, max)
		CFG[key] = v
		local rel = (max > min) and ((v - min) / (max - min)) or 0
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, -5)
		val.Text = fmt(v)
		if onChange and not silent then pcall(onChange, v) end
	end

	local dragging = false
	local function fromX(px)
		local w = math.max(track.AbsoluteSize.X, 1)
		local rel = clamp((px - track.AbsolutePosition.X) / w, 0, 1)
		apply(min + (max - min) * rel)
	end

	conn(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
			conn(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end))
		end
	end))

	conn(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end))

	apply(CFG[key], true)
	renders[key] = function() apply(CFG[key], true) end
	return row
end

local function dropdown(page, text, key, options, onChange)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1, LayoutOrder = nextOrder(),
	}, page)

	new("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local b = new("TextButton", {
		Size = UDim2.fromOffset(100, 18), Position = UDim2.new(1, -100, 0.5, -9),
		BackgroundColor3 = OFF, Text = "", AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	corner(b, 6)
	local txt = new("TextLabel", {
		Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0),
		BackgroundTransparency = 1, Text = "",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, b)

	local idx = 1
	for i, o in ipairs(options) do
		if o == CFG[key] then idx = i break end
	end

	local function render()
		CFG[key] = options[idx]
		txt.Text = tostring(options[idx])
	end

	conn(b.MouseButton1Click:Connect(function()
		idx = idx % #options + 1
		render()
		if onChange then pcall(onChange, CFG[key]) end
	end))

	render()
	renders[key] = render
	return row
end

local function colorRow(page, text, key, onPick)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1, LayoutOrder = nextOrder(),
	}, page)

	new("TextLabel", {
		Size = UDim2.new(1, -46, 1, 0), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local b = new("TextButton", {
		Size = UDim2.fromOffset(34, 17), Position = UDim2.new(1, -34, 0.5, -8),
		BackgroundColor3 = CFG[key], Text = "", AutoButtonColor = false,
		BorderSizePixel = 0,
	}, row)
	corner(b, 9)
	new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.75 }, b)

	local i = 1
	for n, c in ipairs(ACCENTS) do
		if c == CFG[key] then i = n break end
	end

	conn(b.MouseButton1Click:Connect(function()
		i = i % #ACCENTS + 1
		CFG[key] = ACCENTS[i]
		b.BackgroundColor3 = CFG[key]
		if onPick then pcall(onPick, CFG[key]) end
	end))
end

local function button(page, text, fn, col)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = col or OFF, Text = text,
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TEXT,
		AutoButtonColor = false, BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
	}, page)
	corner(b, 6)
	conn(b.MouseButton1Click:Connect(function() pcall(fn) end))
	return b
end

-- ── binds ───────────────────────────────────────────────────

local BINDS = {
	Aimbot = { key = Enum.KeyCode.K, mode = "Toggle" },
}
local bindRenders = {}
local pickerOpen = nil

local function bindRow(page, text, feature)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1, LayoutOrder = nextOrder(),
	}, page)

	new("TextLabel", {
		Size = UDim2.new(1, -124, 1, 0), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local modeBtn = new("TextButton", {
		Size = UDim2.fromOffset(48, 18), Position = UDim2.new(1, -106, 0.5, -9),
		BackgroundColor3 = OFF, Text = "Toggle", AutoButtonColor = false,
		BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 9,
		TextColor3 = DIM,
	}, row)
	corner(modeBtn, 6)

	local keyBtn = new("TextButton", {
		Size = UDim2.fromOffset(50, 18), Position = UDim2.new(1, -52, 0.5, -9),
		BackgroundColor3 = OFF, Text = "", AutoButtonColor = false,
		BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 9,
		TextColor3 = ACCENT,
	}, row)
	corner(keyBtn, 6)

	local function render()
		local b = BINDS[feature]
		modeBtn.Text = b.mode
		keyBtn.Text = b.key and b.key.Name or "-"
		keyBtn.TextColor3 = ACCENT
	end

	conn(modeBtn.MouseButton1Click:Connect(function()
		local b = BINDS[feature]
		b.mode = (b.mode == "Toggle") and "Hold" or "Toggle"
		render()
	end))

	conn(keyBtn.MouseButton1Click:Connect(function()
		if pickerOpen then return end
		pickerOpen = feature
		keyBtn.Text = "press"
		keyBtn.TextColor3 = RED
	end))

	render()
	bindRenders[feature] = render
	return row
end

conn(UIS.InputBegan:Connect(function(input, gp)
	if pickerOpen then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			if input.KeyCode == Enum.KeyCode.Backspace then
				BINDS[pickerOpen].key = nil
			else
				BINDS[pickerOpen].key = input.KeyCode
			end
			local f = pickerOpen
			pickerOpen = nil
			if bindRenders[f] then bindRenders[f]() end
		end
		return
	end
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		sg.Enabled = not sg.Enabled
		espGui.Enabled = sg.Enabled
		return
	end
	for feature, b in pairs(BINDS) do
		if b.key and input.KeyCode == b.key then
			if b.mode == "Toggle" then
				CFG[feature] = not CFG[feature]
				if renders[feature] then renders[feature](true) end
				notify(feature .. (CFG[feature] and " ON" or " OFF"),
					CFG[feature] and ACCENT or DIM)
			end
			b.held = true
		end
	end
end))

conn(UIS.InputEnded:Connect(function(input)
	for _, b in pairs(BINDS) do
		if b.key and input.KeyCode == b.key then b.held = false end
	end
end))

local function bindActive(feature)
	local b = BINDS[feature]
	if not b then return false end
	if b.mode == "Hold" then return b.held == true end
	return CFG[feature] == true
end

-- ── combat core ─────────────────────────────────────────────

local firing, releaseAt, nextShot = false, 0, 0

local function sameTeam(plr)
	return LP.Team ~= nil and plr.Team ~= nil and LP.Team == plr.Team
end

local function isEnemy(plr)
	if plr == LP then return false end
	if CFG.TeamCheck and sameTeam(plr) then return false end
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return true
end

local function aimPartOf(char, partName)
	if not char then return nil end
	if partName == "Head" then
		return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	elseif partName == "Nearest" then
		local c = cam()
		if not c then return char:FindFirstChild("HumanoidRootPart") end
		local vp = c.ViewportSize
		local best, bestD
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				local sp = c:WorldToViewportPoint(d.Position)
				if sp.Z > 0 then
					local dd = (Vector2.new(sp.X, sp.Y)
						- Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude
					if not bestD or dd < bestD then bestD = dd; best = d end
				end
			end
		end
		return best or char:FindFirstChild("HumanoidRootPart")
	elseif partName == "Random" then
		local parts = {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				table.insert(parts, d)
			end
		end
		if #parts > 0 then return parts[math.random(1, #parts)] end
		return char:FindFirstChild("HumanoidRootPart")
	end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local RAY = RaycastParams.new()
RAY.FilterType = RFT_EXCLUDE
RAY.IgnoreWater = true

local function isVisible(part)
	if not CFG.WallCheck then return true end
	local c = cam()
	if not c then return false end
	local ignore = {}
	if LP.Character then ignore[1] = LP.Character end
	RAY.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(c.CFrame.Position,
		(part.Position - c.CFrame.Position) * 1.05, RAY)
	if not hit then return true end
	local char = part.Parent
	return char ~= nil and hit.Instance:IsDescendantOf(char)
end

local TARGET = { part = nil, dist = 0, plr = nil, pos = nil }

local function predict(part, amount, speed)
	if amount <= 0 then return part.Position end
	local c = cam()
	if not c then return part.Position end
	local vel = part.AssemblyLinearVelocity
	if not vel or vel.Magnitude < 1 then return part.Position end
	local dist = (part.Position - c.CFrame.Position).Magnitude
	return part.Position + vel * (dist / math.max(speed, 1)) * amount
end

local function resolveTarget(fov, ignoreWalls, predictAmt)
	TARGET.plr, TARGET.part, TARGET.pos, TARGET.dist = nil, nil, nil, 0
	local c = cam()
	if not c then return end
	local vp = c.ViewportSize
	local cx, cy = vp.X * 0.5, vp.Y * 0.5

	local best, bestScore, bestPart, bestPos

	for _, plr in ipairs(Players:GetPlayers()) do
		if isEnemy(plr) then
			local part = aimPartOf(plr.Character, CFG.AimPart)
			if part then
				local aimPos = predict(part, predictAmt or CFG.Prediction, CFG.BulletSpeed)
				local sp = c:WorldToViewportPoint(aimPos)
				if sp.Z > 0 then
					local d = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
					if d < fov and (ignoreWalls or isVisible(part)) then
						local score
						if CFG.Priority == "Health" then
							local hum = plr.Character:FindFirstChildOfClass("Humanoid")
							score = hum and hum.Health or 100
						elseif CFG.Priority == "Distance" then
							score = (aimPos - c.CFrame.Position).Magnitude
						else
							score = d
						end
						if not bestScore or score < bestScore then
							bestScore = score
							best = plr
							bestPart = part
							bestPos = aimPos
						end
					end
				end
			end
		end
	end

	if best then
		TARGET.plr, TARGET.part, TARGET.pos = best, bestPart, bestPos
		TARGET.dist = (bestPos - c.CFrame.Position).Magnitude
	end
end

local function easeVal(t, style)
	if style == "Linear" then return t end
	if style == "Sine" then return math.sin(t * math.pi / 2) end
	if style == "Expo" then return t == 0 and 0 or 2 ^ (10 * (t - 1)) end
	if style == "Back" then
		local s = 1.70158
		return t * t * ((s + 1) * t - s)
	end
	return t * t
end

local function aimAt(pos, smooth, style)
	local c = cam()
	if not c then return end
	local vp = c.ViewportSize
	local sp = c:WorldToViewportPoint(pos)
	if sp.Z <= 0 then return end
	local dx = sp.X - vp.X * 0.5
	local dy = sp.Y - vp.Y * 0.5
	local k = clamp(easeVal(smooth, style or CFG.Ease), 0.02, 1)
	if CFG.Humanize > 0 then
		dx = dx + (math.random() - 0.5) * CFG.Humanize
		dy = dy + (math.random() - 0.5) * CFG.Humanize
	end
	if mousemoverel then mousemoverel(dx * k, dy * k) end
end

local function fireOnce()
	if not mouse1press then return end
	mouse1press()
	firing = true
	releaseAt = os.clock() + 0.04
	if CFG.Hitmarker then hitmarker() end
end

local function fovRadius()
	if CFG.FullFOV then
		local c = cam()
		if not c then return 9999 end
		local vp = c.ViewportSize
		return math.sqrt((vp.X * 0.5) ^ 2 + (vp.Y * 0.5) ^ 2)
	end
	return CFG.FOV
end

-- ── combat page ─────────────────────────────────────────────

local pCombat = makeTab("combat", "COMBAT")

section(pCombat, "RAGEBOT")
toggle(pCombat, "Ragebot", "Rage", function(v)
	notify(v and "Ragebot engaged" or "Ragebot off", v and ACCENT or DIM)
end)
toggle(pCombat, "Shoot Through Walls", "RageThroughWalls")
slider(pCombat, "Rage FOV", "RageFOV", 20, 900, 0)
slider(pCombat, "Rage Prediction", "RagePredict", 0, 2, 2)
toggle(pCombat, "Rage Auto Fire", "RageAutoFire")
label(pCombat, "Ignores wall check, snaps instantly, fires alone.")

section(pCombat, "AIMBOT")
toggle(pCombat, "Aimbot", "Aimbot")
bindRow(pCombat, "Aimbot bind", "Aimbot")
dropdown(pCombat, "Trigger mode", "AimMode", { "Hold", "Toggle", "Always" })
toggle(pCombat, "Require Right Mouse", "RequireRMB")
toggle(pCombat, "Silent aim (mouse snap)", "SilentAim")
dropdown(pCombat, "Aim part", "AimPart", { "Head", "Root", "Nearest", "Random" })
dropdown(pCombat, "Priority", "Priority", { "Crosshair", "Health", "Distance" })
toggle(pCombat, "Sticky target", "Sticky")
toggle(pCombat, "Wall check", "WallCheck")
toggle(pCombat, "Full screen FOV", "FullFOV")
slider(pCombat, "FOV radius", "FOV", 40, 900, 0)
slider(pCombat, "Smoothness", "Smooth", 0.05, 1, 2)
dropdown(pCombat, "Easing", "Ease", { "Linear", "Quad", "Sine", "Expo", "Back" })
slider(pCombat, "Humanize", "Humanize", 0, 8, 1)
slider(pCombat, "Prediction", "Prediction", 0, 2, 2)
slider(pCombat, "Bullet speed", "BulletSpeed", 200, 2000, 0)
colorRow(pCombat, "FOV color", "FOVColor")
slider(pCombat, "FOV thickness", "FOVThick", 1, 4, 0)
slider(pCombat, "FOV transparency", "FOVTrans", 0, 0.9, 2)

section(pCombat, "TRIGGERBOT")
toggle(pCombat, "Triggerbot", "Trigger")
slider(pCombat, "Trigger FOV", "TrigFOV", 4, 60, 0)
slider(pCombat, "Pre-delay", "TrigDelay", 0, 0.4, 2)
slider(pCombat, "Jitter", "TrigJitter", 0, 0.15, 3)
slider(pCombat, "Fire rate", "TrigRate", 0.01, 0.4, 2)

-- ── esp ─────────────────────────────────────────────────────

local espData = {}
local chamsFolder = new("Folder", { Name = "SleeperX_Chams" }, parent)
local highlights = {}

local R15 = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
}
local R6 = {
	{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
	{"Torso","Left Leg"},{"Left Leg","Left Foot"},{"Torso","Right Leg"},{"Right Leg","Right Foot"},
}

local function ensureLines(e, n)
	if not HAS_DRAW then return end
	e.lines = e.lines or {}
	local have = #e.lines
	for i = have + 1, n do
		local l = Drawing.new("Line")
		l.Thickness = 1
		l.Visible = false
		e.lines[i] = l
	end
end

local function mkEsp()
	local e = {}
	e.box = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
	new("UIStroke", { Thickness = 1 }, e.box)
	e.hpBg = new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		BorderSizePixel = 0, Visible = false,
	}, espGui)
	e.hp = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(90, 255, 140), BorderSizePixel = 0, Visible = false,
	}, e.hpBg)
	e.name = new("TextLabel", {
		BackgroundTransparency = 1, Visible = false,
		Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4,
	}, espGui)
	e.dist = new("TextLabel", {
		BackgroundTransparency = 1, Visible = false,
		Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 205, 215),
		TextStrokeTransparency = 0.5,
	}, espGui)
	e.tracer = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Visible = false, AnchorPoint = Vector2.new(0, 0.5),
	}, espGui)
	e.dot = new("Frame", {
		Size = UDim2.fromOffset(5, 5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false,
	}, espGui)
	corner(e.dot, 3)
	e.arrow = new("TextLabel", {
		Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
		Text = "^", Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1), Visible = false,
	}, espGui)
	return e
end

local function freeEsp(e)
	for _, k in ipairs({ "box", "hpBg", "hp", "name", "dist", "tracer", "dot", "arrow" }) do
		if e[k] then pcall(function() e[k]:Destroy() end) end
	end
	if e.lines then
		for _, l in ipairs(e.lines) do pcall(function() l:Remove() end) end
	end
end

local function hideEsp(e)
	e.box.Visible = false
	e.hpBg.Visible = false
	e.hp.Visible = false
	e.name.Visible = false
	e.dist.Visible = false
	e.tracer.Visible = false
	e.dot.Visible = false
	e.arrow.Visible = false
	if e.lines then
		for _, l in ipairs(e.lines) do l.Visible = false end
	end
end

local ESP_TARGET

local function drawEsp(plr, e)
	local c = cam()
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not c or not char or not hum or hum.Health <= 0 or not hrp then
		hideEsp(e)
		return
	end

	local ally = CFG.TeamCheck and sameTeam(plr)
	local col = ally and CFG.AllyColor or CFG.EspColor
	if CFG.TargetHL and ESP_TARGET == plr then col = Color3.fromRGB(255, 90, 90) end

	local vp = c.ViewportSize
	local function proj(p)
		local sp = c:WorldToViewportPoint(p)
		if sp.Z <= 0 then return nil end
		return Vector2.new(sp.X, sp.Y)
	end

	local top, bottom, left, right
	if CFG.Box2D or CFG.Box3D then
		local head = char:FindFirstChild("Head") or hrp
		local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") or hrp
		local hp = proj(head.Position + Vector3.new(0, 0.6, 0))
		local fp = proj(foot.Position - Vector3.new(0, 0.5, 0))
		if hp and fp then
			local h = math.abs(fp.Y - hp.Y)
			local w = h * 0.55
			top, bottom = math.min(hp.Y, fp.Y), math.max(hp.Y, fp.Y)
			left, right = hp.X - w / 2, hp.X + w / 2
		end
	end

	if not top then
		hideEsp(e)
		if CFG.Offscreen then
			local sp = c:WorldToViewportPoint(hrp.Position)
			local dir = Vector2.new(sp.X, sp.Y) - Vector2.new(vp.X / 2, vp.Y / 2)
			if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
			dir = dir.Unit
			local r = math.min(vp.X, vp.Y) * 0.42
			local pos = Vector2.new(vp.X / 2, vp.Y / 2) + dir * r
			e.arrow.Visible = true
			e.arrow.Position = UDim2.fromOffset(pos.X - 9, pos.Y - 9)
			e.arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
			e.arrow.TextColor3 = col
		end
		return
	end

	local dist = (hrp.Position - c.CFrame.Position).Magnitude

	if CFG.Box2D then
		e.box.Visible = true
		e.box.Position = UDim2.fromOffset(left, top)
		e.box.Size = UDim2.fromOffset(right - left, bottom - top)
		local stroke = e.box:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = col
			stroke.Transparency = (CFG.TargetHL and ESP_TARGET == plr) and 0 or 0.25
		end
	end

	if CFG.Box3D and HAS_DRAW then
		ensureLines(e, 12)
		local cf = hrp.CFrame
		local corners = {}
		for _, o in ipairs({
			Vector3.new(1.2, 1.6, 1.2), Vector3.new(-1.2, 1.6, 1.2),
			Vector3.new(-1.2, 1.6, -1.2), Vector3.new(1.2, 1.6, -1.2),
			Vector3.new(1.2, -1.6, 1.2), Vector3.new(-1.2, -1.6, 1.2),
			Vector3.new(-1.2, -1.6, -1.2), Vector3.new(1.2, -1.6, -1.2),
		}) do
			table.insert(corners, proj((cf * CFrame.new(o)).Position))
		end
		local edges = {
			{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},
			{1,5},{2,6},{3,7},{4,8},
		}
		for i, ed in ipairs(edges) do
			local l = e.lines[i]
			if l then
				local a, b = corners[ed[1]], corners[ed[2]]
				if a and b then
					l.From, l.To, l.Color, l.Visible = a, b, col, true
				else
					l.Visible = false
				end
			end
		end
	end

	if CFG.Skeleton and HAS_DRAW then
		local base = (CFG.Box3D and 12) or 0
		local set = char:FindFirstChild("UpperTorso") and R15 or R6
		ensureLines(e, base + #set)
		for i, pair in ipairs(set) do
			local l = e.lines[base + i]
			if l then
				local a = char:FindFirstChild(pair[1])
				local b = char:FindFirstChild(pair[2])
				local pa = a and proj(a.Position)
				local pb = b and proj(b.Position)
				if pa and pb then
					l.From, l.To, l.Color, l.Visible = pa, pb, col, true
				else
					l.Visible = false
				end
			end
		end
	end

	if CFG.HealthBar then
		local pct = clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local bh = bottom - top
		e.hpBg.Visible = true
		e.hpBg.Position = UDim2.fromOffset(left - 6, top)
		e.hpBg.Size = UDim2.fromOffset(3, bh)
		e.hp.Visible = true
		e.hp.Position = UDim2.fromOffset(0, bh * (1 - pct))
		e.hp.Size = UDim2.new(1, 0, pct, 0)
		e.hp.BackgroundColor3 = Color3.fromRGB(
			math.floor(255 * (1 - pct)), math.floor(255 * pct), 60)
	end

	if CFG.NameTag then
		e.name.Visible = true
		e.name.Text = plr.Name
		e.name.TextSize = CFG.TagSize
		e.name.TextColor3 = col
		e.name.Position = UDim2.fromOffset(left + (right - left) / 2 - 60, top - 16)
		e.name.Size = UDim2.fromOffset(120, 14)
	end

	if CFG.DistanceTag then
		e.dist.Visible = true
		e.dist.Text = math.floor(dist) .. "m"
		e.dist.TextSize = math.max(CFG.TagSize - 2, 8)
		e.dist.Position = UDim2.fromOffset(left + (right - left) / 2 - 60, bottom + 2)
		e.dist.Size = UDim2.fromOffset(120, 12)
	end

	if CFG.HeadDot then
		local head = char:FindFirstChild("Head")
		local hp = head and proj(head.Position)
		if hp then
			e.dot.Visible = true
			e.dot.Position = UDim2.fromOffset(hp.X, hp.Y)
			e.dot.BackgroundColor3 = col
		end
	end

	if CFG.Tracer then
		local sp = proj(hrp.Position)
		if sp then
			local from = Vector2.new(vp.X / 2, vp.Y)
			local delta = sp - from
			e.tracer.Visible = true
			e.tracer.BackgroundColor3 = col
			e.tracer.BackgroundTransparency = 0.35
			e.tracer.Position = UDim2.fromOffset(from.X, from.Y)
			e.tracer.Size = UDim2.fromOffset(delta.Magnitude, 1)
			e.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
		end
	end
end

local function ensureChams(plr)
	local h = highlights[plr]
	if not h then
		h = Instance.new("Highlight")
		h.Name = "SleeperX_" .. plr.Name
		if Enum.HighlightDepthMode then
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		end
		h.Parent = chamsFolder
		highlights[plr] = h
	end
	return h
end

local function refreshEsp()
	if not CFG.ESP and not CFG.Chams then
		for _, e in pairs(espData) do hideEsp(e) end
		for _, h in pairs(highlights) do h.Enabled = false; h.Adornee = nil end
		return
	end

	for plr, e in pairs(espData) do
		if not plr.Parent then
			hideEsp(e)
			freeEsp(e)
			espData[plr] = nil
		end
	end
	for plr, h in pairs(highlights) do
		if not plr.Parent then
			h:Destroy()
			highlights[plr] = nil
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			if CFG.ESP then
				local e = espData[plr]
				if not e then
					e = mkEsp()
					espData[plr] = e
				end
				drawEsp(plr, e)
			else
				local e = espData[plr]
				if e then hideEsp(e) end
			end

			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if CFG.Chams and char and hum and hum.Health > 0 then
				local h = ensureChams(plr)
				local ally = CFG.TeamCheck and sameTeam(plr)
				h.Adornee = char
				h.FillColor = ally and CFG.AllyColor or CFG.EspColor
				h.FillTransparency = CFG.ChamsTrans
				h.OutlineTransparency = CFG.ChamsOutlineTrans
				h.Enabled = true
			else
				local h = highlights[plr]
				if h then h.Enabled = false; h.Adornee = nil end
			end
		end
	end
end

-- ── visuals page ────────────────────────────────────────────

local pVis = makeTab("visuals", "VISUALS")

section(pVis, "ESP")
toggle(pVis, "ESP enabled", "ESP")
toggle(pVis, "Team check", "TeamCheck")
toggle(pVis, "2D box", "Box2D")
toggle(pVis, "3D box", "Box3D")
toggle(pVis, "Skeleton", "Skeleton")
toggle(pVis, "Health bar", "HealthBar")
toggle(pVis, "Name", "NameTag")
toggle(pVis, "Distance", "DistanceTag")
toggle(pVis, "Tracer", "Tracer")
toggle(pVis, "Head dot", "HeadDot")
toggle(pVis, "Off-screen arrows", "Offscreen")
toggle(pVis, "Highlight target", "TargetHL")
slider(pVis, "Tag size", "TagSize", 9, 20, 0)
colorRow(pVis, "Enemy color", "EspColor")
colorRow(pVis, "Ally color", "AllyColor")
if not HAS_DRAW then label(pVis, "3D box + skeleton need Drawing support", RED) end

section(pVis, "CHAMS")
toggle(pVis, "Chams", "Chams")
slider(pVis, "Fill transparency", "ChamsTrans", 0, 0.95, 2)
slider(pVis, "Outline transparency", "ChamsOutlineTrans", 0, 1, 2)

section(pVis, "ENVIRONMENT")
toggle(pVis, "Fullbright", "Fullbright")
toggle(pVis, "Remove fog", "NoFog")
toggle(pVis, "Custom camera FOV", "CamFOVOn")
slider(pVis, "Camera FOV", "CamFOV", 50, 120, 0)

section(pVis, "CROSSHAIR")
toggle(pVis, "Custom crosshair", "Crosshair")
dropdown(pVis, "Style", "CrossStyle", { "Cross", "Dot", "T" })
slider(pVis, "Size", "CrossSize", 2, 30, 0)
slider(pVis, "Gap", "CrossGap", 0, 20, 0)
slider(pVis, "Thickness", "CrossThick", 1, 4, 0)
colorRow(pVis, "Color", "CrossColor")
toggle(pVis, "Hitmarker", "Hitmarker")

-- ── overlays ────────────────────────────────────────────────

local fovRing = new("Frame", {
	Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundTransparency = 1, Visible = false,
}, espGui)
corner(fovRing, 9999)
local fovStroke = new("UIStroke", { Thickness = 1, Transparency = 0.55, Color = ACCENT }, fovRing)

local crossHolder = new("Frame", {
	Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
}, espGui)
local crossParts = {}
for i = 1, 4 do
	crossParts[i] = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, crossHolder)
end
local crossDot = new("Frame", {
	Size = UDim2.fromOffset(2, 2), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
}, crossHolder)

local hitFrame = new("Frame", {
	Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
}, espGui)
local hitParts = {}
for i = 1, 4 do
	hitParts[i] = new("Frame", {
		Size = UDim2.fromOffset(9, 2), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, hitFrame)
end

local hitSound
if okSS then
	hitSound = new("Sound", { SoundId = "rbxassetid://3744369861", Volume = 0.3 }, SoundService)
end

function hitmarker()
	if hitSound then pcall(function() hitSound:Play() end) end
	for i, p in ipairs(hitParts) do
		p.BackgroundTransparency = 0
		p.Position = UDim2.new(0.5, 0, 0.5, 0)
		p.Rotation = (i - 1) * 90 + 45
		local dir = Vector2.new(math.cos(math.rad(p.Rotation)), math.sin(math.rad(p.Rotation)))
		tween(p, {
			Position = UDim2.new(0.5, dir.X * 14, 0.5, dir.Y * 14),
			BackgroundTransparency = 1,
		}, 0.22)
	end
end

local function renderCross()
	crossHolder.Visible = CFG.Crosshair
	if not CFG.Crosshair then return end
	local s, g, t, col = CFG.CrossSize, CFG.CrossGap, CFG.CrossThick, CFG.CrossColor
	crossDot.BackgroundColor3 = col
	crossDot.Visible = CFG.CrossStyle == "Dot"
	for i, p in ipairs(crossParts) do
		p.BackgroundColor3 = col
		p.BackgroundTransparency = 0
		p.Visible = (CFG.CrossStyle == "Cross") or (CFG.CrossStyle == "T" and i ~= 3)
	end
	crossParts[1].Size = UDim2.fromOffset(t, s)
	crossParts[1].Position = UDim2.new(0.5, 0, 0.5, -(g + s / 2))
	crossParts[2].Size = UDim2.fromOffset(t, s)
	crossParts[2].Position = UDim2.new(0.5, 0, 0.5, g + s / 2)
	crossParts[3].Size = UDim2.fromOffset(s, t)
	crossParts[3].Position = UDim2.new(0.5, -(g + s / 2), 0.5, 0)
	crossParts[4].Size = UDim2.fromOffset(s, t)
	crossParts[4].Position = UDim2.new(0.5, g + s / 2, 0.5, 0)
end

-- ── movement page ───────────────────────────────────────────

local pMove = makeTab("movement", "MOVEMENT")

section(pMove, "GROUND")
toggle(pMove, "Walk speed", "SpeedOn")
slider(pMove, "Speed value", "WalkSpeed", 16, 300, 0)
toggle(pMove, "Jump power", "JumpPowerOn")
slider(pMove, "Jump value", "JumpPower", 50, 300, 0)
toggle(pMove, "Infinite jump", "InfJump")
toggle(pMove, "Auto jump", "AutoJump")
toggle(pMove, "Anti AFK", "AntiAFK")

section(pMove, "AIR")
toggle(pMove, "Fly", "Fly")
slider(pMove, "Fly speed", "FlySpeed", 10, 300, 0)
toggle(pMove, "Noclip", "Noclip")
label(pMove, "Fly: WASD move, Space up, Ctrl down.", DIM)

local flyBV
local function stopFly()
	if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
end

local function startFly()
	local char = LP.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	stopFly()
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = hrp
end

-- ── misc page ───────────────────────────────────────────────

local pMisc = makeTab("misc", "MISC")

local watermark = new("Frame", {
	Size = UDim2.fromOffset(190, 34), Position = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = PANEL, BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false,
}, sg)
corner(watermark, 7)
new("UIStroke", { Color = LINE, Transparency = 0.4 }, watermark)
new("TextLabel", {
	Size = UDim2.new(1, -10, 0, 15), Position = UDim2.new(0, 7, 0, 3),
	BackgroundTransparency = 1, Text = "SLEEPER X  •  by Affy",
	Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = ACCENT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, watermark)
local wmStats = new("TextLabel", {
	Size = UDim2.new(1, -10, 0, 13), Position = UDim2.new(0, 7, 0, 17),
	BackgroundTransparency = 1, Text = "",
	Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = DIM,
	TextXAlignment = Enum.TextXAlignment.Left,
}, watermark)

section(pMisc, "INTERFACE")
toggle(pMisc, "Watermark", "Watermark")
toggle(pMisc, "Player list", "PlayerList")
toggle(pMisc, "Keybind list", "BindList")

section(pMisc, "PLAYERS")
local plrList = new("Frame", {
	Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
	LayoutOrder = nextOrder(), Visible = false,
}, pMisc)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, plrList)

local function rebuildPlayerList()
	for _, c in ipairs(plrList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local c = cam()
			local dist = (hrp and c) and math.floor((hrp.Position - c.CFrame.Position).Magnitude) or 0
			local ally = CFG.TeamCheck and sameTeam(plr)

			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = OFF, BackgroundTransparency = 0.5,
				Text = "  " .. plr.Name .. "   " .. dist .. "m",
				Font = Enum.Font.GothamMedium, TextSize = 10,
				TextColor3 = ally and CFG.AllyColor or TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false, BorderSizePixel = 0,
			}, plrList)
			corner(b, 4)

			conn(b.MouseButton1Click:Connect(function()
				if hrp and c then
					c.CFrame = CFrame.new(c.CFrame.Position, hrp.Position)
					notify("Spectating " .. plr.Name, ACCENT)
				end
			end))
		end
	end
end

section(pMisc, "SESSION")
button(pMisc, "Rejoin server", function()
	if okTP then Teleport:Teleport(game.PlaceId) end
end)
button(pMisc, "Copy join link", function()
	if setclipboard then
		setclipboard("https://www.roblox.com/games/" .. game.PlaceId)
		notify("Join link copied", ACCENT)
	end
end)

-- ── skins ───────────────────────────────────────────────────

local CosmeticLibrary, ItemLibrary, ReplicatedClass, ClientViewModel
local libReady = false
local catalog = { skins = {}, wraps = { "None" } }
local catalogReady = false
local skinHooked = false

local FALLBACK_SKINS = {
	["Assault Rifle"] = { "Default", "AK-47", "AUG", "Tommy Gun", "Phoenix Rifle" },
	["Sniper"] = { "Default", "Pixel Sniper", "Hyper Sniper", "Event Horizon" },
	["Shotgun"] = { "Default", "Hyper Shotgun", "Balloon Shotgun", "Broomstick" },
	["Revolver"] = { "Default", "Desert Eagle", "Sheriff", "Peppergun" },
	["Handgun"] = { "Default", "Blaster", "Gumball Handgun" },
	["Katana"] = { "Default", "Saber", "Stellar Katana", "Crystal Katana" },
	["Knife"] = { "Default", "Karambit", "Balisong", "Machete" },
	["Scythe"] = { "Default", "Scythe of Death", "Anchor", "Cryo Scythe" },
	["Uzi"] = { "Default", "Water Uzi", "Electro Uzi", "Money Gun" },
	["RPG"] = { "Default", "Nuke Launcher", "Squid Launcher" },
	["Minigun"] = { "Default", "Lasergun 3000", "Pixel Minigun" },
	["Fists"] = { "Default", "Boxing Gloves", "Brass Knuckles" },
}
local FALLBACK_WRAPS = { "None", "Gold", "Diamond", "Damascus", "Neon Lights", "Glass" }

local function tryRequire(path)
	if not path then return nil end
	identity(2)
	local good, mod = pcall(require, path)
	identity(7)
	if good then return mod end
	return nil
end

local function bootLibs()
	if not okRS then return end
	local modules = RS:FindFirstChild("Modules")
	if not modules then return end
	CosmeticLibrary = tryRequire(modules:FindFirstChild("CosmeticLibrary"))
	ItemLibrary = tryRequire(modules:FindFirstChild("ItemLibrary"))
	ReplicatedClass = tryRequire(modules:FindFirstChild("ReplicatedClass"))
	local ps = LP:FindFirstChild("PlayerScripts")
	local cif = ps and ps:FindFirstChild("Modules")
	cif = cif and cif:FindFirstChild("ClientReplicatedClasses")
	cif = cif and cif:FindFirstChild("ClientFighter")
	cif = cif and cif:FindFirstChild("ClientItem")
	ClientViewModel = cif and tryRequire(cif:FindFirstChild("ClientViewModel"))
	libReady = (CosmeticLibrary ~= nil) and (ClientViewModel ~= nil)
end

local function buildCatalog()
	if catalogReady then return end
	catalog.skins = {}
	catalog.wraps = { "None" }

	if CosmeticLibrary and CosmeticLibrary.Cosmetics then
		local n = 0
		for name, info in pairs(CosmeticLibrary.Cosmetics) do
			if type(info) == "table" then
				if info.Type == "Skin" and info.ItemName then
					catalog.skins[info.ItemName] = catalog.skins[info.ItemName] or { "Default" }
					table.insert(catalog.skins[info.ItemName], name)
				elseif info.Type == "Wrap" then
					table.insert(catalog.wraps, name)
				end
			end
			n = n + 1
			if n % 150 == 0 then task.wait() end
		end
	end

	for weapon, list in pairs(FALLBACK_SKINS) do
		if not catalog.skins[weapon] then
			catalog.skins[weapon] = deepCopy(list)
		else
			local seen = {}
			for _, n in ipairs(catalog.skins[weapon]) do seen[n] = true end
			for _, n in ipairs(list) do
				if not seen[n] then table.insert(catalog.skins[weapon], n) end
			end
		end
	end

	catalogReady = true
end

local function cosmeticData(name, ctype)
	if not CosmeticLibrary or not CosmeticLibrary.Cosmetics then return nil end
	local base = CosmeticLibrary.Cosmetics[name]
	if not base then return nil end
	local d = {}
	for k, v in pairs(base) do d[k] = v end
	d.Name = name
	d.Type = ctype
	return d
end

local function installSkinHooks()
	if skinHooked or not libReady then return end
	skinHooked = true

	local oldNew = ClientViewModel.new
	ClientViewModel.new = function(replicatedData, clientItem)
		pcall(function()
			if not CFG.SkinsOn or not clientItem or not clientItem.Name then return end
			local skin = CFG.Skins[clientItem.Name]
			if not skin or skin == "Default" or skin == "None" then return end
			local cf = rawget(clientItem, "ClientFighter") or clientItem.ClientFighter
			if not cf or cf.Player ~= LP then return end
			local data = cosmeticData(skin, "Skin")
			if not data or not ReplicatedClass then return end
			local dk = ReplicatedClass:ToEnum("Data")
			local sk = ReplicatedClass:ToEnum("Skin")
			local nk = ReplicatedClass:ToEnum("Name")
			replicatedData[dk] = replicatedData[dk] or {}
			replicatedData[dk][sk] = data
			replicatedData[dk][nk] = skin
		end)
		local vm = oldNew(replicatedData, clientItem)
		task.delay(0.1, function()
			pcall(function()
				if vm and vm._UpdateWrap then vm:_UpdateWrap() end
			end)
		end)
		return vm
	end

	if ClientViewModel.GetWrap then
		local oldWrap = ClientViewModel.GetWrap
		ClientViewModel.GetWrap = function(self)
			local good, res = pcall(function()
				local wn = self.ClientItem and self.ClientItem.Name
				local w = wn and CFG.Wraps[wn]
				if CFG.SkinsOn and w and w ~= "None" then
					return cosmeticData(w, "Wrap")
				end
			end)
			if good and res then return res end
			return oldWrap(self)
		end
	end
end

local function applyAllSkins()
	if not libReady or not CosmeticLibrary.Equip then return end
	for weapon, skin in pairs(CFG.Skins) do
		if skin and skin ~= "Default" then
			pcall(function() CosmeticLibrary.Equip(weapon, "Skin", skin) end)
		end
	end
end

local skinWeapon
local skinPage = makeTab("skins", "SKINS")

section(skinPage, "SKIN CHANGER")
toggle(skinPage, "Enabled", "SkinsOn", function(v)
	if not v then return end
	bootLibs()
	buildCatalog()
	if libReady then installSkinHooks() end
	applyAllSkins()
end)

local libStatus = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
	Text = "off — enable to load", Font = Enum.Font.GothamBold, TextSize = 10,
	TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, skinPage)

button(skinPage, "Load / rescan libraries", function()
	bootLibs()
	buildCatalog()
	libStatus.Text = libReady and ("ready • " .. tostring(#catalog.wraps) .. " wraps")
		or "unavailable — fallback list"
	libStatus.TextColor3 = libReady and ACCENT or RED
	if libReady then installSkinHooks() end
end)

local function chipRow(text, onPick)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, skinPage)
	new("TextLabel", {
		Size = UDim2.new(0, 62, 1, 0), BackgroundTransparency = 1,
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local scroll = new("ScrollingFrame", {
		Size = UDim2.new(1, -66, 1, 0), Position = UDim2.new(0, 66, 0, 0),
		BackgroundColor3 = OFF, BackgroundTransparency = 0.4,
		BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = LINE, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
	}, row)
	corner(scroll, 5)
	new("UIListLayout", {
		Padding = UDim.new(0, 3), FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
	}, scroll)
	new("UIPadding", { PaddingLeft = UDim.new(0, 4) }, scroll)

	local btns = {}
	local function setOptions(list)
		for _, b in pairs(btns) do b:Destroy() end
		btns = {}
		for _, opt in ipairs(list) do
			local b = new("TextButton", {
				Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = PANEL, Text = "  " .. opt .. "  ",
				Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = TEXT,
				AutoButtonColor = false, BorderSizePixel = 0,
			}, scroll)
			corner(b, 4)
			table.insert(btns, b)
			conn(b.MouseButton1Click:Connect(function()
				for _, b2 in pairs(btns) do
					b2.BackgroundColor3 = PANEL
					b2.TextColor3 = TEXT
				end
				b.BackgroundColor3 = ACCENT
				b.TextColor3 = BG
				pcall(onPick, opt)
			end))
		end
	end
	return setOptions
end

local weaponOptions = {}
for w in pairs(FALLBACK_SKINS) do table.insert(weaponOptions, w) end
table.sort(weaponOptions)

local setSkinOptions
local setWeaponOptions = chipRow("Weapon", function(w)
	skinWeapon = w
	buildCatalog()
	setSkinOptions(catalog.skins[w] or { "Default" })
end)
local setWrapOptions = chipRow("Wrap", function(w)
	if not skinWeapon then return end
	CFG.Wraps[skinWeapon] = w
	notify("Wrap: " .. w, ACCENT)
end)
setSkinOptions = chipRow("Skin", function(s)
	if not skinWeapon then return end
	CFG.Skins[skinWeapon] = s
	notify(skinWeapon .. " -> " .. s, ACCENT)
	if libReady and CosmeticLibrary.Equip then
		pcall(function() CosmeticLibrary.Equip(skinWeapon, "Skin", s) end)
	end
end)

button(skinPage, "Apply all saved skins", function()
	if not libReady then bootLibs(); buildCatalog() end
	if libReady then installSkinHooks() end
	applyAllSkins()
	notify("Skins applied", ACCENT)
end)
button(skinPage, "Clear skin config", function()
	CFG.Skins = {}
	CFG.Wraps = {}
	notify("Cleared", DIM)
end)

-- ── config page ─────────────────────────────────────────────

local pCfg = makeTab("config", "CONFIG")

section(pCfg, "PROFILE")
label(pCfg, hasFS and ("File: " .. CONFIG_FILE) or "No filesystem — memory only", DIM)

button(pCfg, "Save config", function()
	if not hasFS then notify("writefile unavailable", RED) return end
	local good = pcall(writefile, CONFIG_FILE, encodeCFG())
	notify(good and "Config saved" or "Save failed", good and ACCENT or RED)
end)

button(pCfg, "Load config", function()
	if not hasFS then notify("readfile unavailable", RED) return end
	if not isfile(CONFIG_FILE) then notify("No saved config", RED) return end
	local good = pcall(function() decodeInto(readfile(CONFIG_FILE)) end)
	if good then
		ACCENT = ACCENTS[CFG.Accent] or ACCENTS[1]
		for _, r in pairs(renders) do pcall(r, true) end
		if CFG.SkinsOn then
			bootLibs(); buildCatalog()
			if libReady then installSkinHooks() end
			applyAllSkins()
		end
		notify("Config loaded", ACCENT)
	else
		notify("Load failed", RED)
	end
end)

button(pCfg, "Export to clipboard", function()
	if not setclipboard then notify("setclipboard unavailable", RED) return end
	setclipboard(encodeCFG())
	notify("Copied", ACCENT)
end)

button(pCfg, "Import from clipboard", function()
	if not getclipboard then notify("getclipboard unavailable", RED) return end
	local good = pcall(function() decodeInto(getclipboard()) end)
	if good then
		for _, r in pairs(renders) do pcall(r, true) end
		notify("Imported", ACCENT)
	else
		notify("Invalid config", RED)
	end
end)

button(pCfg, "Reset to defaults", function()
	local d = deepCopy(DEFAULTS)
	for k in pairs(CFG) do
		if d[k] == nil then CFG[k] = nil end
	end
	for k, v in pairs(d) do CFG[k] = v end
	for _, r in pairs(renders) do pcall(r, true) end
	notify("Defaults restored", DIM)
end, Color3.fromRGB(70, 40, 46))

section(pCfg, "THEME")
colorRow(pCfg, "Accent", "Accent", function(c) ACCENT = c end)
slider(pCfg, "Window transparency", "Opacity", 0, 0.7, 2, function(v)
	win.BackgroundTransparency = v
	bar.BackgroundTransparency = v
end)

section(pCfg, "KEYS")
label(pCfg, "RightShift — menu", DIM)
label(pCfg, "K — aimbot", DIM)

button(pCfg, "Unload script", function()
	if getgenv().SleeperX then getgenv().SleeperX.Unload() end
end, Color3.fromRGB(70, 40, 46))

-- ── runtime ─────────────────────────────────────────────────

local origBrightness = Lighting.Brightness
local origFogEnd = Lighting.FogEnd
local origFOV = 70

local lastFrame = os.clock()
local fps, ping = 60, 0
local statAcc = 0
local noclipAcc = 0
local espAcc = 0
local listAcc = 0
local espScanAcc = 0
local lastBright, lastFog, lastFOV
local running = true

local renderConn = RunService.RenderStepped:Connect(function()
	if not running then return end

	pcall(function()
		local now = os.clock()
		local dt = now - lastFrame
		lastFrame = now
		if dt > 0 and dt < 1 then fps = fps + ((1 / dt) - fps) * 0.08 end

		local c = cam()
		if c then
			local wantFOV = CFG.CamFOVOn and CFG.CamFOV or origFOV
			if wantFOV ~= lastFOV then
				c.FieldOfView = wantFOV
				lastFOV = wantFOV
			end
		end

		local wantBright = CFG.Fullbright and 3 or origBrightness
		if wantBright ~= lastBright then
			Lighting.Brightness = wantBright
			lastBright = wantBright
		end
		local wantFog = CFG.NoFog and 1e6 or origFogEnd
		if wantFog ~= lastFog then
			Lighting.FogEnd = wantFog
			lastFog = wantFog
		end

		local rageOn = CFG.Rage
		local aimOn = bindActive("Aimbot") or CFG.AimMode == "Always"
		local trigOn = CFG.Trigger

		if rageOn or aimOn then
			local radius = (rageOn and CFG.RageFOV or CFG.FOV) * 2
			fovRing.Size = UDim2.fromOffset(radius, radius)
			fovRing.Visible = true
			fovStroke.Color = rageOn and Color3.fromRGB(255, 90, 90) or CFG.FOVColor
			fovStroke.Thickness = CFG.FOVThick
			fovStroke.Transparency = CFG.FOVTrans
		elseif fovRing.Visible then
			fovRing.Visible = false
		end

		renderCross()

		if CFG.Watermark ~= watermark.Visible then watermark.Visible = CFG.Watermark end
		if CFG.Watermark then
			statAcc = statAcc + dt
			if statAcc >= 1 then
				statAcc = 0
				if okStats then
					pcall(function()
						ping = math.floor(
							Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
					end)
				end
				wmStats.Text = string.format("%d fps  •  %d ms  •  %d p",
					math.floor(fps), ping, #Players:GetPlayers())
			end
		end

		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if hum then
			local wantSpeed = CFG.SpeedOn and CFG.WalkSpeed or 16
			if math.abs(hum.WalkSpeed - wantSpeed) > 0.05 then hum.WalkSpeed = wantSpeed end
			if CFG.JumpPowerOn and math.abs(hum.JumpPower - CFG.JumpPower) > 0.05 then
				hum.JumpPower = CFG.JumpPower
			end
			if CFG.AutoJump and hum.FloorMaterial ~= Enum.Material.Air then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end

		if CFG.Noclip and char then
			noclipAcc = noclipAcc + dt
			if noclipAcc >= 0.25 then
				noclipAcc = 0
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
				end
			end
		end

		if CFG.Fly and hrp then
			if not flyBV then startFly() end
			if flyBV and c then
				local dir = Vector3.zero
				if UIS:IsKeyDown(Enum.KeyCode.W) then dir += c.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= c.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= c.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then dir += c.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
				if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
				flyBV.Velocity = dir.Magnitude > 0 and (dir.Unit * CFG.FlySpeed) or Vector3.zero
			end
		elseif flyBV and not CFG.Fly then
			stopFly()
		end

		if not char or not c then return end

		local holdOK = (not CFG.RequireRMB)
			or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

		if rageOn then
			resolveTarget(CFG.RageFOV, CFG.RageThroughWalls, CFG.RagePredict)
		elseif (aimOn and holdOK) or trigOn then
			local fov = 0
			if aimOn and holdOK then fov = fovRadius() end
			if trigOn and CFG.TrigFOV > fov then fov = CFG.TrigFOV end
			resolveTarget(fov, false, CFG.Prediction)
		end

		if rageOn and TARGET.part then
			aimAt(TARGET.pos, 1, "Linear")
			if CFG.RageAutoFire and not firing and now >= nextShot then
				fireOnce()
				nextShot = now + CFG.TrigRate
			end
		elseif aimOn and holdOK and TARGET.part then
			aimAt(TARGET.pos, CFG.SilentAim and 1 or CFG.Smooth, CFG.Ease)
		end

		if trigOn and TARGET.part and TARGET.dist <= CFG.TrigFOV
		and not firing and now >= nextShot then
			local delay = CFG.TrigDelay + (math.random() * CFG.TrigJitter)
			nextShot = now + CFG.TrigRate + delay
			task.delay(delay, function()
				if running and not firing then fireOnce() end
			end)
		end

		if firing and now >= releaseAt then
			if mouse1release then mouse1release() end
			firing = false
		end
	end)
end)
conn(renderConn)

conn(RunService.Heartbeat:Connect(function(dt)
	if not running then return end

	espAcc = espAcc + dt
	local interval = 0.1 + math.min(#Players:GetPlayers() * 0.004, 0.1)
	if espAcc >= interval then
		espAcc = 0
		pcall(refreshEsp)
	end

	if CFG.ESP and CFG.TargetHL and not CFG.Rage and not bindActive("Aimbot") then
		espScanAcc = espScanAcc + dt
		if espScanAcc >= 0.2 then
			espScanAcc = 0
			pcall(function()
				resolveTarget(900, true, 0)
				ESP_TARGET = TARGET.plr
			end)
		end
	end

	if CFG.PlayerList then
		listAcc = listAcc + dt
		if listAcc >= 0.5 then
			listAcc = 0
			plrList.Visible = true
			pcall(rebuildPlayerList)
		end
	elseif plrList.Visible then
		plrList.Visible = false
	end
end))

conn(UIS.JumpRequest:Connect(function()
	if not CFG.InfJump then return end
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

conn(LP.Idled:Connect(function()
	if not CFG.AntiAFK then return end
	if typeof(VirtualUser) == "table" and VirtualUser.ClickButton2 then
		pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
	end
end))

local function watchPlayer(plr)
	conn(plr.CharacterAdded:Connect(function()
		task.wait(0.4)
		pcall(refreshEsp)
	end))
end

for _, plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
conn(Players.PlayerAdded:Connect(watchPlayer))
conn(Players.PlayerRemoving:Connect(function(plr)
	local e = espData[plr]
	if e then
		hideEsp(e)
		freeEsp(e)
		espData[plr] = nil
	end
	local h = highlights[plr]
	if h then h:Destroy(); highlights[plr] = nil end
end))

conn(LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	stopFly()
	pcall(refreshEsp)
end))

local dragging, dragStart, startPos
conn(bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = win.Position
		conn(input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end))
	end
end))

conn(UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		win.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end))

local minimized = false
conn(minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	rail.Visible = not minimized
	for _, p in pairs(pages) do p.Visible = false end
	if not minimized and pages.combat then pages.combat.Visible = true end
	tween(win, {
		Size = minimized and UDim2.fromOffset(WIN_W, 40) or UDim2.fromOffset(WIN_W, WIN_H),
	})
end))

conn(closeBtn.MouseButton1Click:Connect(function()
	sg.Enabled = false
	espGui.Enabled = false
end))

local function unload()
	running = false
	for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
	CONNS = {}
	stopFly()
	for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
	for _, e in pairs(espData) do freeEsp(e) end
	espData = {}
	Lighting.Brightness = origBrightness
	Lighting.FogEnd = origFogEnd
	local c = cam()
	if c then pcall(function() c.FieldOfView = origFOV end) end
	pcall(function() sg:Destroy() end)
	pcall(function() espGui:Destroy() end)
	pcall(function() chamsFolder:Destroy() end)
	if hitSound then pcall(function() hitSound:Destroy() end) end
	getgenv().SleeperX = nil
end

getgenv().SleeperX = { Unload = unload, CFG = CFG }

-- ── boot ────────────────────────────────────────────────────

pages.combat.Visible = true
tabButtons.combat.BackgroundTransparency = 0.15
tabButtons.combat.BackgroundColor3 = ACCENT
tabButtons.combat.TextColor3 = BG

buildCatalog()
setWeaponOptions(weaponOptions)
setSkinOptions(catalog.skins["Assault Rifle"] or { "Default" })
setWrapOptions(FALLBACK_WRAPS)

task.spawn(function()
	if not hasFS then return end
	task.wait(0.4)
	if isfile(CONFIG_FILE) then
		local good = pcall(function() decodeInto(readfile(CONFIG_FILE)) end)
		if good then
			ACCENT = ACCENTS[CFG.Accent] or ACCENTS[1]
			for _, r in pairs(renders) do pcall(r, true) end
			if CFG.SkinsOn then
				bootLibs()
				buildCatalog()
				if libReady then installSkinHooks() end
				applyAllSkins()
				libStatus.Text = libReady and "ready" or "unavailable"
				libStatus.TextColor3 = libReady and ACCENT or RED
			end
		end
	end
end)

print("[Sleeper X by Affy] Loaded. RightShift = menu | K = aim")
notify("Sleeper X loaded", ACCENT)
