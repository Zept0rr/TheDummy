--!strict
-- cost(n), bonkPerHit, prestige grant, offline. All balance numbers come from Config.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type Decimal = {
	m: number,
	e: number,
}

export type DummyDef = {
	id: string,
	baseCost: Decimal,
	costGrowth: number,
	basePower: number,
	hitInterval: number,
	stayTime: number,
	maxCount: number,
	startingCount: number,
	unlockRep: number,
	upgradeBaseCost: Decimal,
	upgradeCostGrowth: number,
	powerPerUpgrade: number,
	stayTimePerUpgrade: number,
	maxUpgradeLevel: number,
}

export type UpgradeDef = {
	id: string,
	dummyId: string,
	baseCost: Decimal,
	costGrowth: number,
	maxLevel: number,
	powerPerLevel: number,
	stayTimePerLevel: number,
}

export type RateInput = {
	dummies: { [string]: number },
	dummyUpgrades: { [string]: number },
	gymLevel: number,
	venueId: string,
}

--[[
	Config keys this module reads (Agent C owns the values):

	tickInterval, offlineCapSeconds
	start.bonk, start.gymLevel, start.venueId, start.dummies
	dummies[id]: baseCost, costGrowth, basePower, hitInterval, stayTime,
	  maxCount, startingCount, unlockRep, upgradeBaseCost, upgradeCostGrowth,
	  powerPerUpgrade, stayTimePerUpgrade, maxUpgradeLevel
	dummyUpgrades[id]: dummyId, baseCost, costGrowth, maxLevel, powerPerLevel, stayTimePerLevel
	gym.maxLevel, gym.baseCost, gym.costGrowth
	venues.backyard.venueMult
	prestige.k  -- floor(sqrt(peakBonk / k))
]]

local ZERO: Decimal = { m = 0, e = 0 }
local ONE: Decimal = { m = 1, e = 0 }

local Decimal = {}

local function normalize(m: number, e: number): Decimal
	if m ~= m or m == 0 or m == math.huge or m == -math.huge then
		return { m = 0, e = 0 }
	end

	local sign = 1
	if m < 0 then
		sign = -1
		m = -m
	end

	local logm = math.log10(m)
	if logm ~= logm or logm == math.huge or logm == -math.huge then
		return { m = 0, e = 0 }
	end

	local adj = math.floor(logm)
	m = m / (10 ^ adj)
	e += adj

	if m >= 10 then
		m /= 10
		e += 1
	elseif m < 1 then
		m *= 10
		e -= 1
	end

	return { m = sign * m, e = e }
end

function Decimal.fromNumber(n: number): Decimal
	return normalize(n, 0)
end

function Decimal.fromString(s: string): Decimal
	local trimmed = string.gsub(s, "%s+", "")
	if trimmed == "" then
		return { m = 0, e = 0 }
	end

	local mantissaStr, expStr = string.match(trimmed, "^([%+%-]?%d*%.?%d+)[eE]([%+%-]?%d+)$")
	if mantissaStr ~= nil and expStr ~= nil then
		local mantissa = tonumber(mantissaStr)
		local exp = tonumber(expStr)
		if mantissa ~= nil and exp ~= nil then
			return normalize(mantissa, exp)
		end
	end

	local n = tonumber(trimmed)
	if n ~= nil then
		return Decimal.fromNumber(n)
	end

	return { m = 0, e = 0 }
end

function Decimal.from(value: any): Decimal
	local valueType = typeof(value)
	if valueType == "number" then
		return Decimal.fromNumber(value)
	elseif valueType == "string" then
		return Decimal.fromString(value)
	elseif valueType == "table" then
		local m = value.m
		local e = value.e
		if typeof(m) == "number" and typeof(e) == "number" then
			return normalize(m, e)
		end
		if typeof(value[1]) == "number" and typeof(value[2]) == "number" then
			return normalize(value[1], value[2])
		end
	end
	return { m = 0, e = 0 }
end

function Decimal.clone(d: Decimal): Decimal
	return { m = d.m, e = d.e }
end

function Decimal.isZero(d: Decimal): boolean
	return d.m == 0
end

