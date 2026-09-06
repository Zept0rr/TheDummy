--!strict
-- Blocky R6 dummy stand-ins. Pen count from State; stall.Stand gets a display dummy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local State = require(script.Parent.State)

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type ClientState = State.ClientState

local DEFAULT_CAP = 12
local DEFAULT_ORDER = { "yellow", "fat", "gold", "crowd" }
local STALL_IDS = { "yellow", "fat", "gold", "crowd" }

-- Classic R6 block sizes. Offsets are from feet (Y = 0).
local R6_PARTS: { { name: string, size: Vector3, offset: Vector3 } } = {
	{ name = "Head", size = Vector3.new(2, 1, 1), offset = Vector3.new(0, 4.5, 0) },
	{ name = "Torso", size = Vector3.new(2, 2, 1), offset = Vector3.new(0, 3, 0) },
	{ name = "LeftArm", size = Vector3.new(1, 2, 1), offset = Vector3.new(-1.5, 3, 0) },
	{ name = "RightArm", size = Vector3.new(1, 2, 1), offset = Vector3.new(1.5, 3, 0) },
	{ name = "LeftLeg", size = Vector3.new(1, 2, 1), offset = Vector3.new(-0.5, 1, 0) },
	{ name = "RightLeg", size = Vector3.new(1, 2, 1), offset = Vector3.new(0.5, 1, 0) },
}

local World = {}

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

local function maxPenDummies(): number
	local world = pick(loadConfig(), { "world", "World" })
	local value = pick(world, { "maxPenDummies", "MaxPenDummies" })
	if typeof(value) == "number" and value == value and value > 0 then
		return math.max(1, math.floor(value))
	end
	return DEFAULT_CAP
end

local function dummyOrder(): { string }
	local cfg = loadConfig()
	local order = pick(cfg, { "dummyOrder", "DummyOrder" })
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}
	if isTable(order) then
		for _, id in order do
			if typeof(id) == "string" and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	if #ids == 0 then
		return table.clone(DEFAULT_ORDER)
	end
	return ids
end

local function tintOf(id: string): Color3
	local raw = Formulas.dummyRaw(id)
	local tint = pick(raw, { "tint", "Tint", "color", "Color" })
	if isTable(tint) then
		local r = tint.r or tint.R
		local g = tint.g or tint.G
		local b = tint.b or tint.B
		if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
			return Color3.new(r, g, b)
		end
	end
	return Color3.fromRGB(255, 216, 64)
end

local function penBodies(id: string): number
	local raw = Formulas.dummyRaw(id)
	local value = pick(raw, { "penBodies", "PenBodies" })
	if typeof(value) == "number" and value == value then
		return math.max(1, math.floor(value))
	end
	return 1
end

local function backyard(): Instance
	local existing = Workspace:FindFirstChild("Backyard")
	if existing ~= nil then
		return existing
	end
	local model = Instance.new("Model")
	model.Name = "Backyard"
	model.Parent = Workspace
	return model
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

local function penFolder(): Model
	local yard = backyard()
	local existing = yard:FindFirstChild("PenDummies")
	if existing and existing:IsA("Model") then
		return existing
	end
	local model = Instance.new("Model")
	model.Name = "PenDummies"
	model.Parent = yard
	return model
end

local function penOrigin(): (Vector3, number)
	local yard = backyard()
	local pad = yard:FindFirstChild("Pen")
	if pad and pad:IsA("BasePart") then
		local top = pad.Position.Y + pad.Size.Y / 2
		return Vector3.new(pad.Position.X, top, pad.Position.Z), math.min(pad.Size.X, pad.Size.Z)
	end
	return Vector3.new(0, 1.4, -20), 32
end

