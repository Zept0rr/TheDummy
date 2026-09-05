--!strict
-- DataStore profile. Client never writes this.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

type Decimal = Formulas.Decimal
local Decimal = Formulas.Decimal

export type Profile = {
	bonk: Decimal,
	lifetimeBonk: Decimal,
	peakBonkThisRun: Decimal,
	dummies: { [string]: number },
	dummyUpgrades: { [string]: number },
	gymLevel: number,
	venueId: string,
	unlockedVenues: { string },
	gymRep: number,
	lifetimeGymRep: number,
	lastTick: number,
	repNodes: { [string]: boolean },
}

export type Snapshot = {
	bonk: { m: number, e: number },
	bonkPerSec: { m: number, e: number },
	lifetimeBonk: { m: number, e: number },
	peakBonkThisRun: { m: number, e: number },
	dummies: { [string]: number },
	dummyUpgrades: { [string]: number },
	gymLevel: number,
	venueId: string,
	unlockedVenues: { string },
	gymRep: number,
	lifetimeGymRep: number,
	lastTick: number,
	persistOk: boolean,
}

type Session = {
	player: Player,
	profile: Profile,
	persistOk: boolean,
	dirty: boolean,
	lastBuyAt: number,
	lastSaveAt: number,
}

local STORE_NAME = "TheDummy_PlayerData_v1"
local AUTOSAVE_SECONDS = 30
local BACKYARD = "backyard"

local PlayerData = {}

local sessions: { [Player]: Session } = {}
local onReady: ((Player, Profile) -> ())? = nil
local remotes: any = nil

local function getRemotes()
	if remotes == nil then
		remotes = require(script.Parent.Remotes)
	end
	return remotes
end

local function copyCounts(src: { [string]: number }): { [string]: number }
	local copy: { [string]: number } = {}
	for id, count in src do
		copy[id] = count
	end
	return copy
end

local function copyFlags(src: { [string]: boolean }): { [string]: boolean }
	local copy: { [string]: boolean } = {}
	for id, owned in src do
		copy[id] = owned
	end
	return copy
end

local function copyVenues(src: { string }): { string }
	local copy: { string } = {}
	for _, id in src do
		table.insert(copy, id)
	end
	return copy
end

local function hasKnownDummies(): boolean
	local found = false
	Formulas.eachDummyDef(function(_id, _raw)
		found = true
	end)
	return found
end

local function sanitizeCounts(raw: any, asDummy: boolean): { [string]: number }
	local counts: { [string]: number } = {}
	if typeof(raw) ~= "table" then
		return counts
	end
	local restrict = hasKnownDummies()
	for id, count in raw do
		if typeof(id) == "string" then
			if restrict then
				if asDummy and not Formulas.knownDummyId(id) then
					continue
				end
				if not asDummy and not Formulas.knownUpgradeId(id) then
					continue
				end
			end
			if typeof(count) == "number" and count == count then
				counts[id] = math.max(0, math.floor(count))
			end
		end
	end
	return counts
end

local function sanitizeVenues(raw: any): { string }
	local venues: { string } = {}
	local seen: { [string]: boolean } = {}
	if typeof(raw) == "table" then
		for _, id in raw do
			if typeof(id) == "string" and id ~= "" and not seen[id] then
				seen[id] = true
				table.insert(venues, id)
			end
		end
	end
	if not seen[BACKYARD] then
		table.insert(venues, 1, BACKYARD)
	end
	return venues
end

local function sanitizeRepNodes(raw: any): { [string]: boolean }
	local nodes: { [string]: boolean } = {}
	if typeof(raw) ~= "table" then
		return nodes
	end
	for key, value in raw do
		if typeof(key) == "string" then
			if value == true or value == 1 then
				nodes[key] = true
			end
		elseif typeof(value) == "string" then
			nodes[value] = true
		end
	end
	return nodes
end

function PlayerData.defaultProfile(): Profile
	return {
		bonk = Formulas.startingBonk(),
		lifetimeBonk = Formulas.startingBonk(),
		peakBonkThisRun = Formulas.startingBonk(),
		dummies = Formulas.startingDummies(),
		dummyUpgrades = {},
		gymLevel = Formulas.startingGymLevel(),
		venueId = BACKYARD,
		unlockedVenues = { BACKYARD },
		gymRep = 0,
		lifetimeGymRep = 0,
		lastTick = 0,
		repNodes = {},
	}
