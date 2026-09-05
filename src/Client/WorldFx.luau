--!strict
-- +Bonk popups on hit. Display only — never grants currency.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Format = require(script.Parent.Format)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
type ClientState = State.ClientState
local Decimal = Formulas.Decimal

local POOL_SIZE = 12
local MAX_PER_SEC = 8
local RISE = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local WorldFx = {}

local function perHit(id: string, state: ClientState): Decimal?
	local count = math.max(0, math.floor(state.dummies[id] or 0))
	if count <= 0 then
		return nil
	end
	local def = Formulas.dummyDef(id)
	if def == nil then
		return nil
	end
	local hits = Formulas.hitsPerSecond(count, def.hitInterval)
	if hits <= 0 then
		return nil
	end
	local venueMult = Formulas.venueMult(state.venueId)
	local rate = Formulas.dummyBonkPerSec(id, count, state.dummyUpgrades, state.gymLevel, venueMult)
	if Decimal.isZero(rate) then
		return nil
	end
	return Decimal.div(rate, hits)
end

function WorldFx.mount(gui: ScreenGui)
	local layer = Instance.new("Frame")
	layer.Name = "HitPopups"
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.Size = UDim2.fromScale(1, 1)
	layer.ZIndex = 20
	layer.Parent = gui

	local pool: { TextLabel } = {}
	for i = 1, POOL_SIZE do
		local label = Instance.new("TextLabel")
		label.Name = "Popup" .. tostring(i)
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromOffset(160, 28)
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Font = Theme.font.display
		label.TextSize = 22
		label.TextColor3 = Theme.colors.hit
		label.TextStrokeColor3 = Theme.colors.bg
		label.TextStrokeTransparency = 0.4
		label.Visible = false
		label.ZIndex = 21
		label.Parent = layer
		table.insert(pool, label)
	end

	local function acquire(): TextLabel?
		for _, label in pool do
			if not label.Visible then
				return label
			end
		end
		return nil
	end

	local function spawnPopup(amount: Decimal)
		local label = acquire()
		if label == nil then
			return
		end
		label.Text = Format.plus(amount)
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.4
		label.Visible = true
		label.Position = UDim2.new(0.38, math.random(-48, 48), 0.48, math.random(-28, 28))

		local tween = TweenService:Create(label, RISE, {
			Position = label.Position + UDim2.fromOffset(0, -72),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			label.Visible = false
		end)
	end

	local clocks: { [string]: number } = {}
	local spawnedThisSecond = 0
	local secondAccum = 0.0

	RunService.Heartbeat:Connect(function(dt: number)
		secondAccum += dt
		if secondAccum >= 1 then
			secondAccum -= 1
			spawnedThisSecond = 0
		end
		if spawnedThisSecond >= MAX_PER_SEC then
			return
		end

		local state = State.get()
		Formulas.eachDummyDef(function(id, _raw)
			if spawnedThisSecond >= MAX_PER_SEC then
				return
			end
			local count = math.max(0, math.floor(state.dummies[id] or 0))
			if count <= 0 then
				clocks[id] = 0
				return
			end
			local def = Formulas.dummyDef(id)
			if def == nil then
				return
			end
			local period = math.max(def.hitInterval / count, 1 / MAX_PER_SEC)
			clocks[id] = (clocks[id] or 0) + dt
			while clocks[id] >= period and spawnedThisSecond < MAX_PER_SEC do
				clocks[id] -= period
				local amount = perHit(id, state)
				if amount ~= nil then
					spawnPopup(amount)
					spawnedThisSecond += 1
				end
			end
		end)
	end)
end

return WorldFx
