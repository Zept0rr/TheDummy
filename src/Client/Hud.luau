--!strict
-- Compact world HUD. Display only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(script.Parent.Format)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Hud = {}

local function copyText(key: string, fallback: string): string
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local module = if shared then shared:FindFirstChild("Config") else nil
	if module == nil then
		return fallback
	end
	local ok, cfg = pcall(require, module)
	if not ok or typeof(cfg) ~= "table" or typeof(cfg.copy) ~= "table" then
		return fallback
	end
	local value = cfg.copy[key]
	if typeof(value) == "string" and value ~= "" then
		return value
	end
	return fallback
end

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
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = ""
	label.Parent = parent
	return label
end

function Hud.mount(gui: ScreenGui)
	local bar = Instance.new("Frame")
	bar.Name = "Hud"
	bar.AnchorPoint = Vector2.new(0, 0)
	bar.Position = UDim2.fromOffset(12, 10)
	bar.Size = UDim2.fromOffset(196, 54)
	bar.BackgroundColor3 = Theme.colors.bg
	bar.BackgroundTransparency = 0.55
	bar.BorderSizePixel = 0
	bar.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = bar

	local caption = makeLabel(bar, "Caption", UDim2.new(0.58, 0, 0, 13), UDim2.fromOffset(0, 0), 12, Theme.colors.muted)
	caption.Font = Theme.font.body
	caption.Text = copyText("bonk", "Bonk")

	local dummyCount = makeLabel(bar, "DummyCount", UDim2.new(0.42, 0, 0, 13), UDim2.new(0.58, 0, 0, 0), 12, Theme.colors.muted)
	dummyCount.Font = Theme.font.body
	dummyCount.TextXAlignment = Enum.TextXAlignment.Right
	dummyCount.Text = "0"

	local bonk = makeLabel(bar, "Bonk", UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 12), 20, Theme.colors.bonk)
	bonk.Text = "0"

	local rate = makeLabel(bar, "Rate", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 32), 12, Theme.colors.muted)
	rate.Font = Theme.font.body
	rate.Text = Format.rate(0)

	State.subscribe(function(state)
		local bonkName = copyText("bonk", "Bonk")
		local persistOff = copyText("persistOff", "")
		if state.persistOk then
			caption.Text = bonkName
			caption.TextColor3 = Theme.colors.muted
		elseif persistOff ~= "" then
			caption.Text = bonkName .. "  ·  " .. persistOff
			caption.TextColor3 = Theme.colors.cost
		else
			caption.Text = bonkName
			caption.TextColor3 = Theme.colors.cost
		end
		bonk.Text = Format.bonk(state.bonk)
		rate.Text = Format.rate(state.bonkPerSec)
		local tab = copyText("tabDummies", "")
		local total = tostring(State.dummyTotal(state))
		dummyCount.Text = if tab ~= "" then tab .. "  " .. total else total
	end)
end

return Hud
