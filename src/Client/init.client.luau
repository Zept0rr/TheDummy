--!strict
-- Wave 1 client bootstrap. HUD + dummy/gym shop + hit popups.
-- Spend is FireServer only. Client never grants Bonk.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Hud)
local ShopUI = require(script.ShopUI)
local State = require(script.State)
local WorldFx = require(script.WorldFx)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local buyDummy = remotesFolder:WaitForChild("BuyDummy") :: RemoteEvent
local buyUpgrade = remotesFolder:WaitForChild("BuyDummyUpgrade") :: RemoteEvent
local buyGym = remotesFolder:WaitForChild("BuyGymLevel") :: RemoteEvent
local requestSync = remotesFolder:WaitForChild("RequestSync") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "TheDummy"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 50
gui.Parent = playerGui

Hud.mount(gui)
ShopUI.mount(gui, {
	buyDummy = buyDummy,
	buyUpgrade = buyUpgrade,
	buyGym = buyGym,
})
WorldFx.mount(gui)

requestSync.OnClientEvent:Connect(function(snapshot: any)
	State.apply(snapshot)
end)

requestSync:FireServer()
