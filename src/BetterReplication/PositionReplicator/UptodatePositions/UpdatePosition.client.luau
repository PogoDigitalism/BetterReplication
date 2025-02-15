local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Config = require(ReplicatedStorage.BetterReplication.Config)
local BufferUtils = require(ReplicatedStorage.BetterReplication.Lib.BufferUtils)
local Utils = require(ReplicatedStorage.BetterReplication.Lib.Utils)

local FromClient = ReplicatedStorage.BetterReplication.Remotes.FromClient

local player = Players.LocalPlayer
local character: Model = player.Character
local rootpart: Part = character:WaitForChild('HumanoidRootPart')

local lastCframe = CFrame.new(9999, 9999, 9999)
local angleThreshold = math.rad(0.5)
local positionThreshold = 0.01

local writeFromClient = BufferUtils.writeFromClientSimplified
if Config.makeRagdollFriendly then
	writeFromClient = BufferUtils.writeFromClient
end

local function hasSignificantChange(cframe1, cframe2)
	local positionDelta = (cframe1.Position - cframe2.Position).Magnitude
	if positionDelta > positionThreshold then
		return true
	end

	local x1, y1, z1 = cframe1:ToOrientation()
	local x2, y2, z2 = cframe2:ToOrientation()
	local angleDelta = math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)
	
	return angleDelta > angleThreshold
end

local function update()
	local rootCframe = rootpart.CFrame
	
	if hasSignificantChange(lastCframe, rootCframe) then
		lastCframe = rootCframe
		
		FromClient:FireServer(writeFromClient(os.clock(), rootCframe))
	end
end
update()

Utils.FrequencyPostSimulation(update, 20)