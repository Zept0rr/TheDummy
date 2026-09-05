--!strict
-- Client copy of the last server snapshot. Never grants Bonk.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
local Decimal = Formulas.Decimal

export type ClientState = {
	bonk: Decimal,
	bonkPerSec: Decimal,
	dummies: { [string]: number },
	dummyUpgrades: { [string]: number },
	gymLevel: number,
	venueId: string,
	lifetimeGymRep: number,
	persistOk: boolean,
}

export type Listener = (ClientState) -> ()

local State = {}

local function emptyCounts(): { [string]: number }
	return {}
end

local current: ClientState = {
	bonk = Decimal.fromNumber(0),
	bonkPerSec = Decimal.fromNumber(0),
	dummies = emptyCounts(),
	dummyUpgrades = emptyCounts(),
	gymLevel = 1,
	venueId = "backyard",
	lifetimeGymRep = 0,
	persistOk = true,
}

local listeners: { Listener } = {}

local function copyCounts(raw: any): { [string]: number }
	local copy: { [string]: number } = {}
	if typeof(raw) ~= "table" then
		return copy
	end
	for id, count in raw do
		if typeof(id) == "string" and typeof(count) == "number" and count == count then
			copy[id] = math.max(0, math.floor(count))
		end
	end
	return copy
end

function State.get(): ClientState
	return current
end

function State.dummyTotal(state: ClientState): number
	local total = 0
	for _, count in state.dummies do
		total += count
	end
	return total
end

function State.subscribe(listener: Listener): () -> ()
	table.insert(listeners, listener)
	listener(current)
	return function()
		local index = table.find(listeners, listener)
		if index ~= nil then
			table.remove(listeners, index)
		end
	end
end

function State.apply(raw: any)
	if typeof(raw) ~= "table" then
		return
	end

	local gymLevel = current.gymLevel
	if typeof(raw.gymLevel) == "number" and raw.gymLevel == raw.gymLevel then
		gymLevel = math.max(1, math.floor(raw.gymLevel))
	end

	local venueId = current.venueId
	if typeof(raw.venueId) == "string" and raw.venueId ~= "" then
		venueId = raw.venueId
	end

	local lifetimeGymRep = current.lifetimeGymRep
	if typeof(raw.lifetimeGymRep) == "number" and raw.lifetimeGymRep == raw.lifetimeGymRep then
		lifetimeGymRep = math.max(0, math.floor(raw.lifetimeGymRep))
	end

	local persistOk = current.persistOk
	if typeof(raw.persistOk) == "boolean" then
		persistOk = raw.persistOk
	end

	current = {
		bonk = Decimal.from(raw.bonk),
		bonkPerSec = Decimal.from(raw.bonkPerSec),
		dummies = copyCounts(raw.dummies),
		dummyUpgrades = copyCounts(raw.dummyUpgrades),
		gymLevel = gymLevel,
		venueId = venueId,
		lifetimeGymRep = lifetimeGymRep,
		persistOk = persistOk,
	}

	for _, listener in listeners do
		listener(current)
	end
end

return State
