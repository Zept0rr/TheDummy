--!strict
-- BuyDummy / BuyDummyUpgrade. Costs from Config via Formulas. Server validates.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))
local PlayerData = require(script.Parent.PlayerData)
local Economy = require(script.Parent.Economy)

local BUY_COOLDOWN = 0.15

local Dummies = {}

function Dummies.buy(player: Player, id: any)
	if typeof(id) ~= "string" then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	if not PlayerData.buyAllowed(player, BUY_COOLDOWN) then
		return
	end

	local def = Formulas.dummyDef(id)
	if def == nil then
		return
	end
	if not Formulas.canUnlockDummy(id, profile.lifetimeGymRep) then
		return
	end

	local owned = math.max(0, math.floor(profile.dummies[id] or 0))
	if owned >= def.maxCount then
		return
	end

	local cost = Formulas.dummyCost(id, owned)
	if cost == nil or not Economy.trySpend(profile, cost) then
		return
	end

	profile.dummies[id] = owned + 1
	PlayerData.markDirty(player)
	PlayerData.save(player)
	PlayerData.sync(player)
end

function Dummies.buyUpgrade(player: Player, id: any)
	if typeof(id) ~= "string" then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	if not PlayerData.buyAllowed(player, BUY_COOLDOWN) then
		return
	end

	local def = Formulas.upgradeDef(id)
	if def == nil then
		return
	end
	if not Formulas.knownDummyId(def.dummyId) then
		return
	end
	if not Formulas.canUnlockDummy(def.dummyId, profile.lifetimeGymRep) then
		return
	end

	local level = math.max(0, math.floor(profile.dummyUpgrades[id] or 0))
	if level >= def.maxLevel then
		return
	end

	local cost = Formulas.upgradeCost(id, level)
	if cost == nil or not Economy.trySpend(profile, cost) then
		return
	end

	profile.dummyUpgrades[id] = level + 1
	PlayerData.markDirty(player)
	PlayerData.save(player)
	PlayerData.sync(player)
end

return Dummies
