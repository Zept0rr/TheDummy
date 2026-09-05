--!strict
-- Wave 1 HUD: Bonk, Bonk/sec, dummy count. Display only.

local Format = require(script.Parent.Format)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Hud = {}

local function makeLabel(parent: Instance, name: string, size: UDim2, position: UDim2, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Theme.font.display
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = ""
	label.Parent = parent
	return label
end

function Hud.mount(gui: ScreenGui)
	local bar = Instance.new("Frame")
	bar.Name = "Hud"
	bar.AnchorPoint = Vector2.new(0, 0)
	bar.Position = UDim2.fromOffset(16, 16)
	bar.Size = UDim2.fromOffset(420, 92)
	bar.BackgroundColor3 = Theme.colors.panel
	bar.BackgroundTransparency = 0.08
	bar.BorderSizePixel = 0
	bar.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bar

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.colors.stroke
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = bar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = bar

	local caption = makeLabel(bar, "Caption", UDim2.new(0.55, 0, 0, 16), UDim2.fromOffset(0, 0), 14, Theme.colors.muted)
	caption.Font = Theme.font.body
	caption.Text = "BONK"

	local dummyCount = makeLabel(bar, "DummyCount", UDim2.new(0.45, 0, 0, 16), UDim2.new(0.55, 0, 0, 0), 14, Theme.colors.muted)
	dummyCount.Font = Theme.font.body
	dummyCount.TextXAlignment = Enum.TextXAlignment.Right
	dummyCount.Text = "Dummies  0"

	local bonk = makeLabel(bar, "Bonk", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 16), 32, Theme.colors.bonk)
	bonk.Text = "0"

	local rate = makeLabel(bar, "Rate", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 52), 18, Theme.colors.text)
	rate.Font = Theme.font.body
	rate.Text = "0/sec"

	State.subscribe(function(state)
		bonk.Text = Format.bonk(state.bonk)
		rate.Text = Format.rate(state.bonkPerSec)
		dummyCount.Text = "Dummies  " .. tostring(State.dummyTotal(state))
	end)
end

return Hud
