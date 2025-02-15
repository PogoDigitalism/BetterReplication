--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BufferUtils = require(ReplicatedStorage.BetterReplication.Lib.BufferUtils)
local GetRegistry = ReplicatedStorage.BetterReplication.Remotes.GetRegistry
local Utils = require(ReplicatedStorage.BetterReplication.Lib.Utils)
local Config = require(ReplicatedStorage.BetterReplication.Config)

local FromClient = ReplicatedStorage.BetterReplication.Remotes.FromClient
local ToClient = ReplicatedStorage.BetterReplication.Remotes.ToClient
local RegisterIdentifier = ReplicatedStorage.BetterReplication.Remotes.RegisterIdentifier
local OutOfProximity = ReplicatedStorage.BetterReplication.Remotes.OutOfProximity

local random = Random.new(tick())

type playerIdentifier = number

local UptodatePositions = {}
local positionTable = {} :: {[Player]: CFrame} -- table for getting latest position data
local identifiers = {} :: {[Player]: playerIdentifier}
local currentlyOutOfProximity = {} :: {[Player]: {Player}}
local warrantIteration = false
local enabled = true

local writeToClient = BufferUtils.writeToClientSimplified
local readFromClient = BufferUtils.readFromClientSimplified
if Config.makeRagdollFriendly then
	readFromClient = BufferUtils.readFromClient
	writeToClient = BufferUtils.writeToClient
end

-------------------

local function getIdentifier(player: Player)
	local potentialId = 1

	for i = 1, 255 do
		local taken = false
		for _, id in identifiers do
			if id == i then
				taken = true
				break
			end
		end

		if not taken then
			potentialId = i
			break
		end
	end
	identifiers[player] = potentialId
	
	RegisterIdentifier:FireAllClients(BufferUtils.writeRegisterIdentifier(player.Name, potentialId))
end
GetRegistry.OnServerInvoke = function()
	local t = {}
	for player, id in identifiers do
		t[id] = player
	end
	return t
end

Players.PlayerAdded:Connect(function(player: Player)
	getIdentifier(player)
	currentlyOutOfProximity[player] = {}
	
	player.CharacterAdded:Connect(function(char: Model)
		local scr = script.UpdatePosition:Clone()
		scr.Parent = char
	end)
end)
Players.PlayerRemoving:Connect(function(player: Player)
	positionTable[player] = nil
	identifiers[player] = nil
end)


--
FromClient.OnServerEvent:Connect(function(player, b: buffer)
	local data = readFromClient(b)
	
	if random:NextNumber() <= Config.packetLossRate then
		warn("simulated loss for", player)
		return
	end
	
	-- your sanity checks here
	-- make sure to at least implement protection against remote spams
	
	positionTable[player] = data.c
	if not enabled then return end
	
	warrantIteration = true
	
	local outOfProximity = currentlyOutOfProximity[player]
	for _, receiver in Players:GetPlayers() do
		if receiver == player or table.find(outOfProximity, receiver) then
			continue
		end

		ToClient:FireClient(receiver, writeToClient(data.t, identifiers[player], data.c))
	end
end)

local function proximityClock(ht)
	if not warrantIteration then return end
	
	for _, receiver in Players:GetPlayers() do
		local updateMap = {}
		
		local newOutOfProximity = {}
		local proximityUpdate = false
		
		local receiverCframe = positionTable[receiver]
		if not receiverCframe then continue end
		
		for subject, cframe in positionTable do
			if subject == receiver then continue end
			
			local isInProximity = (receiverCframe.Position - cframe.Position).Magnitude <= Config.proximityThreshold
			local outOfProximityIndex = table.find(
				currentlyOutOfProximity[receiver], 
				subject
			)
			
			-- i find the implementation below a bit ugly to read, if you have a more elegant solution please let me know!
			if outOfProximityIndex then
				if isInProximity then
					table.remove(
						currentlyOutOfProximity[receiver], 
						outOfProximityIndex
					)
				else
					continue
				end
			elseif not outOfProximityIndex and not isInProximity then
				table.insert(
					currentlyOutOfProximity[receiver], 
					subject
				)
				table.insert(
					newOutOfProximity,
					identifiers[subject]
				)
				
				proximityUpdate = true
			end
		end
		if proximityUpdate then
			OutOfProximity:FireClient(receiver, BufferUtils.writeOutOfProximityArray(newOutOfProximity))
		end
	end
	warrantIteration = false
end
Utils.FrequencyHeartbeat(proximityClock, 1/Config.tickRate)

function UptodatePositions.getCFrame(player: Player): CFrame
	return positionTable[player]
end

function UptodatePositions.toggle(v: boolean)
	enabled = v
end

return UptodatePositions