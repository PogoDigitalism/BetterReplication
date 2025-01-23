--[[
	A very big shout-out to @Mephistopheles for 
	their implementation of the replication buffer. 
	Thanks to them BetterReplication has it now implemented as well.
]]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local localPlayer = Players.LocalPlayer

local ReplicationPackets = require(ReplicatedStorage.BetterReplication.Lib.ByteNet.Namespaces.ReplicationPackets)
local GetRegistry = ReplicatedStorage.BetterReplication.GetRegistry
local PositionCache = require(ReplicatedStorage.BetterReplication.Client.PositionCache)
local Config = require(ReplicatedStorage.BetterReplication.Config)
local RunServiceUtils = require(ReplicatedStorage.BetterReplication.Lib.Utils)
local Snapshots = require(ReplicatedStorage.BetterReplication.Lib.Snapshots)

local registeredIdentifiers = {} :: {[number]: Player}
local inProximity = {} :: {[Player]: boolean}
local renderAt = {} :: {[Player]: number}

local lastClockDuration = 0
local lastClockAt = 0

ReplicationPackets.RegisterPlayerIdentifer.listen(function(data)
	local player: Player = Players:FindFirstChild(data.player)
	registeredIdentifiers[data.id] = player
end)

-- associate identifer with player object and push the new cframe
ReplicationPackets.GetReplicatedPosition.listen(function(data)
	local currentClock = data.t
	if currentClock > lastClockAt then
		lastClockDuration = os.clock()
		lastClockAt = currentClock
	else
		return
	end
	
	for identifier: number, cframe: CFrame in data.m do
		local player = registeredIdentifiers[identifier]
		if player and player.Character then
			if not renderAt[player] then
				renderAt[player] = currentClock - Config.interpolationDelay
			end
			inProximity[player] = true
			
			local snapshots = Snapshots.getSnapshotInstance(player)
			snapshots:pushAt(currentClock, cframe)
			PositionCache[player] = cframe
		end
	end
end)

ReplicationPackets.OutOfProximity.listen(function(data)
	for _, identifier: number in data do
		local player = registeredIdentifiers[identifier]
		if player then
			inProximity[player] = false
		end
	end
end)

RunService.PreSimulation:Connect(function(dt)
	local stagedPlayers = {}
	local stagedResults = {}
	
	for player, isIn in inProximity do
		if not isIn or player == localPlayer then
			continue
		end
		
		local estimatedServerTime = lastClockAt + (os.clock() - lastClockDuration)
		
		local clientRenderAt = renderAt[player]
		clientRenderAt += dt

		local renderTimeError = Config.interpolationDelay - (estimatedServerTime - clientRenderAt)
		if math.abs(renderTimeError) > .1 then
			clientRenderAt = estimatedServerTime - Config.interpolationDelay
		elseif renderTimeError > .01 then
			clientRenderAt = math.max(estimatedServerTime - Config.interpolationDelay, clientRenderAt - .1 * dt)
		elseif renderTimeError < -.01 then
			clientRenderAt = math.min(estimatedServerTime - Config.interpolationDelay, clientRenderAt + .1 * dt)
		end
		
		renderAt[player] = clientRenderAt
		local snapshot = Snapshots.getSnapshotInstance(player)
		local res = snapshot:getAt(clientRenderAt)
		
		if res then
			table.insert(
				stagedPlayers,
				player.Character.HumanoidRootPart
			)
			table.insert(
				stagedResults,
				res
			)
		end
	end
	workspace:BulkMoveTo(stagedPlayers, stagedResults, Enum.BulkMoveMode.FireAllEvents)
end)

Players.PlayerAdded:Connect(function(player: Player)
	inProximity[player] = false
	Snapshots.registerPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	inProximity[player] = nil
	Snapshots.deregisterPlayer(player)
	
	for id, other in registeredIdentifiers do
		if other == player then
			registeredIdentifiers[id] = nil
			break
		end
	end
end)
registeredIdentifiers = GetRegistry:InvokeServer()