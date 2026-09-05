--!strict
-- BuyGymLevel. Wave 1 Backyard gym 1–10. Costs from Config via Formulas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))
local PlayerData = require(script.Parent.PlayerData)
local Economy = require(script.Parent.Economy)

local BUY_COOLDOWN = 0.15

local Gym = {}

function Gym.buyLevel(player: Player)
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	if not PlayerData.buyAllowed(player, BUY_COOLDOWN) then
		return
	end

	local maxLevel = Formulas.gymMaxLevel()
	if profile.gymLevel >= maxLevel then
		return
	end

	local cost = Formulas.gymCost(profile.gymLevel)
	if cost == nil or not Economy.trySpend(profile, cost) then
		return
	end

	profile.gymLevel += 1
	PlayerData.markDirty(player)
	PlayerData.save(player)
	PlayerData.sync(player)
end

return Gym
