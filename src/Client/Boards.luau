--!strict
-- 3D dummy/gym boards. SurfaceGui + ProximityPrompt. Fire remotes only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Format = require(script.Parent.Format)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
type ClientState = State.ClientState
local Decimal = Formulas.Decimal

export type Remotes = {
	buyDummy: RemoteEvent,
	buyUpgrade: RemoteEvent,
	buyGym: RemoteEvent,
}

type BuyKind = "ready" | "poor" | "max" | "locked"

type DummyBinding = {
	refresh: (ClientState) -> (),
}

type StallSpec = {
	path: { string },
	position: Vector3,
	size: Vector3,
	color: Color3,
	face: Enum.NormalId,
}

local DUMMY_IDS = { "yellow", "fat", "gold", "crowd" }

local DUMMY_STALLS: { [string]: StallSpec } = {
	yellow = {
		path = { "Backyard", "DummyBoard", "Stalls", "yellow" },
		position = Vector3.new(-33.2, 6.5, 2.8),
		size = Vector3.new(0.6, 5.4, 5.8),
		color = Color3.fromRGB(242, 209, 56),
		face = Enum.NormalId.Right,
	},
	fat = {
		path = { "Backyard", "DummyBoard", "Stalls", "fat" },
		position = Vector3.new(-33.2, 6.5, -3.4),
		size = Vector3.new(0.6, 5.4, 5.8),
		color = Color3.fromRGB(230, 133, 71),
		face = Enum.NormalId.Right,
	},
	gold = {
		path = { "Backyard", "DummyBoard", "Stalls", "gold" },
		position = Vector3.new(-33.2, 6.5, -9.6),
		size = Vector3.new(0.6, 5.4, 5.8),
		color = Color3.fromRGB(235, 184, 46),
		face = Enum.NormalId.Right,
	},
	crowd = {
		path = { "Backyard", "DummyBoard", "Stalls", "crowd" },
		position = Vector3.new(-33.2, 6.5, -15.8),
		size = Vector3.new(0.6, 5.4, 5.8),
		color = Color3.fromRGB(140, 140, 153),
		face = Enum.NormalId.Right,
	},
}

local GYM_STALL: StallSpec = {
	path = { "Backyard", "GymBoard", "Stall" },
	position = Vector3.new(33.2, 7, -8),
	size = Vector3.new(0.6, 8, 12),
	color = Color3.fromRGB(217, 115, 56),
	face = Enum.NormalId.Left,
}

local Boards = {}

local function isTable(value: any): boolean
	return typeof(value) == "table"
end

local function pick(from: any, keys: { string }): any
	if not isTable(from) then
		return nil
	end
	for _, key in keys do
		local value = from[key]
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function loadConfig(): any
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local module = if shared then shared:FindFirstChild("Config") else nil
	if module == nil then
		return {}
	end
	local ok, result = pcall(require, module)
	if ok and isTable(result) then
		return result
	end
	return {}
end

local function copyText(key: string, fallback: string): string
	local copy = pick(loadConfig(), { "copy", "Copy" })
	if isTable(copy) then
		local value = copy[key]
		if typeof(value) == "string" and value ~= "" then
			return value
		end
	end
	return fallback
end

local function promptDistance(): number
	local world = pick(loadConfig(), { "world", "World" })
	local value = pick(world, { "promptDistance", "PromptDistance" })
	if typeof(value) == "number" and value == value and value > 0 then
		return value
	end
	return 10
end

local function follow(path: { string }): Instance?
	local node: Instance? = Workspace
	for _, name in path do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(name)
	end
	return node
end

local function asPart(node: Instance?): BasePart?
	if node == nil then
		return nil
	end
	if node:IsA("BasePart") then
		return node
	end
	return node:FindFirstChildWhichIsA("BasePart", true)
end

local function backyardFolder(): Instance
	local existing = Workspace:FindFirstChild("Backyard")
	if existing ~= nil then
		return existing
	end
	local model = Instance.new("Model")
	model.Name = "Backyard"
	model.Parent = Workspace
	return model
end

local function ensureStall(spec: StallSpec, fallbackName: string): BasePart
	local found = asPart(follow(spec.path))
	if found ~= nil then
		return found
	end

	local part = Instance.new("Part")
	part.Name = fallbackName
	part.Anchored = true
	part.CanCollide = true
	part.Size = spec.size
	part.Position = spec.position
	part.Color = spec.color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = backyardFolder()
	return part
end

local function clearClientUi(part: BasePart)
	for _, child in part:GetChildren() do
		if child:GetAttribute("ClientBoard") == true then
			child:Destroy()
		end
	end
end

local function makeLabel(parent: Instance, name: string, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, textSize + 8)
	label.Font = Theme.font.title
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = ""
	label.Parent = parent
	return label
end

type BoardFace = {
	title: TextLabel,
	owned: TextLabel,
	lineA: TextLabel,
	lineB: TextLabel,
}