end

function PlayerData.cloneProfile(profile: Profile): Profile
	return {
		bonk = Decimal.clone(profile.bonk),
		lifetimeBonk = Decimal.clone(profile.lifetimeBonk),
		peakBonkThisRun = Decimal.clone(profile.peakBonkThisRun),
		dummies = copyCounts(profile.dummies),
		dummyUpgrades = copyCounts(profile.dummyUpgrades),
		gymLevel = profile.gymLevel,
		venueId = profile.venueId,
		unlockedVenues = copyVenues(profile.unlockedVenues),
		gymRep = profile.gymRep,
		lifetimeGymRep = profile.lifetimeGymRep,
		lastTick = profile.lastTick,
		repNodes = copyFlags(profile.repNodes),
	}
end

function PlayerData.sanitize(raw: any): Profile
	local profile = PlayerData.defaultProfile()
	if typeof(raw) ~= "table" then
		return profile
	end

	profile.bonk = Decimal.from(raw.bonk)
	profile.lifetimeBonk = Decimal.from(raw.lifetimeBonk)
	profile.peakBonkThisRun = Decimal.from(raw.peakBonkThisRun)
	if Decimal.isZero(profile.lifetimeBonk) then
		profile.lifetimeBonk = Decimal.clone(profile.bonk)
	end
	profile.peakBonkThisRun = Decimal.max(profile.peakBonkThisRun, profile.bonk)

	if typeof(raw.dummies) == "table" then
		profile.dummies = sanitizeCounts(raw.dummies, true)
	end
	if typeof(raw.dummyUpgrades) == "table" then
		profile.dummyUpgrades = sanitizeCounts(raw.dummyUpgrades, false)
	end

	if typeof(raw.gymLevel) == "number" then
		profile.gymLevel = math.clamp(math.floor(raw.gymLevel), 1, Formulas.gymMaxLevel())
	end

	-- Wave 1: Backyard only.
	profile.venueId = BACKYARD
	profile.unlockedVenues = sanitizeVenues(raw.unlockedVenues)

	if typeof(raw.gymRep) == "number" and raw.gymRep == raw.gymRep then
		profile.gymRep = math.max(0, math.floor(raw.gymRep))
	end
	if typeof(raw.lifetimeGymRep) == "number" and raw.lifetimeGymRep == raw.lifetimeGymRep then
		profile.lifetimeGymRep = math.max(0, math.floor(raw.lifetimeGymRep))
	end
	if profile.lifetimeGymRep < profile.gymRep then
		profile.lifetimeGymRep = profile.gymRep
	end

	if typeof(raw.lastTick) == "number" and raw.lastTick == raw.lastTick then
		profile.lastTick = math.max(0, math.floor(raw.lastTick))
	end

	profile.repNodes = sanitizeRepNodes(raw.repNodes)
	return profile
end

local function serialize(profile: Profile): { [string]: any }
	return {
		bonk = Decimal.toPayload(profile.bonk),
		lifetimeBonk = Decimal.toPayload(profile.lifetimeBonk),
		peakBonkThisRun = Decimal.toPayload(profile.peakBonkThisRun),
		dummies = copyCounts(profile.dummies),
		dummyUpgrades = copyCounts(profile.dummyUpgrades),
		gymLevel = profile.gymLevel,
		venueId = profile.venueId,
		unlockedVenues = copyVenues(profile.unlockedVenues),
		gymRep = profile.gymRep,
		lifetimeGymRep = profile.lifetimeGymRep,
		lastTick = profile.lastTick,
		repNodes = copyFlags(profile.repNodes),
	}
end

local function getStore(): DataStore?
	local ok, storeOrErr = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if not ok then
		warn("[PlayerData] DataStore unavailable:", storeOrErr)
		return nil
	end
	return storeOrErr
end

