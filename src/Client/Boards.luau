--!strict
-- NI-style 3D cards. Green Buy / gold Upgrade TextButtons fire remotes.

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
	standPosition: Vector3,
	standSize: Vector3,
	color: Color3,
	face: Enum.NormalId,
}

local DUMMY_IDS = { "yellow", "fat", "gold", "crowd" }

local DUMMY_STALLS: { [string]: StallSpec } = {
	yellow = {
		path = { "Backyard", "DummyBoard", "Stalls", "yellow" },
		position = Vector3.new(-31.2, 13.2, -2),
		size = Vector3.new(0.5, 7, 10),
		standPosition = Vector3.new(-27, 1.2, -2),
		standSize = Vector3.new(3, 0.4, 3),
		color = Color3.fromRGB(51, 56, 71),
		face = Enum.NormalId.Right,
	},
	fat = {
		path = { "Backyard", "DummyBoard", "Stalls", "fat" },
		position = Vector3.new(-31.2, 13.2, -14),
		size = Vector3.new(0.5, 7, 10),
		standPosition = Vector3.new(-27, 1.2, -14),
		standSize = Vector3.new(3, 0.4, 3),
		color = Color3.fromRGB(51, 56, 71),
		face = Enum.NormalId.Right,
	},
	gold = {
		path = { "Backyard", "DummyBoard", "Stalls", "gold" },
		position = Vector3.new(-31.2, 5.6, -2),
		size = Vector3.new(0.5, 7, 10),
		standPosition = Vector3.new(-23.5, 1.2, -2),
		standSize = Vector3.new(3, 0.4, 3),
		color = Color3.fromRGB(51, 56, 71),
		face = Enum.NormalId.Right,
	},
	crowd = {
		path = { "Backyard", "DummyBoard", "Stalls", "crowd" },
		position = Vector3.new(-31.2, 5.6, -14),
		size = Vector3.new(0.5, 7, 10),
		standPosition = Vector3.new(-23.5, 1.2, -14),
		standSize = Vector3.new(3, 0.4, 3),
		color = Color3.fromRGB(51, 56, 71),
		face = Enum.NormalId.Right,
	},
}

local GYM_STALL: StallSpec = {
	path = { "Backyard", "GymBoard", "Stall" },
	position = Vector3.new(31.2, 8, -8),
	size = Vector3.new(0.5, 12, 14),
	standPosition = Vector3.new(27, 1.2, -8),
	standSize = Vector3.new(4, 0.4, 4),
	color = Color3.fromRGB(51, 56, 71),
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

local function cardPixelsPerStud(): number
	local world = pick(loadConfig(), { "world", "World" })
	local value = pick(world, { "cardPixelsPerStud", "CardPixelsPerStud" })
	if typeof(value) == "number" and value == value and value > 0 then
		return value
	end
	return 40
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

	local stand = Instance.new("Part")
	stand.Name = "Stand"
	stand.Anchored = true
	stand.Size = spec.standSize
	stand.Position = spec.standPosition
	stand.Color = Color3.fromRGB(191, 173, 128)
	stand.Material = Enum.Material.SmoothPlastic
	stand.TopSurface = Enum.SurfaceType.Smooth
	stand.BottomSurface = Enum.SurfaceType.Smooth
	stand.Parent = part

	return part
end

local function clearClientUi(part: BasePart)
	for _, child in part:GetChildren() do
		if child:GetAttribute("ClientBoard") == true then
			child:Destroy()
		end
	end
end

local function makeLabel(parent: Instance, name: string, height: number, textSize: number, color: Color3, font: Enum.Font): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height)
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.Active = true
	button.BorderSizePixel = 0
	button.Size = UDim2.new(0.5, -5, 1, 0)
	button.Font = Theme.font.title
	button.TextSize = 24
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = color
	button.Text = ""
	button.TextTruncate = Enum.TextTruncate.AtEnd
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

type CardFace = {
	title: TextLabel,
	owned: TextLabel,
	effect: TextLabel,
	buy: TextButton,
	upgrade: TextButton,
	buyCost: TextLabel,
	upgradeCost: TextLabel,
	upgradeRow: Frame,
}

