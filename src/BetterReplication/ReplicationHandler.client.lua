--[[
	A shout-out to @Mephistopheles for 
	their implementation of the replication buffer.
]]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local localPlayer = Players.LocalPlayer

local GetRegistry = ReplicatedStorage.BetterReplication.Remotes.GetRegistry
local PositionCache = require(ReplicatedStorage.BetterReplication.Client.PositionCache)
local Config = require(ReplicatedStorage.BetterReplication.Config)
local RunServiceUtils = require(ReplicatedStorage.BetterReplication.Lib.Utils)
local Snapshots = require(ReplicatedStorage.BetterReplication.Lib.Snapshots)
local BufferUtils = require(ReplicatedStorage.BetterReplication.Lib.BufferUtils)

local FromClient = ReplicatedStorage.BetterReplication.Remotes.FromClient
local ToClient = ReplicatedStorage.BetterReplication.Remotes.ToClient
local RegisterIdentifier = ReplicatedStorage.BetterReplication.Remotes.RegisterIdentifier
local OutOfProximity = ReplicatedStorage.BetterReplication.Remotes.OutOfProximity

local registeredIdentifiers = {} :: {[number]: Player}
local inProximity = {} :: {[Player]: boolean}
local renderCache = {} :: {[Player]: {
	renderAt: number,
	lastClockAt: number,
	lastClockDuration: number
}}

local readToClient = BufferUtils.readToClientSimplified
if Config.makeRagdollFriendly then
	readToClient = BufferUtils.readToClient
end

RegisterIdentifier.OnClientEvent:Connect(function(b: buffer)
	local data = BufferUtils.readRegisterIdentifier(b)
	
	local player: Player = Players:FindFirstChild(data.p)
	registeredIdentifiers[data.id] = player
end)

-- associate identifer with player object and push the new cframe
ToClient.OnClientEvent:Connect(function(b: buffer)
	local data = readToClient(b)
	
	local player = registeredIdentifiers[data.p]
	local renderCacheEntry = renderCache[player]

	local currentClock = data.t
	if currentClock > renderCacheEntry.lastClockAt then
		renderCache[player].lastClockDuration = os.clock()
		renderCache[player].lastClockAt = currentClock
	else
		return
	end

	if player and player.Character then
		if not renderCacheEntry.renderAt then
			renderCache[player].renderAt = currentClock - Config.interpolationDelay
		end
		inProximity[player] = true

		local snapshots = Snapshots.getSnapshotInstance(player)
		snapshots:pushAt(currentClock, data.c)
		PositionCache[player] = data.c
	end
end)

OutOfProximity.OnClientEvent:Connect(function(b: buffer)
	local data = BufferUtils.readOutOfProximityArray(b)
	
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
		
		local renderCacheEntry = renderCache[player]
		
		local estimatedServerTime = renderCacheEntry.lastClockAt + (os.clock() - renderCacheEntry.lastClockDuration)
		
		local clientRenderAt = renderCacheEntry.renderAt
		clientRenderAt += dt

		local renderTimeError = Config.interpolationDelay - (estimatedServerTime - clientRenderAt)
		if math.abs(renderTimeError) > .1 then
			clientRenderAt = estimatedServerTime - Config.interpolationDelay
		elseif renderTimeError > .01 then
			clientRenderAt = math.max(estimatedServerTime - Config.interpolationDelay, clientRenderAt - .1 * dt)
		elseif renderTimeError < -.01 then
			clientRenderAt = math.min(estimatedServerTime - Config.interpolationDelay, clientRenderAt + .1 * dt)
		end
		
		renderCache[player].renderAt = clientRenderAt
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

local function setUp(player: Player)
	inProximity[player] = false
	renderCache[player] = {
		renderAt = nil,
		lastClockAt = 0,
		lastClockDuration = 0
	}
	Snapshots.registerPlayer(player)
end

Players.PlayerAdded:Connect(function(player: Player)
	setUp(player)
end)
for _, player in Players:GetPlayers() do
	setUp(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	inProximity[player] = nil
	renderCache[player] = nil
	
	Snapshots.deregisterPlayer(player)
	
	for id, other in registeredIdentifiers do
		if other == player then
			registeredIdentifiers[id] = nil
			break
		end
	end
end)
registeredIdentifiers = GetRegistry:InvokeServer()