--!strict
-- One binder. Wave 1 remotes only. Server validates every spend.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WAVE1_REMOTES = {
	"BuyDummy",
	"BuyDummyUpgrade",
	"BuyGymLevel",
	"RequestSync",
}

local FOLDER_NAME = "Remotes"

local Remotes = {}

local folder: Folder? = nil

local function getFolder(): Folder
	if folder ~= nil then
		return folder
	end

	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing and existing:IsA("Folder") then
			folder = existing
			return existing
		end
		local created = Instance.new("Folder")
		created.Name = FOLDER_NAME
		created.Parent = ReplicatedStorage
		folder = created
		return created
	end

	local replicated = ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
	assert(replicated ~= nil and replicated:IsA("Folder"), "Remotes folder missing")
	folder = replicated
	return replicated
end

function Remotes.get(name: string): RemoteEvent
	assert(table.find(WAVE1_REMOTES, name) ~= nil, `Unknown remote: {name}`)
	local remoteFolder = getFolder()

	if RunService:IsServer() then
		local existing = remoteFolder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
		return remote
	end

	local remote = remoteFolder:WaitForChild(name, 30)
	assert(remote ~= nil and remote:IsA("RemoteEvent"), `Remote {name} missing`)
	return remote
end

function Remotes.ensure()
	for _, name in WAVE1_REMOTES do
		Remotes.get(name)
	end
end

function Remotes.push(player: Player, snapshot: any)
	Remotes.get("RequestSync"):FireClient(player, snapshot)
end

function Remotes.bind()
	Remotes.ensure()

	local Dummies = require(script.Parent.Dummies)
	local Gym = require(script.Parent.Gym)
	local PlayerData = require(script.Parent.PlayerData)

	Remotes.get("BuyDummy").OnServerEvent:Connect(function(player: Player, id: any)
		Dummies.buy(player, id)
	end)

	Remotes.get("BuyDummyUpgrade").OnServerEvent:Connect(function(player: Player, id: any)
		Dummies.buyUpgrade(player, id)
	end)

	Remotes.get("BuyGymLevel").OnServerEvent:Connect(function(player: Player)
		Gym.buyLevel(player)
	end)

	Remotes.get("RequestSync").OnServerEvent:Connect(function(player: Player)
		PlayerData.sync(player)
	end)
end

return Remotes
