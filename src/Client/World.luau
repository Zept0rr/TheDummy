--!strict
-- Pen dummy stand-ins. Count from State, tint from Config. Display only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local State = require(script.Parent.State)

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type ClientState = State.ClientState

local DEFAULT_CAP = 12
local DEFAULT_ORDER = { "yellow", "fat", "gold", "crowd" }

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

local function makeStandIn(): Model
	local model = Instance.new("Model")
	model.Name = "StandIn"
	model:SetAttribute("ClientStandIn", true)

	local color = Color3.fromRGB(255, 216, 64)
	addPart(model, "Torso", Vector3.new(2, 2, 1.2), Vector3.new(0, 2.7, 0), color)
	addPart(model, "Head", Vector3.new(1.25, 1.25, 1.25), Vector3.new(0, 4.2, 0), color)
	addPart(model, "LeftLeg", Vector3.new(0.75, 1.8, 0.75), Vector3.new(-0.5, 0.9, 0), color)
	addPart(model, "RightLeg", Vector3.new(0.75, 1.8, 0.75), Vector3.new(0.5, 0.9, 0), color)
	addPart(model, "LeftArm", Vector3.new(0.55, 1.8, 0.55), Vector3.new(-1.3, 2.65, 0), color)
	addPart(model, "RightArm", Vector3.new(0.55, 1.8, 0.55), Vector3.new(1.3, 2.65, 0), color)

	return model
end

local function paint(model: Model, color: Color3)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			child.Color = color
			if child.Name == "Head" then
				child.Color = color:Lerp(Color3.new(1, 1, 1), 0.12)
			end
		end
	end
end

local function move(model: Model, feet: Vector3)
	local root = CFrame.lookAt(feet, feet + Vector3.new(0, 0, 1))
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

function World.mount()
	Workspace:WaitForChild("Backyard", 8)
	local pen = penFolder()

	for _, child in pen:GetChildren() do
		if child:GetAttribute("ClientStandIn") == true then
			child:Destroy()
		end
	end

	local pool: { Model } = {}

	local function ensure(n: number)
		while #pool < n do
			table.insert(pool, makeStandIn())
		end
	end

	State.subscribe(function(state)
		local slots = slotsFor(state)
		ensure(#slots)
		local positions = gridPositions(math.max(#slots, 1))
		for index, model in pool do
			local slot = slots[index]
			if slot ~= nil then
				model.Parent = pen
				paint(model, slot.tint)
				move(model, positions[index])
			else
				model.Parent = nil
			end
		end
	end)
end

return World