local function addPart(parent: Model, name: string, size: Vector3, offset: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("Offset", offset)
	part.Parent = parent
	return part
end

local function makeR6(scale: number): Model
	local model = Instance.new("Model")
	model.Name = "StandIn"
	model:SetAttribute("ClientStandIn", true)
	local color = Color3.fromRGB(255, 216, 64)
	for _, def in R6_PARTS do
		addPart(model, def.name, def.size * scale, def.offset * scale, color)
	end
	return model
end

local function paint(model: Model, color: Color3)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			if child.Name == "Head" then
				child.Color = color:Lerp(Color3.new(1, 1, 1), 0.12)
			else
				child.Color = color
			end
		end
	end
end

local function move(model: Model, feet: Vector3, look: Vector3)
	local target = feet + look
	if look.Magnitude < 1e-4 then
		target = feet + Vector3.new(0, 0, 1)
	end
	local root = CFrame.lookAt(feet, Vector3.new(target.X, feet.Y, target.Z))
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			local offset = child:GetAttribute("Offset")
			if typeof(offset) == "Vector3" then
				child.CFrame = root * CFrame.new(offset)
			end
		end
	end
end

local function slotsFor(state: ClientState): { { id: string, tint: Color3 } }
	local cap = maxPenDummies()
	local remaining = cap
	local slots: { { id: string, tint: Color3 } } = {}
	for _, id in dummyOrder() do
		if remaining <= 0 then
			break
		end
		local owned = math.max(0, math.floor(state.dummies[id] or 0))
		if owned > 0 then
			local want = owned * penBodies(id)
			local take = math.min(want, remaining)
			local tint = tintOf(id)
			for _ = 1, take do
				table.insert(slots, { id = id, tint = tint })
			end
			remaining -= take
		end
	end
	return slots
end

local function gridPositions(count: number): { Vector3 }
	local origin, span = penOrigin()
	local cols = 4
	local spacing = math.min(3.8, (span - 8) / math.max(cols - 1, 1))
	local rows = math.max(1, math.ceil(count / cols))
	local x0 = origin.X - ((cols - 1) * spacing) / 2
	local z0 = origin.Z - ((rows - 1) * spacing) / 2
	local positions: { Vector3 } = {}
	for i = 1, count do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		table.insert(positions, Vector3.new(x0 + col * spacing, origin.Y, z0 + row * spacing))
	end
	return positions
end

local function findStand(path: { string }): BasePart?
	local node = follow(path)
	if node == nil then
		return nil
	end
	local stand = node:FindFirstChild("Stand")
	if stand and stand:IsA("BasePart") then
		return stand
	end
	if node:IsA("BasePart") and node.Name == "Stand" then
		return node
	end
	return nil
end

local function standFeet(stand: BasePart): Vector3
	return Vector3.new(stand.Position.X, stand.Position.Y + stand.Size.Y / 2, stand.Position.Z)
end

local function clearStandIns(root: Instance)
	for _, inst in root:GetDescendants() do
		if inst:GetAttribute("ClientStandIn") == true then
			inst:Destroy()
		end
	end
end

function World.mount()
	Workspace:WaitForChild("Backyard", 8)
	local yard = backyard()
	local pen = penFolder()

	clearStandIns(yard)

	local pool: { Model } = {}
	local stallDummies: { [string]: Model } = {}
	local gymDummy: Model? = nil

	local function ensurePen(n: number)
		while #pool < n do
			table.insert(pool, makeR6(0.85))
		end
	end

	local function ensureStallDummy(id: string, stand: BasePart): Model
		local existing = stallDummies[id]
		if existing ~= nil then
			return existing
		end
		local model = makeR6(0.55)
		model.Name = "DisplayDummy"
		model.Parent = stand
		stallDummies[id] = model
		return model
	end

	local function placeStallDisplays(state: ClientState)
		for _, id in STALL_IDS do
			local stand = findStand({ "Backyard", "DummyBoard", "Stalls", id })
			if stand ~= nil then
				local model = ensureStallDummy(id, stand)
				local owned = math.max(0, math.floor(state.dummies[id] or 0))
				local locked = not Formulas.canUnlockDummy(id, state.lifetimeGymRep)
				local tint = tintOf(id)
				if locked then
					tint = tint:Lerp(Color3.fromRGB(40, 40, 48), 0.55)
				elseif owned <= 0 then
					tint = tint:Lerp(Color3.fromRGB(80, 80, 90), 0.35)
				end
				paint(model, tint)
				move(model, standFeet(stand), Vector3.new(1, 0, 0))
				model.Parent = stand
			end
		end

		local gymStand = findStand({ "Backyard", "GymBoard", "Stall" })
		if gymStand ~= nil then
			local model = gymDummy
			if model == nil then
				model = makeR6(0.7)
				model.Name = "DisplayDummy"
				gymDummy = model
			end
			paint(model, Color3.fromRGB(232, 140, 56))
			move(model, standFeet(gymStand), Vector3.new(-1, 0, 0))
			model.Parent = gymStand
		end
	end

	State.subscribe(function(state)
		local slots = slotsFor(state)
		ensurePen(#slots)
		local positions = gridPositions(math.max(#slots, 1))
		for index, model in pool do
			local slot = slots[index]
			if slot ~= nil then
				model.Parent = pen
				paint(model, slot.tint)
				move(model, positions[index], Vector3.new(0, 0, 1))
			else
				model.Parent = nil
			end
		end
		placeStallDisplays(state)
	end)
end

return World