local function makeCard(part: BasePart, face: Enum.NormalId, showUpgrade: boolean): CardFace
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = cardPixelsPerStud()
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Brightness = 2
	gui.MaxDistance = 140
	gui.ZOffset = 2
	gui.Active = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("ClientBoard", true)
	gui.Parent = part

	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.BackgroundColor3 = Theme.colors.card
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 78, 96)
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.PaddingTop = UDim.new(0.07, 0)
	pad.PaddingBottom = UDim.new(0.07, 0)
	pad.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Top
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = frame

	local title = makeLabel(frame, "Title", 40, 32, Color3.new(1, 1, 1), Theme.font.title)
	title.LayoutOrder = 1
	title.TextScaled = true
	local titleSize = Instance.new("UITextSizeConstraint")
	titleSize.MinTextSize = 22
	titleSize.MaxTextSize = 36
	titleSize.Parent = title
	local owned = makeLabel(frame, "Owned", 28, 22, Theme.colors.cost, Theme.font.title)
	owned.LayoutOrder = 2
	local effect = makeLabel(frame, "Effect", 36, 16, Theme.colors.muted, Theme.font.body)
	effect.LayoutOrder = 3
	effect.TextWrapped = true

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 56)
	buttonRow.LayoutOrder = 4
	buttonRow.Parent = frame

	local buy = makeButton(buttonRow, "Buy", Theme.colors.buy)
	buy.Position = UDim2.fromScale(0, 0)
	buy.Size = if showUpgrade then UDim2.new(0.5, -5, 1, 0) else UDim2.new(1, 0, 1, 0)

	local upgrade = makeButton(buttonRow, "Upgrade", Theme.colors.upgrade)
	upgrade.AnchorPoint = Vector2.new(1, 0)
	upgrade.Position = UDim2.fromScale(1, 0)
	upgrade.Visible = showUpgrade

	local costRow = Instance.new("Frame")
	costRow.Name = "Costs"
	costRow.BackgroundTransparency = 1
	costRow.Size = UDim2.new(1, 0, 0, 26)
	costRow.LayoutOrder = 5
	costRow.Parent = frame

	local buyCost = makeLabel(costRow, "BuyCost", 26, 20, Theme.colors.cost, Theme.font.title)
	buyCost.Size = if showUpgrade then UDim2.new(0.5, -5, 1, 0) else UDim2.new(1, 0, 1, 0)
	buyCost.TextXAlignment = Enum.TextXAlignment.Center

	local upgradeCost = makeLabel(costRow, "UpgradeCost", 26, 20, Theme.colors.cost, Theme.font.title)
	upgradeCost.AnchorPoint = Vector2.new(1, 0)
	upgradeCost.Position = UDim2.fromScale(1, 0)
	upgradeCost.Size = UDim2.new(0.5, -5, 1, 0)
	upgradeCost.TextXAlignment = Enum.TextXAlignment.Center
	upgradeCost.Visible = showUpgrade

	return {
		title = title,
		owned = owned,
		effect = effect,
		buy = buy,
		upgrade = upgrade,
		buyCost = buyCost,
		upgradeCost = upgradeCost,
		upgradeRow = buttonRow,
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

local function dummyRole(id: string): string
	local raw = Formulas.dummyRaw(id)
	local role = pick(raw, { "role", "Role", "description", "Description" })
	if typeof(role) == "string" and role ~= "" then
		return role
	end
	return ""
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

local function costText(buyKind: BuyKind, cost: Decimal?): string
	if buyKind == "locked" then
		return copyText("needsRep", "Needs Gym Rep")
	end
	if buyKind == "max" then
		return copyText("maxed", "Max")
	end
	if cost == nil then
		return "—"
	end
	if buyKind == "poor" then
		return copyText("cantAfford", "Can't afford")
	end
	return Format.compact(cost)
end

local function paintButton(button: TextButton, buyKind: BuyKind, readyColor: Color3, label: string)
	button.Text = label
	if buyKind == "ready" then
		button.BackgroundColor3 = readyColor
		button.TextColor3 = Color3.new(1, 1, 1)
		button.AutoButtonColor = true
	else
		button.BackgroundColor3 = Theme.colors.poor
		button.TextColor3 = Theme.colors.muted
		button.AutoButtonColor = false
	end
end

local function paintCost(label: TextLabel, buyKind: BuyKind, cost: Decimal?)
	label.Text = costText(buyKind, cost)
	if buyKind == "ready" then
		label.TextColor3 = Theme.colors.cost
	else
		label.TextColor3 = Theme.colors.muted
	end
end

local function paintPrompt(prompt: ProximityPrompt, buyKind: BuyKind, action: string, object: string)
	prompt.ObjectText = object
	if buyKind == "locked" then
		prompt.ActionText = copyText("locked", "Locked")
		prompt.Enabled = false
	elseif buyKind == "max" then
		prompt.ActionText = copyText("maxed", "Max")
		prompt.Enabled = false
	elseif buyKind == "poor" then
		prompt.ActionText = copyText("cantAfford", "Can't afford")
		prompt.Enabled = true
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

	local part = ensureStall(spec, id)
	clearClientUi(part)
	local card = makeCard(part, spec.face, true)
	local buyPrompt = makePrompt(part, "Buy", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 0)
	local upgradePrompt = makePrompt(part, "Upgrade", Enum.KeyCode.R, Enum.KeyCode.ButtonY, 72)
	local upgradeId = upgradeIdForDummy(id)

	card.buy.Activated:Connect(function()
		remotes.buyDummy:FireServer(id)
	end)
	card.upgrade.Activated:Connect(function()
		if upgradeId ~= nil then
			remotes.buyUpgrade:FireServer(upgradeId)
		end
	end)
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
		local lv = copyText("level", "Lv")
		local ownedText = if def ~= nil then `{owned} / {def.maxCount}` else tostring(owned)

		card.title.Text = name
		card.owned.Text = if locked then copyText("locked", "Locked") else `{lv} {ownedText}`
		card.effect.Text = if locked then copyText("needsRep", "Needs Gym Rep") else dummyRole(id)

		paintButton(card.buy, buyKind, Theme.colors.buy, copyText("buy", "Buy"))
		paintCost(card.buyCost, buyKind, cost)
		paintPrompt(buyPrompt, buyKind, copyText("buy", "Buy"), name)

		if locked then
			card.upgrade.Visible = true
			card.upgradeCost.Visible = true
			paintButton(card.upgrade, "locked", Theme.colors.upgrade, copyText("upgrade", "Upgrade"))
			paintCost(card.upgradeCost, "locked", nil)
			upgradePrompt.Enabled = false
		elseif upgradeId == nil then
			card.upgrade.Visible = false
			card.upgradeCost.Visible = false
			card.buy.Size = UDim2.new(1, 0, 1, 0)
			card.buyCost.Size = UDim2.new(1, 0, 1, 0)
			upgradePrompt.Enabled = false
		else
			card.upgrade.Visible = true
			card.upgradeCost.Visible = true
			local upgradeDef = Formulas.upgradeDef(upgradeId)
			local level = math.max(0, math.floor(state.dummyUpgrades[upgradeId] or 0))
			local upgradeMax = upgradeDef ~= nil and level >= upgradeDef.maxLevel
			local upgradeCost = Formulas.upgradeCost(upgradeId, level)
			local upgradeAfford = upgradeCost ~= nil and Decimal.gte(state.bonk, upgradeCost)
			local upgradeKind = kind(upgradeAfford, upgradeMax, false)
			paintButton(card.upgrade, upgradeKind, Theme.colors.upgrade, `{copyText("upgrade", "Upgrade")}  {lv} {level}`)
			paintCost(card.upgradeCost, upgradeKind, upgradeCost)
			paintPrompt(upgradePrompt, upgradeKind, copyText("upgrade", "Upgrade"), `{lv} {level}`)
		end
	end

	return { refresh = refresh }
end

local function bindGym(remotes: Remotes): DummyBinding
	local part = ensureStall(GYM_STALL, "Stall")
	clearClientUi(part)
	local card = makeCard(part, GYM_STALL.face, false)
	local buyPrompt = makePrompt(part, "Buy", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 0)

	card.buy.Activated:Connect(function()
		remotes.buyGym:FireServer()
	end)
	buyPrompt.Triggered:Connect(function()
		remotes.buyGym:FireServer()
	end)

	local function refresh(state: ClientState)
		local cfg = loadConfig()
		local gym = pick(cfg, { "gym", "Gym" })
		local named = pick(gym, { "name", "Name" })
		local title = if typeof(named) == "string" and named ~= "" then named else copyText("tabGym", "This Gym")
		local flavor = pick(gym, { "flavor", "Flavor", "role", "Role" })
		local maxLevel = Formulas.gymMaxLevel()
		local level = math.clamp(state.gymLevel, 1, maxLevel)
		local atMax = level >= maxLevel
		local cost = if atMax then nil else Formulas.gymCost(level)
		local affordable = cost ~= nil and Decimal.gte(state.bonk, cost)
		local buyKind = kind(affordable, atMax, false)
		local lv = copyText("level", "Lv")
		local ownedText = `{lv} {level} / {maxLevel}`

		card.title.Text = title
		card.owned.Text = ownedText
		card.effect.Text = if typeof(flavor) == "string" then flavor else ""
		paintButton(card.buy, buyKind, Theme.colors.buy, copyText("gymBuy", "Buy gym level"))
		paintCost(card.buyCost, buyKind, cost)
		paintPrompt(buyPrompt, buyKind, copyText("gymBuy", "Buy gym level"), ownedText)
	end

	return { refresh = refresh }
end

local function bindBoardTitle(path: { string }, copyKey: string, face: Enum.NormalId)
	local part = asPart(follow(path))
	if part == nil then
		return
	end
	clearClientUi(part)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "TitleGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = cardPixelsPerStud()
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Brightness = 2
	gui.MaxDistance = 160
	gui.ZOffset = 4
	gui.Active = false
	gui:SetAttribute("ClientBoard", true)
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.font.title
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Text = copyText(copyKey, "")
	label.Parent = gui

	local size = Instance.new("UITextSizeConstraint")
	size.MinTextSize = 18
	size.MaxTextSize = 48
	size.Parent = label
end

function Boards.mount(remotes: Remotes)
	Workspace:WaitForChild("Backyard", 8)

	bindBoardTitle({ "Backyard", "DummyBoard", "Title" }, "tabDummies", Enum.NormalId.Right)
	bindBoardTitle({ "Backyard", "GymBoard", "Title" }, "tabGym", Enum.NormalId.Left)

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
