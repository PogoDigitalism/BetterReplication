local Players = game:GetService('Players')
local BetterReplication = script.Parent.Parent

local Config = require(BetterReplication.Config)
local BufferUtils = require(BetterReplication.Lib.BufferUtils)
local Utils = require(BetterReplication.Lib.Utils)

local FromClient = BetterReplication.Remotes.FromClient

local player = Players.LocalPlayer
local character: Model = nil
local rootpart: Part = nil

local lastCframe = CFrame.new(9999, 9999, 9999)
local angleThreshold = math.rad(0.5)
local positionThreshold = 0.01

local writeFromClient = BufferUtils.writeFromClientSimplified
if Config.makeRagdollFriendly then
	writeFromClient = BufferUtils.writeFromClient
end
local optimize = Config.optimizeInactivity

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
	if not rootpart then return end
	local rootCframe = rootpart.CFrame

	if not optimize or hasSignificantChange(lastCframe, rootCframe) then
		lastCframe = rootCframe

		FromClient:FireServer(writeFromClient(os.clock(), rootCframe))
	end
end

local module = {}
function module.start()
	if not player.Character then
		error("No existing player.Character, can not start the replication handler.")
	end
	
	player.CharacterAdded:Connect(function(char)
		character = char
		
		rootpart = nil
		rootpart = char:WaitForChild("HumanoidRootPart")
	end)
	character = player.Character
	rootpart = character:WaitForChild("HumanoidRootPart")
	
	update()
	Utils.FrequencyPostSimulation(update, 20)
end

function module.setCharacter(char)
	character = char
	rootpart = char.HumanoidRootPart
end

return module