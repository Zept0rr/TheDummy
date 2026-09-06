--!strict
-- +Bonk popups at the pen. Display only — never grants currency.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Format = require(script.Parent.Format)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
type ClientState = State.ClientState
local Decimal = Formulas.Decimal

local POOL_SIZE = 10
local MAX_PER_SEC = 6
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

local function penPart(): BasePart?
	local yard = Workspace:FindFirstChild("Backyard")
	if yard == nil then
		return nil
	end
	local pen = yard:FindFirstChild("Pen")
	if pen and pen:IsA("BasePart") then
		return pen
	end
	local dummies = yard:FindFirstChild("PenDummies")
	if dummies ~= nil then
		local body = dummies:FindFirstChildWhichIsA("BasePart", true)
		if body then
			return body
		end
	end
	return nil
end

function WorldFx.mount(_gui: ScreenGui)
	local pool: { BillboardGui } = {}

	local function acquire(): BillboardGui?
		for _, gui in pool do
			if not gui.Enabled then
				return gui
			end
		end
		return nil
	end

	local function spawnPopup(amount: Decimal)
		local adornee = penPart()
		if adornee == nil then
			return
		end
		local gui = acquire()
		if gui == nil then
			if #pool >= POOL_SIZE then
				return
			end
			gui = Instance.new("BillboardGui")
			gui.Name = "BonkPopup"
			gui.Size = UDim2.fromOffset(110, 36)
			gui.AlwaysOnTop = false
			gui.MaxDistance = 90
			gui.ResetOnSpawn = false
			gui.LightInfluence = 0
			local label = Instance.new("TextLabel")
			label.Name = "Text"
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Theme.font.display
			label.TextSize = 26
			label.TextColor3 = Theme.colors.hit
			label.TextStrokeColor3 = Theme.colors.bg
			label.TextStrokeTransparency = 0.45
			label.Parent = gui
			table.insert(pool, gui)
		end

		local label = gui:FindFirstChild("Text")
		if label and label:IsA("TextLabel") then
			label.Text = Format.plus(amount)
			label.TextTransparency = 0
			label.TextStrokeTransparency = 0.45
		end

		gui.Adornee = adornee
		gui.Parent = adornee
		gui.StudsOffset = Vector3.new((math.random() - 0.5) * 14, 3 + math.random() * 2, (math.random() - 0.5) * 14)
		gui.Enabled = true

		local start = gui.StudsOffset
		local tween = TweenService:Create(gui, RISE, {
			StudsOffset = start + Vector3.new(0, 3.2, 0),
		})
		tween:Play()
		if label and label:IsA("TextLabel") then
			TweenService:Create(label, RISE, {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end
		tween.Completed:Once(function()
			gui.Enabled = false
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