function Decimal.cmp(a: any, b: any): number
	local left = Decimal.from(a)
	local right = Decimal.from(b)
	if left.m == 0 and right.m == 0 then
		return 0
	end
	if left.m < 0 and right.m >= 0 then
		return -1
	end
	if left.m >= 0 and right.m < 0 then
		return 1
	end
	if left.e ~= right.e then
		if left.m >= 0 then
			return if left.e > right.e then 1 else -1
		end
		return if left.e > right.e then -1 else 1
	end
	if left.m == right.m then
		return 0
	end
	return if left.m > right.m then 1 else -1
end

function Decimal.eq(a: any, b: any): boolean
	return Decimal.cmp(a, b) == 0
end

function Decimal.lt(a: any, b: any): boolean
	return Decimal.cmp(a, b) < 0
end

function Decimal.lte(a: any, b: any): boolean
	return Decimal.cmp(a, b) <= 0
end

function Decimal.gt(a: any, b: any): boolean
	return Decimal.cmp(a, b) > 0
end

function Decimal.gte(a: any, b: any): boolean
	return Decimal.cmp(a, b) >= 0
end

function Decimal.add(a: any, b: any): Decimal
	local left = Decimal.from(a)
	local right = Decimal.from(b)
	if left.m == 0 then
		return Decimal.clone(right)
	end
	if right.m == 0 then
		return Decimal.clone(left)
	end
	if left.e < right.e then
		left, right = right, left
	end
	local de = left.e - right.e
	if de > 18 then
		return Decimal.clone(left)
	end
	return normalize(left.m + right.m * (10 ^ -de), left.e)
end

function Decimal.neg(a: any): Decimal
	local d = Decimal.from(a)
	return { m = -d.m, e = d.e }
end

function Decimal.sub(a: any, b: any): Decimal
	return Decimal.add(a, Decimal.neg(b))
end

function Decimal.mul(a: any, b: any): Decimal
	local left = Decimal.from(a)
	local right = Decimal.from(b)
	if left.m == 0 or right.m == 0 then
		return { m = 0, e = 0 }
	end
	return normalize(left.m * right.m, left.e + right.e)
end

function Decimal.div(a: any, b: any): Decimal
	local left = Decimal.from(a)
	local right = Decimal.from(b)
	if left.m == 0 then
		return { m = 0, e = 0 }
	end
	if right.m == 0 then
		return { m = 0, e = 0 }
	end
	return normalize(left.m / right.m, left.e - right.e)
end

function Decimal.pow(base: any, exponent: number): Decimal
	if exponent == 0 then
		return { m = 1, e = 0 }
	end
	local b = Decimal.from(base)
	if b.m == 0 then
		return { m = 0, e = 0 }
	end
	if b.m < 0 then
		local integer = exponent == math.floor(exponent)
		if not integer then
			return { m = 0, e = 0 }
		end
		local mag = Decimal.pow({ m = -b.m, e = b.e }, exponent)
		if exponent % 2 == 0 then
			return mag
		end
		return Decimal.neg(mag)
	end
	local log10 = exponent * (math.log10(b.m) + b.e)
	if log10 ~= log10 or log10 == math.huge or log10 == -math.huge then
		return { m = 0, e = 0 }
	end
	local e = math.floor(log10)
	return normalize(10 ^ (log10 - e), e)
end

function Decimal.max(a: any, b: any): Decimal
	if Decimal.gte(a, b) then
		return Decimal.from(a)
	end
	return Decimal.from(b)
end

function Decimal.floor(a: any): Decimal
	local d = Decimal.from(a)
	if d.m == 0 then
		return { m = 0, e = 0 }
	end
	if d.e >= 15 then
		return Decimal.clone(d)
	end
	if d.e < 0 then
		if d.m > 0 then
			return { m = 0, e = 0 }
		end
		return { m = -1, e = 0 }
	end
	return Decimal.fromNumber(math.floor(d.m * (10 ^ d.e)))
end

function Decimal.toNumber(a: any): number
	local d = Decimal.from(a)
	if d.m == 0 then
		return 0
	end
	local n = d.m * (10 ^ d.e)
	if n ~= n then
		return 0
	end
	if n == math.huge then
		return 1e308
	end
	if n == -math.huge then
		return -1e308
	end
	return n