function PlayerData.load(player: Player): (Profile, boolean)
	local store = getStore()
	if store == nil then
		return PlayerData.defaultProfile(), false
	end

	local key = tostring(player.UserId)
	local ok, dataOrErr = pcall(function()
		return store:GetAsync(key)
	end)
	if not ok then
		warn("[PlayerData] GetAsync failed:", dataOrErr)
		return PlayerData.defaultProfile(), false
	end
	if dataOrErr == nil then
		return PlayerData.defaultProfile(), true
	end
	return PlayerData.sanitize(dataOrErr), true
end

function PlayerData.save(player: Player): boolean
	local session = sessions[player]
	if session == nil then
		return false
	end
	if not session.persistOk then
		return false
	end

	local store = getStore()
	if store == nil then
		session.persistOk = false
		return false
	end

	session.profile.lastTick = os.time()
	local payload = serialize(session.profile)
	local key = tostring(player.UserId)
	local ok, err = pcall(function()
		store:SetAsync(key, payload)
	end)
	if not ok then
		warn("[PlayerData] SetAsync failed:", err)
		session.persistOk = false
		return false
	end
	session.dirty = false
	session.lastSaveAt = os.clock()
	return true
end

function PlayerData.get(player: Player): Profile?
	local session = sessions[player]
	if session == nil then
		return nil
	end
	return session.profile
end

function PlayerData.session(player: Player): Session?
	return sessions[player]
end

function PlayerData.markDirty(player: Player)
	local session = sessions[player]
	if session ~= nil then
		session.dirty = true
	end
end

function PlayerData.buyAllowed(player: Player, cooldown: number): boolean
	local session = sessions[player]
	if session == nil then
		return false
	end
	local now = os.clock()
	if now - session.lastBuyAt < cooldown then
		return false
	end
	session.lastBuyAt = now
	return true
end

function PlayerData.snapshot(player: Player): Snapshot?
	local session = sessions[player]
	if session == nil then
		return nil
	end
	local profile = session.profile
	local rate = Formulas.bonkPerSec({
		dummies = profile.dummies,
		dummyUpgrades = profile.dummyUpgrades,
		gymLevel = profile.gymLevel,
		venueId = profile.venueId,
	})
	return {
		bonk = Decimal.toPayload(profile.bonk),
		bonkPerSec = Decimal.toPayload(rate),
		lifetimeBonk = Decimal.toPayload(profile.lifetimeBonk),
		peakBonkThisRun = Decimal.toPayload(profile.peakBonkThisRun),
		dummies = copyCounts(profile.dummies),
		dummyUpgrades = copyCounts(profile.dummyUpgrades),
		gymLevel = profile.gymLevel,
		venueId = profile.venueId,
		unlockedVenues = copyVenues(profile.unlockedVenues),
		gymRep = profile.gymRep,
		lifetimeGymRep = profile.lifetimeGymRep,
		lastTick = profile.lastTick,
		persistOk = session.persistOk,
	}
end

function PlayerData.sync(player: Player)
	local snapshot = PlayerData.snapshot(player)
	if snapshot == nil then
		return
	end
	getRemotes().push(player, snapshot)
end

function PlayerData.setOnReady(callback: (Player, Profile) -> ())
	onReady = callback
end

local function onPlayerAdded(player: Player)
	local profile, persistOk = PlayerData.load(player)
	if player.Parent == nil then
		return
	end
	sessions[player] = {
		player = player,
		profile = profile,
		persistOk = persistOk,
		dirty = false,
		lastBuyAt = 0,
		lastSaveAt = os.clock(),
	}
	if onReady ~= nil then
		onReady(player, profile)
	else
		PlayerData.sync(player)
	end
end

local function onPlayerRemoving(player: Player)
	PlayerData.save(player)
	sessions[player] = nil
end

function PlayerData.eachSession(callback: (Player, Profile) -> ())
	for player, session in sessions do
		if player.Parent ~= nil then
			callback(player, session.profile)
		end
	end
end

function PlayerData.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	game:BindToClose(function()
		for player, _session in sessions do
			PlayerData.save(player)
		end
		task.wait(1)
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, session in sessions do
				if session.dirty and player.Parent ~= nil then
					PlayerData.save(player)
				end
			end
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlayerData
