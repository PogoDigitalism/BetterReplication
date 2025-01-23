--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ReplicationPackets = require(ReplicatedStorage.BetterReplication.Lib.ByteNet.Namespaces.ReplicationPackets)
local GetRegistry = ReplicatedStorage.BetterReplication.GetRegistry
local Utils = require(ReplicatedStorage.BetterReplication.Lib.Utils)
local Config =require(ReplicatedStorage.BetterReplication.Config)

local random = Random.new(tick())

type playerIdentifier = number

local UptodatePositions = {}
local positionTable = {} :: {[Player]: CFrame} -- table for getting latest position data
local identifiers = {} :: {[Player]: playerIdentifier}
local scheduledUpdates = {} :: {[Player]: CFrame}-- high frequency position update table
local currentlyOutOfProximity = {} :: {[Player]: {Player}}
local targets = false
local enabled = true

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
	
	ReplicationPackets.RegisterPlayerIdentifer.sendToAll({
			id = potentialId,
		player = player.Name
	})
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

ReplicationPackets.ReplicatePosition.listen(function(data, player)
	if random:NextNumber() <= Config.packetLossRate then
		warn("simulated loss for", player)
		return
	end
	
	positionTable[player] = data
	scheduledUpdates[player] = data
	
	targets = true
end)

local function clock(ht)
	if not enabled or not targets then return end
	
	for _, receiver in Players:GetPlayers() do
		local updateMap = {}
		local subjectTargets = false
		
		local newOutOfProximity = {}
		local proximityUpdate = false
		
		local receiverCframe = positionTable[receiver]
		for subject, cframe in scheduledUpdates do
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
				table.insert(newOutOfProximity, 
					
					identifiers[subject]
				)
				
				proximityUpdate = true
				continue
			end
		
			subjectTargets = true
			updateMap[identifiers[subject]] = cframe
		end
		if proximityUpdate then
			ReplicationPackets.OutOfProximity.sendTo(newOutOfProximity, receiver)
		end
		if subjectTargets then
			ReplicationPackets.GetReplicatedPosition.sendTo({
				t = os.clock(),
				m = updateMap
			}, receiver)
		end
	end
	
	-- flush scheduledUpdates
	targets = false
	table.clear(scheduledUpdates)
end
Utils.FrequencyHeartbeat(clock, 1/Config.tickRate)

function UptodatePositions.getCFrame(player: Player): CFrame
	return positionTable[player]
end

function UptodatePositions.toggle(v: boolean)
	enabled = v
end

return UptodatePositions