local function makeSurface(part: BasePart, face: Enum.NormalId): BoardFace
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80
	gui.ZOffset = 2
	gui.Active = false
	gui:SetAttribute("ClientBoard", true)
	gui.Parent = part

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.BackgroundColor3 = Theme.colors.panel
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.08, 0)
	pad.PaddingRight = UDim.new(0.08, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.Parent = frame

	return {
		title = makeLabel(frame, "Title", 28, Theme.colors.text),
		owned = makeLabel(frame, "Owned", 22, Theme.colors.muted),
		lineA = makeLabel(frame, "LineA", 22, Theme.colors.bonk),
		lineB = makeLabel(frame, "LineB", 20, Theme.colors.muted),
	}
end

local function makePrompt(part: BasePart, name: string, key: Enum.KeyCode, gamepad: Enum.KeyCode, offsetY: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.KeyboardKeyCode = key
	prompt.GamepadKeyCode = gamepad
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = promptDistance()
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.AutoLocalize = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.UIOffset = Vector2.new(0, offsetY)
	prompt:SetAttribute("ClientBoard", true)
	prompt.Parent = part
	return prompt
end

local function dummyName(id: string): string
	local raw = Formulas.dummyRaw(id)
	local named = pick(raw, { "name", "Name", "displayName", "DisplayName" })
	if typeof(named) == "string" and named ~= "" then
		return named
	end
	return id
end

local function upgradeIdForDummy(dummyId: string): string?
	local cfg = loadConfig()
	local order = pick(cfg, { "dummyUpgradeOrder", "DummyUpgradeOrder" })
	if isTable(order) then
		for _, id in order do
			if typeof(id) == "string" then
				local raw = Formulas.upgradeRaw(id)
				if isTable(raw) then
					local target = pick(raw, { "dummyId", "DummyId", "dummy", "Dummy" })
					if target == dummyId then
						return id
					end
				end
			end
		end
	end

	local root = pick(cfg, { "dummyUpgrades", "DummyUpgrades", "upgrades", "Upgrades" })
	if isTable(root) then
		for key, def in root do
			if isTable(def) then
				local id = if typeof(key) == "string" then key else pick(def, { "id", "Id" })
				local target = pick(def, { "dummyId", "DummyId", "dummy", "Dummy" })
				if typeof(id) == "string" and target == dummyId then
					return id
				end
			end
		end
	end

	local def = Formulas.dummyDef(dummyId)
	if def == nil then
		return nil
	end
	if def.maxUpgradeLevel <= 0 or Decimal.isZero(def.upgradeBaseCost) then
		return nil
	end
	if Formulas.knownUpgradeId(dummyId) then
		return dummyId
	end
	return nil
end

local function kind(affordable: boolean, atMax: boolean, locked: boolean): BuyKind
	if locked then
		return "locked"
	end
	if atMax then
		return "max"
	end
	if affordable then
		return "ready"
	end
	return "poor"
end

local function costLine(buyKind: BuyKind, prefix: string, cost: Decimal?): string
	if buyKind == "locked" then
		return copyText("locked", "Locked")
	end
	if buyKind == "max" then
		return copyText("maxed", "Max")
	end
	if cost == nil then
		return "—"
	end
	local price = Format.compact(cost)
	if buyKind == "poor" then
		return copyText("cantAfford", "Can't afford") .. "  " .. price
	end
	return prefix .. "  " .. price
end

local function paintPrompt(prompt: ProximityPrompt, buyKind: BuyKind, action: string, object: string, enabledWhenPoor: boolean)
	prompt.ObjectText = object
	if buyKind == "locked" then
		prompt.ActionText = copyText("locked", "Locked")
		prompt.Enabled = false
	elseif buyKind == "max" then
		prompt.ActionText = copyText("maxed", "Max")
		prompt.Enabled = false
	elseif buyKind == "poor" then
		prompt.ActionText = copyText("cantAfford", "Can't afford")
		prompt.Enabled = enabledWhenPoor
	else
		prompt.ActionText = action
		prompt.Enabled = true
	end
	prompt.MaxActivationDistance = promptDistance()
end

local function bindDummy(id: string, remotes: Remotes): DummyBinding?
	local spec = DUMMY_STALLS[id]
	if spec == nil then
		return nil
	end

	local part = ensureStall(spec, "Stall_" .. id)
	clearClientUi(part)
	local face = makeSurface(part, spec.face)
	local buyPrompt = makePrompt(part, "Buy", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 0)
	local upgradePrompt = makePrompt(part, "Upgrade", Enum.KeyCode.R, Enum.KeyCode.ButtonY, 72)
	local upgradeId = upgradeIdForDummy(id)

	buyPrompt.Triggered:Connect(function()
		remotes.buyDummy:FireServer(id)
	end)
	upgradePrompt.Triggered:Connect(function()
		if upgradeId ~= nil then
			remotes.buyUpgrade:FireServer(upgradeId)
		end
	end)

	local function refresh(state: ClientState)
		local def = Formulas.dummyDef(id)
		local owned = math.max(0, math.floor(state.dummies[id] or 0))
		local locked = not Formulas.canUnlockDummy(id, state.lifetimeGymRep)
		local atMax = def ~= nil and owned >= def.maxCount
		local cost = Formulas.dummyCost(id, owned)
		local affordable = cost ~= nil and Decimal.gte(state.bonk, cost)
		local buyKind = kind(affordable, atMax, locked)
		local name = dummyName(id)
		local ownedText = if def ~= nil then `{owned} / {def.maxCount}` else `x{owned}`

		face.title.Text = name
		face.owned.Text = ownedText
		if locked then
			face.owned.Text = copyText("locked", "Locked")
			face.lineA.Text = copyText("needsRep", "Needs Gym Rep")
			face.lineA.TextColor3 = Theme.colors.muted
			face.lineB.Text = ""
		else
			face.lineA.Text = costLine(buyKind, copyText("buy", "Buy"), cost)
			face.lineA.TextColor3 = if buyKind == "ready" then Theme.colors.bonk else Theme.colors.muted
		end

		paintPrompt(buyPrompt, buyKind, copyText("buy", "Buy"), name .. "  " .. ownedText, true)

		if upgradeId == nil or locked then
			upgradePrompt.Enabled = false
			face.lineB.Visible = false
			face.lineB.Text = ""
			if locked then
				upgradePrompt.ObjectText = copyText("needsRep", "Needs Gym Rep")
				upgradePrompt.ActionText = copyText("locked", "Locked")
			end
		else
			local upgradeDef = Formulas.upgradeDef(upgradeId)
			local level = math.max(0, math.floor(state.dummyUpgrades[upgradeId] or 0))
			local upgradeMax = upgradeDef ~= nil and level >= upgradeDef.maxLevel
			local upgradeCost = Formulas.upgradeCost(upgradeId, level)
			local upgradeAfford = upgradeCost ~= nil and Decimal.gte(state.bonk, upgradeCost)
			local upgradeKind = kind(upgradeAfford, upgradeMax, false)
			local upgradeLabel = copyText("upgrade", "Upgrade")
			local named = pick(Formulas.upgradeRaw(upgradeId), { "name", "Name" })
			if typeof(named) == "string" and named ~= "" then
				upgradeLabel = named
			end
			face.lineB.Visible = true
			face.lineB.Text = costLine(upgradeKind, upgradeLabel, upgradeCost)
			face.lineB.TextColor3 = if upgradeKind == "ready" then Theme.colors.text else Theme.colors.muted
			paintPrompt(upgradePrompt, upgradeKind, copyText("upgrade", "Upgrade"), upgradeLabel, true)
		end
	end

	return { refresh = refresh }
end

local function bindGym(remotes: Remotes): DummyBinding
	local part = ensureStall(GYM_STALL, "Stall_gym")
	clearClientUi(part)
	local face = makeSurface(part, GYM_STALL.face)
	local buyPrompt = makePrompt(part, "Buy", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 0)
	face.lineB.Visible = false
	face.lineB.Text = ""

	buyPrompt.Triggered:Connect(function()
		remotes.buyGym:FireServer()
	end)

	local function refresh(state: ClientState)
		local cfg = loadConfig()
		local gym = pick(cfg, { "gym", "Gym" })
		local named = pick(gym, { "name", "Name" })
		local title = if typeof(named) == "string" and named ~= "" then named else "This Gym"
		local maxLevel = Formulas.gymMaxLevel()
		local level = math.clamp(state.gymLevel, 1, maxLevel)
		local atMax = level >= maxLevel
		local cost = if atMax then nil else Formulas.gymCost(level)
		local affordable = cost ~= nil and Decimal.gte(state.bonk, cost)
		local buyKind = kind(affordable, atMax, false)
		local ownedText = `Level {level} / {maxLevel}`

		face.title.Text = title
		face.owned.Text = ownedText
		face.lineA.Text = costLine(buyKind, copyText("gymBuy", "Buy gym level"), cost)
		face.lineA.TextColor3 = if buyKind == "ready" then Theme.colors.bonk else Theme.colors.muted
		paintPrompt(buyPrompt, buyKind, copyText("gymBuy", "Buy gym level"), ownedText, true)
	end

	return { refresh = refresh }
end

function Boards.mount(remotes: Remotes)
	Workspace:WaitForChild("Backyard", 8)

	local bindings: { DummyBinding } = {}
	for _, id in DUMMY_IDS do
		local binding = bindDummy(id, remotes)
		if binding ~= nil then
			table.insert(bindings, binding)
		end
	end
	table.insert(bindings, bindGym(remotes))

	State.subscribe(function(state)
		for _, binding in bindings do
			binding.refresh(state)
		end
	end)
end

return Boards