end

function Decimal.toSci(a: any): string
	local d = Decimal.from(a)
	if d.m == 0 then
		return "0"
	end
	return string.format("%.6fe%d", d.m, d.e)
end

function Decimal.toPayload(a: any): { m: number, e: number }
	local d = Decimal.from(a)
	return { m = d.m, e = d.e }
end

local cachedConfig: any = nil

local function tryLoadConfig(): any
	if cachedConfig ~= nil then
		return cachedConfig
	end
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if shared == nil then
		return {}
	end
	local module = shared:FindFirstChild("Config")
	if module == nil then
		return {}
	end
	local ok, result = pcall(require, module)
	if ok and typeof(result) == "table" then
		cachedConfig = result
		return result
	end
	return {}
end

local function getConfig(): any
	return tryLoadConfig()
end

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

local function asNumber(value: any, fallback: number): number
	if typeof(value) == "number" and value == value then
		return value
	end
	if typeof(value) == "string" then
		local n = tonumber(value)
		if n ~= nil and n == n then
			return n
		end
	end
	return fallback
end

local function asInt(value: any, fallback: number): number
	return math.floor(asNumber(value, fallback))
end

local function tableAt(root: any, keys: { string }): any
	return pick(root, keys)
end

local Formulas = {}
Formulas.Decimal = Decimal
Formulas.zero = ZERO
Formulas.one = ONE

function Formulas.waitForConfig(timeoutSeconds: number)
	if cachedConfig ~= nil then
		return
	end
	local shared = ReplicatedStorage:WaitForChild("Shared", timeoutSeconds)
	if shared == nil then
		return
	end
	shared:WaitForChild("Config", timeoutSeconds)
	tryLoadConfig()
end

function Formulas.geometricCost(base: any, growth: number, owned: number): Decimal
	local n = math.max(0, math.floor(owned))
	local g = if growth > 0 then growth else 1
	return Decimal.mul(base, Decimal.pow(g, n))
end

Formulas.cost = Formulas.geometricCost

local function dummiesRoot(): any
	local cfg = getConfig()
	local root = tableAt(cfg, { "dummies", "Dummies", "dummyTypes", "DummyTypes" })
	return if isTable(root) then root else {}
end

local function upgradesRoot(): any
	local cfg = getConfig()
	local root = tableAt(cfg, { "dummyUpgrades", "DummyUpgrades", "upgrades", "Upgrades" })
	return if isTable(root) then root else {}
end

local function gymRoot(): any
	local cfg = getConfig()
	local root = tableAt(cfg, { "gym", "Gym" })
	return if isTable(root) then root else {}
end

local function startRoot(): any
	local cfg = getConfig()
	local root = tableAt(cfg, { "start", "Start", "starting", "Starting" })
	return if isTable(root) then root else {}
end

local function prestigeRoot(): any
	local cfg = getConfig()
	local root = tableAt(cfg, { "prestige", "Prestige" })
	return if isTable(root) then root else {}
end

local function venuesRoot(): any
	local cfg = getConfig()
	local root = tableAt(cfg, { "venues", "Venues" })
	return if isTable(root) then root else {}
end

function Formulas.eachDummyDef(callback: (id: string, raw: any) -> ())
	for key, def in dummiesRoot() do
		if isTable(def) then
			if typeof(key) == "string" then
				callback(key, def)
			elseif typeof(def.id) == "string" then
				callback(def.id, def)
			elseif typeof(def.Id) == "string" then
				callback(def.Id, def)
			end
		end
	end
end

function Formulas.dummyRaw(id: string): any?
	local direct = dummiesRoot()[id]
	if isTable(direct) then
		return direct
	end
	local found: any = nil
	Formulas.eachDummyDef(function(dummyId, def)
		if found == nil and dummyId == id then
			found = def
		end
	end)
	return found
end

function Formulas.upgradeRaw(id: string): any?
	local root = upgradesRoot()
	local direct = root[id]
	if isTable(direct) then
		return direct
	end
	for _, def in root do
		if isTable(def) and (def.id == id or def.Id == id) then
			return def
		end
	end
	return nil
end

