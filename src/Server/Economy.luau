--!strict
-- Grant/spend Bonk. Client cannot grant.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))
local PlayerData = require(script.Parent.PlayerData)

type Profile = PlayerData.Profile
local Decimal = Formulas.Decimal

local Economy = {}

function Economy.rate(profile: Profile): Decimal
	return Formulas.bonkPerSec({
		dummies = profile.dummies,
		dummyUpgrades = profile.dummyUpgrades,
		gymLevel = profile.gymLevel,
		venueId = profile.venueId,
	})
end

function Economy.grantBonk(profile: Profile, amount: any)
	local grant = Decimal.from(amount)
	if Decimal.lte(grant, 0) then
		return
	end
	profile.bonk = Decimal.add(profile.bonk, grant)
	profile.lifetimeBonk = Decimal.add(profile.lifetimeBonk, grant)
	if Decimal.gt(profile.bonk, profile.peakBonkThisRun) then
		profile.peakBonkThisRun = Decimal.clone(profile.bonk)
	end
end

function Economy.trySpend(profile: Profile, cost: any): boolean
	local amount = Decimal.from(cost)
	if Decimal.lt(amount, 0) then
		return false
	end
	if Decimal.lt(profile.bonk, amount) then
		return false
	end
	if Decimal.gt(amount, 0) then
		profile.bonk = Decimal.sub(profile.bonk, amount)
	end
	return true
end

function Economy.applyOffline(profile: Profile)
	local now = os.time()
	local cap = Formulas.offlineCapSeconds()
	if profile.lastTick > 0 and cap > 0 then
		local elapsed = math.max(0, now - profile.lastTick)
		local grant = Formulas.offlineGrant(Economy.rate(profile), elapsed, cap)
		Economy.grantBonk(profile, grant)
	end
	profile.lastTick = now
end

function Economy.tickProfile(profile: Profile, dt: number)
	if dt <= 0 then
		return
	end
	Economy.grantBonk(profile, Decimal.mul(Economy.rate(profile), dt))
	profile.lastTick = os.time()
end

function Economy.start()
	Formulas.waitForConfig(10)
	PlayerData.setOnReady(function(player: Player, profile: Profile)
		Economy.applyOffline(profile)
		PlayerData.markDirty(player)
		PlayerData.save(player)
		PlayerData.sync(player)
	end)
	PlayerData.start()

	task.spawn(function()
		while true do
			local dt = Formulas.tickInterval()
			task.wait(dt)
			PlayerData.eachSession(function(player, profile)
				Economy.tickProfile(profile, dt)
				PlayerData.markDirty(player)
				PlayerData.sync(player)
			end)
		end
	end)
end

return Economy
