--!strict
-- Wave 1 client bootstrap. HUD + 3D boards + pen stand-ins + hit popups.
-- Spend is FireServer only. Client never grants Bonk.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boards = require(script.Boards)
local Hud = require(script.Hud)
local State = require(script.State)
local World = require(script.World)
local WorldFx = require(script.WorldFx)

local Formulas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))
Formulas.waitForConfig(30)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local buyDummy = remotesFolder:WaitForChild("BuyDummy") :: RemoteEvent
local buyUpgrade = remotesFolder:WaitForChild("BuyDummyUpgrade") :: RemoteEvent
local buyGym = remotesFolder:WaitForChild("BuyGymLevel") :: RemoteEvent
local requestSync = remotesFolder:WaitForChild("RequestSync") :: RemoteEvent

local existing = playerGui:FindFirstChild("TheDummy")
if existing ~= nil then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TheDummy"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 50
gui.Parent = playerGui

Hud.mount(gui)
World.mount()
Boards.mount({
	buyDummy = buyDummy,
	buyUpgrade = buyUpgrade,
	buyGym = buyGym,
})
WorldFx.mount(gui)

requestSync.OnClientEvent:Connect(function(snapshot: any)
	State.apply(snapshot)
end)

local function pull()
	requestSync:FireServer()
end

pull()
task.spawn(function()
	for _ = 1, 10 do
		if State.hasSnapshot() then
			return
		end
		task.wait(0.5)
		pull()
	end
end)