local function readDummyDef(id: string, raw: any): DummyDef
	return {
		id = id,
		baseCost = Decimal.from(pick(raw, { "baseCost", "BaseCost", "cost", "Cost" }) or 0),
		costGrowth = asNumber(pick(raw, { "costGrowth", "CostGrowth", "growth", "Growth" }), 1),
		basePower = asNumber(pick(raw, { "basePower", "BasePower", "power", "Power" }), 0),
		hitInterval = math.max(asNumber(pick(raw, { "hitInterval", "HitInterval", "interval", "Interval" }), 1), 1e-6),
		stayTime = asNumber(pick(raw, { "stayTime", "StayTime", "stay", "Stay" }), 1),
		maxCount = math.max(0, asInt(pick(raw, { "maxCount", "MaxCount", "cap", "Cap" }), math.huge)),
		startingCount = math.max(0, asInt(pick(raw, { "startingCount", "StartingCount" }), 0)),
		unlockRep = math.max(0, asInt(pick(raw, { "unlockRep", "UnlockRep", "unlock", "Unlock" }), 0)),
		upgradeBaseCost = Decimal.from(pick(raw, { "upgradeBaseCost", "UpgradeBaseCost" }) or 0),
		upgradeCostGrowth = asNumber(pick(raw, { "upgradeCostGrowth", "UpgradeCostGrowth" }), 1),
		powerPerUpgrade = asNumber(pick(raw, { "powerPerUpgrade", "PowerPerUpgrade" }), 0),
		stayTimePerUpgrade = asNumber(pick(raw, { "stayTimePerUpgrade", "StayTimePerUpgrade" }), 0),
		maxUpgradeLevel = math.max(0, asInt(pick(raw, { "maxUpgradeLevel", "MaxUpgradeLevel" }), math.huge)),
	}
end

function Formulas.dummyDef(id: string): DummyDef?
	local raw = Formulas.dummyRaw(id)
	if raw == nil then
		return nil
	end
	return readDummyDef(id, raw)
end

function Formulas.knownDummyId(id: string): boolean
	return Formulas.dummyRaw(id) ~= nil
end

function Formulas.upgradeDef(id: string): UpgradeDef?
	local raw = Formulas.upgradeRaw(id)
	if isTable(raw) then
		local dummyId = pick(raw, { "dummyId", "DummyId", "dummy", "Dummy" })
		if typeof(dummyId) ~= "string" then
			dummyId = id
		end
		return {
			id = id,
			dummyId = dummyId,
			baseCost = Decimal.from(pick(raw, { "baseCost", "BaseCost", "cost", "Cost" }) or 0),
			costGrowth = asNumber(pick(raw, { "costGrowth", "CostGrowth", "growth", "Growth" }), 1),
			maxLevel = math.max(0, asInt(pick(raw, { "maxLevel", "MaxLevel" }), math.huge)),
			powerPerLevel = asNumber(pick(raw, { "powerPerLevel", "PowerPerLevel", "powerPerUpgrade", "PowerPerUpgrade" }), 0),
			stayTimePerLevel = asNumber(
				pick(raw, { "stayTimePerLevel", "StayTimePerLevel", "stayTimePerUpgrade", "StayTimePerUpgrade" }),
				0
			),
		}
	end

	local dummyRaw = Formulas.dummyRaw(id)
	if dummyRaw == nil then
		return nil
	end
	local upgradeCost = pick(dummyRaw, { "upgradeBaseCost", "UpgradeBaseCost" })
	if upgradeCost == nil then
		return nil
	end
	local dummy = readDummyDef(id, dummyRaw)
	return {
		id = id,
		dummyId = id,
		baseCost = dummy.upgradeBaseCost,
		costGrowth = dummy.upgradeCostGrowth,
		maxLevel = dummy.maxUpgradeLevel,
		powerPerLevel = dummy.powerPerUpgrade,
		stayTimePerLevel = dummy.stayTimePerUpgrade,
	}
end

function Formulas.knownUpgradeId(id: string): boolean
	return Formulas.upgradeDef(id) ~= nil
end

function Formulas.dummyCost(id: string, owned: number): Decimal?
	local def = Formulas.dummyDef(id)
	if def == nil then
		return nil
	end
	return Formulas.geometricCost(def.baseCost, def.costGrowth, owned)
