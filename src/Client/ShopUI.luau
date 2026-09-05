--!strict
-- Wave 1 shop: Dummies | This Gym. Prices come from Config via Formulas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

type DummyRow = {
	root: Frame,
	name: TextLabel,
	owned: TextLabel,
	note: TextLabel,
	buy: TextButton,
	upgrade: TextButton,
	dummyId: string,
	upgradeId: string?,
}

local PREFERRED_ORDER: { [string]: number } = {
	yellow = 1,
	fat = 2,
	gold = 3,
	crowd = 4,
}

local ShopUI = {}

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
	if shared == nil then
		return {}
	end
	local module = shared:FindFirstChild("Config")
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

local function dummiesRoot(cfg: any): any
	local root = pick(cfg, { "dummies", "Dummies", "dummyTypes", "DummyTypes" })
	return if isTable(root) then root else {}
end

local function upgradesRoot(cfg: any): any
	local root = pick(cfg, { "dummyUpgrades", "DummyUpgrades", "upgrades", "Upgrades" })
	return if isTable(root) then root else {}
end

local function gymRoot(cfg: any): any
	local root = pick(cfg, { "gym", "Gym" })
	return if isTable(root) then root else {}
end

local function prettyName(id: string): string
	local spaced = string.gsub(id, "_", " ")
	spaced = string.gsub(spaced, "(%l)(%u)", "%1 %2")
	local titled = string.gsub(spaced, "(%a)([%w]*)", function(first: string, rest: string)
		return string.upper(first) .. string.lower(rest)
	end)
	if string.find(string.lower(titled), "dummy") == nil then
		return titled .. " Dummy"
	end
	return titled
end

local function dummyName(id: string): string
	local raw = Formulas.dummyRaw(id)
	local named = pick(raw, { "name", "Name", "displayName", "DisplayName", "title", "Title" })
	if typeof(named) == "string" and named ~= "" then
		return named
	end
	return prettyName(id)
end

local function dummyNote(id: string): string
	local raw = Formulas.dummyRaw(id)
	local role = pick(raw, { "role", "Role", "description", "Description", "blurb", "Blurb" })
	if typeof(role) == "string" and role ~= "" then
		return role
	end
	return ""
end

local function orderedDummyIds(): { string }
	local cfg = loadConfig()
	local root = dummiesRoot(cfg)
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}

	local function push(id: any)
		if typeof(id) == "string" and not seen[id] and Formulas.knownDummyId(id) then
			seen[id] = true
			table.insert(ids, id)
		end
	end

	local order = pick(cfg, { "dummyOrder", "DummyOrder" })
	if isTable(order) then
		for _, id in order do
			push(id)
		end
	end

	if isTable(root[1]) then
		for _, def in root do
			if isTable(def) then
				push(pick(def, { "id", "Id" }))
			end
		end
	end

	local keyed: { string } = {}
	for key, def in root do
		if typeof(key) == "string" and isTable(def) and not seen[key] and Formulas.knownDummyId(key) then
			table.insert(keyed, key)
		end
	end
	table.sort(keyed, function(a, b)
		local pa = PREFERRED_ORDER[a] or 100
		local pb = PREFERRED_ORDER[b] or 100
		if pa ~= pb then
			return pa < pb
		end
		return a < b
	end)
	for _, id in keyed do
		push(id)
	end

	Formulas.eachDummyDef(function(id, _raw)
		push(id)
	end)

	return ids
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

	local root = upgradesRoot(cfg)
	local listed: { string } = {}

	for key, def in root do
		if isTable(def) then
			local id = if typeof(key) == "string" then key else pick(def, { "id", "Id" })
			local target = pick(def, { "dummyId", "DummyId", "dummy", "Dummy" })
			if typeof(id) == "string" and (target == dummyId or target == nil and id == dummyId) then
				if Formulas.upgradeRaw(id) ~= nil then
					table.insert(listed, id)
				end
			end
		end
	end

	if #listed > 0 then
		return listed[1]
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

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance)
	local s = Instance.new("UIStroke")
	s.Color = Theme.colors.stroke
	s.Thickness = 1
	s.Transparency = 0.35
	s.Parent = parent
end

