--!strict
-- Shared contracts. All balance numbers live in Config.luau.

export type Decimal = {
	m: number,
	e: number,
}

export type Cost = number | Decimal

export type DummyId = "yellow" | "fat" | "gold" | "crowd"

export type VenueId =
	"backyard"
	| "garage"
	| "school_gym"
	| "local_dojo"
	| "strip_mall_mma"
	| "tournament_lobby"
	| "pro_practice"
	| "hill_training"
	| "esports_stage"
	| "raid_pit"

export type Wave1RemoteName = "BuyDummy" | "BuyDummyUpgrade" | "BuyGymLevel" | "RequestSync"

export type RemoteName = Wave1RemoteName | "CloseDojo" | "BuyRepNode"

export type ColorRgb = {
	r: number,
	g: number,
	b: number,
}

-- Raw dummy row in Config. dummyPower in the hit formula is basePower + upgrade bonus.
-- upgradeBaseCost / maxUpgradeLevel stay 0 when dummyUpgrades[] is the live shop,
-- so BuyDummyUpgrade(dummyId) cannot stack a second track.
export type DummyConfig = {
	id: DummyId,
	name: string,
	role: string,
	sortOrder: number,
	baseCost: Cost,
	costGrowth: number,
	basePower: number,
	hitInterval: number,
	stayTime: number,
	maxCount: number,
	startingCount: number,
	unlockRep: number,
	penBodies: number,
	tint: ColorRgb,
	upgradeBaseCost: Cost,
	upgradeCostGrowth: number,
	powerPerUpgrade: number,
	stayTimePerUpgrade: number,
	maxUpgradeLevel: number,
}

export type DummyUpgradeConfig = {
	id: string,
	name: string,
	dummyId: DummyId,
	sortOrder: number,
	baseCost: Cost,
	costGrowth: number,
	maxLevel: number,
	powerPerLevel: number,
	stayTimePerLevel: number,
}

-- cost = Bonk to buy this level from the previous one. Level 1 is the free start.
-- multiplier is the gymLevel term in Bonk/hit (level n = n×).
export type GymLevelConfig = {
	level: number,
	multiplier: number,
	cost: Cost,
}

export type GymConfig = {
	name: string,
	maxLevel: number,
	baseCost: Cost,
	costGrowth: number,
	-- Formulas.gymCost uses baseCost * costGrowth^(currentLevel-1) unless `costs` is set.
	costs: { [number]: Cost }?,
	levels: { GymLevelConfig },
}

export type VenueConfig = {
	id: VenueId,
	name: string,
	index: number,
	venueMult: number,
	unlockRep: number,
	startsUnlocked: boolean,
	enterable: boolean,
	offlineCapSeconds: number,
	penCapacity: number,
	dummySlotBonus: number,
	skinSet: string,
	flavor: string,
}

export type RepNodeEffects = {
	startingDummyId: DummyId?,
	startingDummyBonus: number?,
	bonkMult: number?,
	gymCostMult: number?,
	offlineCapBonusSeconds: number?,
	unlockDummyId: DummyId?,
}

export type RepNodeConfig = {
	id: string,
	name: string,
	description: string,
	costRep: number,
	locked: boolean,
	maxPurchases: number,
	sortOrder: number,
	effects: RepNodeEffects,
}

export type RepShopConfig = {
	locked: boolean,
	nodeOrder: { string },
	nodes: { [string]: RepNodeConfig },
}

export type PrestigeConfig = {
	k: number,
	minGrant: number,
	showWhenNextBuySeconds: number,
}

export type StartConfig = {
	bonk: Cost,
	gymLevel: number,
	venueId: VenueId,
	dummies: { [string]: number },
}

export type ClickConfig = {
	enabled: boolean,
	extraHits: number,
	cooldownSeconds: number,
}

export type NumberFormatConfig = {
	suffixes: { string },
	decimals: number,
	sciFromExponent: number,
}

export type CopyConfig = {
	bonk: string,
	bonkPerSec: string,
	gymRep: string,
	closeDojo: string,
	tabDummies: string,
	tabGym: string,
	tabRep: string,
	tabVenues: string,
	buy: string,
	upgrade: string,
	gymBuy: string,
	cantAfford: string,
	locked: string,
	maxed: string,
	needsRep: string,
	hitPopupPrefix: string,
}

export type WorldConfig = {
	promptDistance: number,
	maxPenDummies: number,
}

export type Config = {
	wave: number,
	tickInterval: number,
	offlineCapSeconds: number,
	buyCooldownSeconds: number,
	start: StartConfig,
	click: ClickConfig,
	dummies: { [string]: DummyConfig },
	dummyOrder: { DummyId },
	dummyUpgrades: { [string]: DummyUpgradeConfig },
	dummyUpgradeOrder: { string },
	gym: GymConfig,
	venues: { [string]: VenueConfig },
	venueOrder: { VenueId },
	prestige: PrestigeConfig,
	repShop: RepShopConfig,
	numberFormat: NumberFormatConfig,
	copy: CopyConfig,
	world: WorldConfig,
}

-- Matches PlayerData.Profile. Bonk is Decimal { m, e }, never a raw number.
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

-- Wire payload from RequestSync. Bonk fields are Decimal { m, e }, not display strings.
export type Snapshot = {
	bonk: Decimal,
	bonkPerSec: Decimal,
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
	persistOk: boolean,
}

export type RateInput = {
	dummies: { [string]: number },
	dummyUpgrades: { [string]: number },
	gymLevel: number,
	venueId: string,
}

local Types = {}

return Types