end

function Formulas.upgradeCost(id: string, level: number): Decimal?
	local def = Formulas.upgradeDef(id)
	if def == nil then
		return nil
	end
	return Formulas.geometricCost(def.baseCost, def.costGrowth, level)
end

function Formulas.gymMaxLevel(): number
	return math.max(1, asInt(pick(gymRoot(), { "maxLevel", "MaxLevel" }), 10))
end

function Formulas.gymCost(currentLevel: number): Decimal?
	local gym = gymRoot()
	local nextLevel = math.floor(currentLevel) + 1
	local listed = pick(gym, { "costs", "Costs", "levelCosts", "LevelCosts" })
	if isTable(listed) then
		local entry = listed[nextLevel] or listed[tostring(nextLevel)]
		if entry == nil then
			return nil
		end
		return Decimal.from(entry)
	end
	local base = pick(gym, { "baseCost", "BaseCost", "cost", "Cost" })
	if base == nil then
		return nil
	end
	local growth = asNumber(pick(gym, { "costGrowth", "CostGrowth", "growth", "Growth" }), 1)
	local step = math.max(0, math.floor(currentLevel) - 1)
	return Formulas.geometricCost(base, growth, step)
end

function Formulas.tickInterval(): number
	local cfg = getConfig()
	local nested = tableAt(cfg, { "tick", "Tick" })
	local value = pick(cfg, { "tickInterval", "TickInterval" })
	if value == nil and isTable(nested) then
		value = pick(nested, { "interval", "Interval" })
	end
	return math.max(asNumber(value, 1), 0.05)
end

function Formulas.offlineCapSeconds(): number
	local cfg = getConfig()
	local nested = tableAt(cfg, { "offline", "Offline" })
	local value = pick(cfg, { "offlineCapSeconds", "OfflineCapSeconds" })
	if value == nil and isTable(nested) then
		value = pick(nested, { "capSeconds", "CapSeconds", "cap", "Cap" })
	end
	return math.max(0, asNumber(value, 0))
end

function Formulas.startingBonk(): Decimal
	return Decimal.from(pick(startRoot(), { "bonk", "Bonk" }) or 0)
end

function Formulas.startingGymLevel(): number
	return math.clamp(asInt(pick(startRoot(), { "gymLevel", "GymLevel" }), 1), 1, Formulas.gymMaxLevel())
end

function Formulas.startingVenueId(): string
	local id = pick(startRoot(), { "venueId", "VenueId" })
	if typeof(id) == "string" and id ~= "" then
		return id
	end
	return "backyard"
end

function Formulas.startingDummies(): { [string]: number }
	local result: { [string]: number } = {}
	local listed = pick(startRoot(), { "dummies", "Dummies" })
	if isTable(listed) then
		for id, count in listed do
			if typeof(id) == "string" then
				result[id] = math.max(0, asInt(count, 0))
			end
		end
		return result
	end
	Formulas.eachDummyDef(function(id, raw)
		local count = math.max(0, asInt(pick(raw, { "startingCount", "StartingCount" }), 0))
		if count > 0 then
			result[id] = count
		end
	end)
	return result
end

function Formulas.canUnlockDummy(id: string, lifetimeGymRep: number): boolean
	local def = Formulas.dummyDef(id)
	if def == nil then
		return false
	end
	return lifetimeGymRep >= def.unlockRep
end

local function backyardVenue(): any?
	local venues = venuesRoot()
	local named = pick(venues, { "backyard", "Backyard" })
	if isTable(named) then
		return named
	end
	if isTable(venues[1]) then
		return venues[1]
	end
	for _, def in venues do
		if isTable(def) then
			local id = pick(def, { "id", "Id" })
			if id == "backyard" or id == "Backyard" then
				return def
			end
		end
	end
	return nil
end

-- Wave 1 is Backyard only. Other venue ids are ignored.
function Formulas.venueMult(_venueId: string): number
	local venue = backyardVenue()
	if venue == nil then
		return 1
	end
	return asNumber(pick(venue, { "venueMult", "VenueMult", "mult", "Mult", "multiplier" }), 1)
end

