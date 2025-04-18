--[[
	A shout-out to @Mephistopheles for 
	their implementation of the replication buffer.
]]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local BetterReplication = script.Parent.Parent

local localPlayer = Players.LocalPlayer

local GetRegistry = BetterReplication.Remotes.GetRegistry
local PositionCache = require(BetterReplication.Client.PositionCache)
local Config = require(BetterReplication.Config)
local RunServiceUtils = require(BetterReplication.Lib.Utils)
local Snapshots = require(BetterReplication.Lib.Snapshots)
local BufferUtils = require(BetterReplication.Lib.BufferUtils)

local FromClient = BetterReplication.Remotes.FromClient
local ToClient = BetterReplication.Remotes.ToClient
local RegisterIdentifier = BetterReplication.Remotes.RegisterIdentifier
local OutOfProximity = BetterReplication.Remotes.OutOfProximity

local runserviceConnection: RBXScriptConnection
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

local function handleIdentifierRegistry(b: buffer)
	local data = BufferUtils.readRegisterIdentifier(b)

	local player: Player = Players:FindFirstChild(data.p)
	registeredIdentifiers[data.id] = player
end

-- associate identifer with player object and push the new cframe
local function handleReplication(b: buffer)
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
end

local function handleProximities(b: buffer)
	local data = BufferUtils.readOutOfProximityArray(b)

	for _, identifier: number in data do
		local player = registeredIdentifiers[identifier]
		if player then
			inProximity[player] = false
		end
	end
end

local function interpolate(dt)
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
end

local function setUp(player: Player)
	inProximity[player] = false
	renderCache[player] = {
		renderAt = nil,
		lastClockAt = 0,
		lastClockDuration = 0
	}
	Snapshots.registerPlayer(player)
end

local module = {}

local started = false
function module.start()
	if started then warn(script:GetFullName(),"| BetterReplication already started!") return end
	
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
	
	RegisterIdentifier.OnClientEvent:Connect(handleIdentifierRegistry)
	registeredIdentifiers = GetRegistry:InvokeServer()
	
	OutOfProximity.OnClientEvent:Connect(handleProximities)
	ToClient.OnClientEvent:Connect(handleReplication)
	runserviceConnection = RunService.PreSimulation:Connect(interpolate)
	
	started = true
end

function module.toggle(v: boolean)
	if not started then
		error(script:GetFullName(),"| Start BetterReplication first using the .start() method!")
	end
	if v then
		if not runserviceConnection then
			runserviceConnection = RunService.PreSimulation:Connect(interpolate)
		else
			warn(script:GetFullName(),"| A BetterReplication connection is already active.")
		end
	else
		if runserviceConnection then
			runserviceConnection:Disconnect()
			runserviceConnection = nil
		else
			warn(script:GetFullName(),"| There is no BetterReplication connection active.")
		end
	end
end

function module.continue()
	module.toggle(true)
end

function module.pause()
	module.toggle(false)
end

return module