local function makeButton(parent: Instance, name: string, size: UDim2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Size = size
	button.Position = position
	button.Font = Theme.font.title
	button.TextSize = 14
	button.TextColor3 = Theme.colors.text
	button.BackgroundColor3 = Theme.colors.ready
	button.Text = ""
	button.TextTruncate = Enum.TextTruncate.AtEnd
	button.Parent = parent
	corner(button, 8)
	return button
end

local function applyBuy(button: TextButton, kind: BuyKind, label: string)
	button.Text = label
	if kind == "ready" then
		button.BackgroundColor3 = Theme.colors.ready
		button.TextColor3 = Theme.colors.text
		button.AutoButtonColor = true
	elseif kind == "poor" then
		button.BackgroundColor3 = Theme.colors.poor
		button.TextColor3 = Theme.colors.muted
		button.AutoButtonColor = false
	elseif kind == "max" then
		button.BackgroundColor3 = Theme.colors.locked
		button.TextColor3 = Theme.colors.muted
		button.AutoButtonColor = false
	else
		button.BackgroundColor3 = Theme.colors.locked
		button.TextColor3 = Theme.colors.muted
		button.AutoButtonColor = false
	end
end

local function buyKind(affordable: boolean, atMax: boolean, locked: boolean): BuyKind
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

local function affordLabel(kind: BuyKind, cost: Decimal?): string
	if kind == "locked" then
		return copyText("locked", "Locked")
	end
	if kind == "max" then
		return copyText("maxed", "Max")
	end
	if cost == nil then
		return "—"
	end
	local price = Format.compact(cost)
	if kind == "poor" then
		return "Can't afford  " .. price
	end
	return price
end

function ShopUI.mount(gui: ScreenGui, remotes: Remotes)
	local panel = Instance.new("Frame")
	panel.Name = "Shop"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 120)
	panel.Size = UDim2.new(0.42, 0, 1, -136)
	panel.BackgroundColor3 = Theme.colors.panel
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Parent = gui
	corner(panel, 12)
	stroke(panel)

	local sizeLock = Instance.new("UISizeConstraint")
	sizeLock.MinSize = Vector2.new(280, 240)
	sizeLock.MaxSize = Vector2.new(400, 10000)
	sizeLock.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.Parent = panel

	local tabs = Instance.new("Frame")
	tabs.Name = "Tabs"
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, 36)
	tabs.Parent = panel

	local dummiesTab = makeButton(tabs, "Dummies", UDim2.new(0.5, -4, 1, 0), UDim2.fromOffset(0, 0))
	local gymTab = makeButton(tabs, "ThisGym", UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0))
	dummiesTab.Text = copyText("tabDummies", "Dummies")
	gymTab.Text = copyText("tabGym", "This Gym")

	local dummiesPage = Instance.new("ScrollingFrame")
	dummiesPage.Name = "DummiesPage"
	dummiesPage.BackgroundTransparency = 1
	dummiesPage.BorderSizePixel = 0
	dummiesPage.Position = UDim2.fromOffset(0, 44)
	dummiesPage.Size = UDim2.new(1, 0, 1, -44)
	dummiesPage.ScrollBarThickness = 4
	dummiesPage.ScrollBarImageColor3 = Theme.colors.muted
	dummiesPage.CanvasSize = UDim2.new()
	dummiesPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
	dummiesPage.Parent = panel

	local dummiesList = Instance.new("UIListLayout")
	dummiesList.SortOrder = Enum.SortOrder.LayoutOrder
	dummiesList.Padding = UDim.new(0, 8)
	dummiesList.Parent = dummiesPage

	local gymPage = Instance.new("ScrollingFrame")
	gymPage.Name = "GymPage"
	gymPage.BackgroundTransparency = 1
	gymPage.BorderSizePixel = 0
	gymPage.Position = UDim2.fromOffset(0, 44)
	gymPage.Size = UDim2.new(1, 0, 1, -44)
	gymPage.ScrollBarThickness = 4
	gymPage.ScrollBarImageColor3 = Theme.colors.muted
	gymPage.CanvasSize = UDim2.new()
	gymPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gymPage.Visible = false
	gymPage.Parent = panel

	local gymList = Instance.new("UIListLayout")
	gymList.SortOrder = Enum.SortOrder.LayoutOrder
	gymList.Padding = UDim.new(0, 8)
	gymList.Parent = gymPage

	local gymCard = Instance.new("Frame")
	gymCard.Name = "GymCard"
	gymCard.BackgroundColor3 = Theme.colors.panelAlt
	gymCard.BorderSizePixel = 0
	gymCard.Size = UDim2.new(1, 0, 0, 148)
	gymCard.Parent = gymPage
	corner(gymCard, 10)

	local gymPad = Instance.new("UIPadding")
	gymPad.PaddingLeft = UDim.new(0, 12)
	gymPad.PaddingRight = UDim.new(0, 12)
	gymPad.PaddingTop = UDim.new(0, 12)
	gymPad.PaddingBottom = UDim.new(0, 12)
	gymPad.Parent = gymCard

	local gymTitle = Instance.new("TextLabel")
	gymTitle.Name = "Title"
	gymTitle.BackgroundTransparency = 1
	gymTitle.Size = UDim2.new(1, 0, 0, 22)
	gymTitle.Font = Theme.font.title
	gymTitle.TextSize = 18
	gymTitle.TextColor3 = Theme.colors.text
	gymTitle.TextXAlignment = Enum.TextXAlignment.Left
	gymTitle.Text = "This Gym"
	gymTitle.Parent = gymCard

	local gymLevel = Instance.new("TextLabel")
	gymLevel.Name = "Level"
	gymLevel.BackgroundTransparency = 1
	gymLevel.Position = UDim2.fromOffset(0, 26)
	gymLevel.Size = UDim2.new(1, 0, 0, 20)
	gymLevel.Font = Theme.font.body
	gymLevel.TextSize = 15
	gymLevel.TextColor3 = Theme.colors.muted
	gymLevel.TextXAlignment = Enum.TextXAlignment.Left
	gymLevel.Text = "Level 1 / 10"
	gymLevel.Parent = gymCard

	local gymBarBg = Instance.new("Frame")
	gymBarBg.Name = "BarBg"
	gymBarBg.BackgroundColor3 = Theme.colors.poor
	gymBarBg.BorderSizePixel = 0
	gymBarBg.Position = UDim2.fromOffset(0, 52)
	gymBarBg.Size = UDim2.new(1, 0, 0, 10)
	gymBarBg.Parent = gymCard
	corner(gymBarBg, 4)

	local gymBar = Instance.new("Frame")
	gymBar.Name = "Bar"
	gymBar.BackgroundColor3 = Theme.colors.bonk
	gymBar.BorderSizePixel = 0
	gymBar.Size = UDim2.new(0.1, 0, 1, 0)
	gymBar.Parent = gymBarBg
	corner(gymBar, 4)

	local gymHint = Instance.new("TextLabel")
	gymHint.Name = "Hint"
	gymHint.BackgroundTransparency = 1
	gymHint.Position = UDim2.fromOffset(0, 68)
	gymHint.Size = UDim2.new(1, 0, 0, 18)
	gymHint.Font = Theme.font.body
	gymHint.TextSize = 13
	gymHint.TextColor3 = Theme.colors.muted
	gymHint.TextXAlignment = Enum.TextXAlignment.Left
	gymHint.TextTruncate = Enum.TextTruncate.AtEnd
	gymHint.Text = "Fighters hit harder in this venue."
	gymHint.Parent = gymCard

	local gymBuy = makeButton(gymCard, "Buy", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 1, -36))
	gymBuy.Activated:Connect(function()
		local state = State.get()
		if state.gymLevel >= Formulas.gymMaxLevel() then
			return
		end
		remotes.buyGym:FireServer()
	end)

	local dummyRows: { DummyRow } = {}
	local activeTab = "dummies"

	local function paintTabs()
		if activeTab == "dummies" then
			dummiesTab.BackgroundColor3 = Theme.colors.tabOn
			dummiesTab.TextColor3 = Theme.colors.bg
			gymTab.BackgroundColor3 = Theme.colors.tabOff
			gymTab.TextColor3 = Theme.colors.text
			dummiesPage.Visible = true
			gymPage.Visible = false
		else
			gymTab.BackgroundColor3 = Theme.colors.tabOn
			gymTab.TextColor3 = Theme.colors.bg
			dummiesTab.BackgroundColor3 = Theme.colors.tabOff
			dummiesTab.TextColor3 = Theme.colors.text
			dummiesPage.Visible = false
			gymPage.Visible = true
		end
	end

	dummiesTab.Activated:Connect(function()
		activeTab = "dummies"
		paintTabs()
	end)
	gymTab.Activated:Connect(function()
		activeTab = "gym"
		paintTabs()
	end)
	paintTabs()

	local function makeDummyRow(dummyId: string, order: number): DummyRow
		local root = Instance.new("Frame")
		root.Name = dummyId
		root.BackgroundColor3 = Theme.colors.panelAlt
		root.BorderSizePixel = 0
		root.Size = UDim2.new(1, 0, 0, 108)
		root.LayoutOrder = order
		root.Parent = dummiesPage
		corner(root, 10)

		local rowPad = Instance.new("UIPadding")
		rowPad.PaddingLeft = UDim.new(0, 12)
		rowPad.PaddingRight = UDim.new(0, 12)
		rowPad.PaddingTop = UDim.new(0, 10)
		rowPad.PaddingBottom = UDim.new(0, 10)
		rowPad.Parent = root

		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(0.62, 0, 0, 20)
		name.Font = Theme.font.title
		name.TextSize = 16
		name.TextColor3 = Theme.colors.text
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Text = dummyName(dummyId)
		name.Parent = root

		local owned = Instance.new("TextLabel")
		owned.Name = "Owned"
		owned.BackgroundTransparency = 1
		owned.Position = UDim2.new(0.62, 0, 0, 0)
		owned.Size = UDim2.new(0.38, 0, 0, 20)
		owned.Font = Theme.font.body
		owned.TextSize = 14
		owned.TextColor3 = Theme.colors.muted
		owned.TextXAlignment = Enum.TextXAlignment.Right
		owned.Text = "x0"
		owned.Parent = root

		local note = Instance.new("TextLabel")
		note.Name = "Note"
		note.BackgroundTransparency = 1
		note.Position = UDim2.fromOffset(0, 22)
		note.Size = UDim2.new(1, 0, 0, 18)
		note.Font = Theme.font.body
		note.TextSize = 13
		note.TextColor3 = Theme.colors.muted
		note.TextXAlignment = Enum.TextXAlignment.Left
		note.TextTruncate = Enum.TextTruncate.AtEnd
		note.Text = dummyNote(dummyId)
		note.Parent = root

		local buy = makeButton(root, "Buy", UDim2.new(0.48, -4, 0, 36), UDim2.new(0, 0, 1, -36))
		local upgrade = makeButton(root, "Upgrade", UDim2.new(0.48, -4, 0, 36), UDim2.new(0.52, 4, 1, -36))

		local upgradeId = upgradeIdForDummy(dummyId)
		upgrade.Visible = upgradeId ~= nil
		if upgradeId == nil then
			buy.Size = UDim2.new(1, 0, 0, 36)
		end

		buy.Activated:Connect(function()
			local state = State.get()
			if not Formulas.canUnlockDummy(dummyId, state.lifetimeGymRep) then
				return
			end
			local def = Formulas.dummyDef(dummyId)
			local owned = math.max(0, math.floor(state.dummies[dummyId] or 0))
			if def ~= nil and owned >= def.maxCount then
				return
			end
			remotes.buyDummy:FireServer(dummyId)
		end)
		upgrade.Activated:Connect(function()
			if upgradeId == nil then
				return
			end
			local state = State.get()
			if not Formulas.canUnlockDummy(dummyId, state.lifetimeGymRep) then
				return
			end
			local upgradeDef = Formulas.upgradeDef(upgradeId)
			local level = math.max(0, math.floor(state.dummyUpgrades[upgradeId] or 0))
			if upgradeDef ~= nil and level >= upgradeDef.maxLevel then
				return
			end
			remotes.buyUpgrade:FireServer(upgradeId)
		end)

		return {
			root = root,
			name = name,
			owned = owned,
			note = note,
			buy = buy,
			upgrade = upgrade,
			dummyId = dummyId,
			upgradeId = upgradeId,
		}
	end

	local function ensureRows()
		local ids = orderedDummyIds()
		local same = #dummyRows == #ids
		if same then
			for index, id in ids do
				if dummyRows[index].dummyId ~= id then
					same = false
					break
				end
			end
		end
		if same then
			return
		end
		for _, row in dummyRows do
			row.root:Destroy()
		end
		table.clear(dummyRows)
		for index, id in ids do
			table.insert(dummyRows, makeDummyRow(id, index))
		end
	end

	local function refreshGym(state: ClientState)
		local cfg = loadConfig()
		local gym = gymRoot(cfg)
		local named = pick(gym, { "name", "Name", "displayName", "DisplayName" })
		local venues = pick(cfg, { "venues", "Venues" })
		local venue = if isTable(venues) then venues[state.venueId] else nil
		local venueName = pick(venue, { "name", "Name", "displayName", "DisplayName" })
		if typeof(named) == "string" and named ~= "" then
			gymTitle.Text = named
		elseif typeof(venueName) == "string" and venueName ~= "" then
			gymTitle.Text = venueName
		else
			gymTitle.Text = copyText("tabGym", "This Gym")
		end

		local maxLevel = Formulas.gymMaxLevel()
		local level = math.clamp(state.gymLevel, 1, maxLevel)
		gymLevel.Text = `Level {level} / {maxLevel}`
		gymBar.Size = UDim2.new(level / maxLevel, 0, 1, 0)
		gymHint.Text = `Fighters hit ×{level} in this venue.`

		local atMax = level >= maxLevel
		local cost = if atMax then nil else Formulas.gymCost(level)
		local affordable = cost ~= nil and Decimal.gte(state.bonk, cost)
		local kind = buyKind(affordable, atMax, false)
		local label: string
		if kind == "ready" and cost ~= nil then
			label = "Gym Lv " .. tostring(level + 1) .. "  " .. Format.compact(cost)
		else
			label = affordLabel(kind, cost)
		end
		applyBuy(gymBuy, kind, label)
	end

	local function refreshDummies(state: ClientState)
		ensureRows()
		for _, row in dummyRows do
			local def = Formulas.dummyDef(row.dummyId)
			local owned = math.max(0, math.floor(state.dummies[row.dummyId] or 0))
			local locked = not Formulas.canUnlockDummy(row.dummyId, state.lifetimeGymRep)
			local atMax = def ~= nil and owned >= def.maxCount
			local cost = Formulas.dummyCost(row.dummyId, owned)
			local affordable = cost ~= nil and Decimal.gte(state.bonk, cost)
			local kind = buyKind(affordable, atMax, locked)

			row.name.Text = dummyName(row.dummyId)
			row.owned.Text = if def ~= nil and def.maxCount < 100000 then `x{owned} / {def.maxCount}` else `x{owned}`
			local note = dummyNote(row.dummyId)
			if locked then
				local need = if def ~= nil then def.unlockRep else 0
				if need > 0 then
					row.note.Text = `Needs {need} Gym Rep`
				elseif note ~= "" then
					row.note.Text = note
				else
					row.note.Text = copyText("locked", "Locked")
				end
			else
				row.note.Text = note
			end
			if kind == "ready" and cost ~= nil then
				applyBuy(row.buy, kind, "Buy  " .. Format.compact(cost))
			else
				applyBuy(row.buy, kind, affordLabel(kind, cost))
			end

			local upgradeId = row.upgradeId
			if upgradeId == nil then
				row.upgrade.Visible = false
				row.buy.Size = UDim2.new(1, 0, 0, 36)
			else
				row.upgrade.Visible = true
				row.buy.Size = UDim2.new(0.48, -4, 0, 36)
				local upgradeDef = Formulas.upgradeDef(upgradeId)
				local level = math.max(0, math.floor(state.dummyUpgrades[upgradeId] or 0))
				local upgradeMax = upgradeDef ~= nil and level >= upgradeDef.maxLevel
				local upgradeCost = Formulas.upgradeCost(upgradeId, level)
				local upgradeAfford = upgradeCost ~= nil and Decimal.gte(state.bonk, upgradeCost)
				local upgradeKind = buyKind(upgradeAfford, upgradeMax, locked)
				local text: string
				if upgradeKind == "ready" and upgradeCost ~= nil then
					text = `Lv {level + 1}  {Format.compact(upgradeCost)}`
				elseif upgradeKind == "poor" and upgradeCost ~= nil then
					text = "Can't afford  " .. Format.compact(upgradeCost)
				else
					text = affordLabel(upgradeKind, upgradeCost)
				end
				applyBuy(row.upgrade, upgradeKind, text)
			end
		end
	end

	local function refresh(state: ClientState)
		dummiesTab.Text = copyText("tabDummies", "Dummies")
		gymTab.Text = copyText("tabGym", "This Gym")
		refreshDummies(state)
		refreshGym(state)
	end

	State.subscribe(refresh)

	task.spawn(function()
		Formulas.waitForConfig(60)
		refresh(State.get())
	end)
end

return ShopUI