function Formulas.dummyPower(basePower: number, upgradeBonus: number): Decimal
	return Decimal.fromNumber(math.max(0, basePower + upgradeBonus))
end

function Formulas.combo(stayTime: number, hitInterval: number): number
	local interval = math.max(hitInterval, 1e-6)
	return math.max(1, stayTime / interval)
end

function Formulas.hitsPerSecond(count: number, hitInterval: number): number
	if count <= 0 then
		return 0
	end
	return count / math.max(hitInterval, 1e-6)
end

function Formulas.bonkPerHit(dummyPower: any, gymLevel: number, venueMult: number, combo: number): Decimal
	return Decimal.mul(dummyPower, gymLevel * venueMult * math.max(combo, 1))
end

local function upgradeBonusForDummy(dummyId: string, dummyUpgrades: { [string]: number }): (number, number)
	local powerBonus = 0
	local stayBonus = 0

	local dummy = Formulas.dummyDef(dummyId)
	if dummy ~= nil then
		local level = math.max(0, math.floor(dummyUpgrades[dummyId] or 0))
		powerBonus += dummy.powerPerUpgrade * level
		stayBonus += dummy.stayTimePerUpgrade * level
	end

	for key, def in upgradesRoot() do
		if isTable(def) then
			local upgradeId = if typeof(key) == "string" then key else pick(def, { "id", "Id" })
			local target = pick(def, { "dummyId", "DummyId", "dummy", "Dummy" })
			if typeof(upgradeId) == "string" and target == dummyId and upgradeId ~= dummyId then
				local parsed = Formulas.upgradeDef(upgradeId)
				if parsed ~= nil then
					local level = math.max(0, math.floor(dummyUpgrades[upgradeId] or 0))
					powerBonus += parsed.powerPerLevel * level
					stayBonus += parsed.stayTimePerLevel * level
				end
			end
		end
	end

	return powerBonus, stayBonus
end

function Formulas.dummyBonkPerSec(id: string, count: number, dummyUpgrades: { [string]: number }, gymLevel: number, venueMult: number): Decimal
	if count <= 0 then
		return { m = 0, e = 0 }
	end
	local def = Formulas.dummyDef(id)
	if def == nil then
		return { m = 0, e = 0 }
	end
	local powerBonus, stayBonus = upgradeBonusForDummy(id, dummyUpgrades)
	local power = Formulas.dummyPower(def.basePower, powerBonus)
	local stay = math.max(def.stayTime + stayBonus, def.hitInterval)
	local combo = Formulas.combo(stay, def.hitInterval)
	local perHit = Formulas.bonkPerHit(power, gymLevel, venueMult, combo)
	local hits = Formulas.hitsPerSecond(count, def.hitInterval)
	return Decimal.mul(perHit, hits)
end

function Formulas.bonkPerSec(state: RateInput): Decimal
	local gymLevel = math.max(1, math.floor(state.gymLevel))
	local venueMult = Formulas.venueMult(state.venueId)
	local total: Decimal = { m = 0, e = 0 }
	Formulas.eachDummyDef(function(id, _raw)
		local count = math.max(0, math.floor(state.dummies[id] or 0))
		total = Decimal.add(total, Formulas.dummyBonkPerSec(id, count, state.dummyUpgrades, gymLevel, venueMult))
	end)
	return total
end

function Formulas.offlineGrant(rate: any, elapsedSeconds: number, capSeconds: number): Decimal
	local seconds = math.max(0, math.min(elapsedSeconds, math.max(0, capSeconds)))
	if seconds <= 0 then
		return { m = 0, e = 0 }
	end
	return Decimal.mul(rate, seconds)
end

function Formulas.prestigeK(): number
	return asNumber(pick(prestigeRoot(), { "k", "K" }), 0)
end

-- Wave 2 wires this. Shape is floor(sqrt(peakBonk / k)).
function Formulas.prestigeGrant(peakBonk: any): Decimal
	local k = Formulas.prestigeK()
	if k <= 0 then
		return { m = 0, e = 0 }
	end
	local ratio = Decimal.div(peakBonk, k)
	if Decimal.lte(ratio, 0) then
		return { m = 0, e = 0 }
	end
	return Decimal.floor(Decimal.pow(ratio, 0.5))
end

return Formulas
