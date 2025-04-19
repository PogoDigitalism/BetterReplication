-- _______  _______  _______  _______              _______  _______              _______  _______  _______ 
--(  ____ )(  ___  )(  ____ \(  ___  )   |\     /|(  ___  )(  ____ \   |\     /|(  ____ \(  ____ )(  ____ \
--| (    )|| (   ) || (    \/| (   ) |   | )   ( || (   ) || (    \/   | )   ( || (    \/| (    )|| (    \/
--| (____)|| |   | || |      | |   | |   | | _ | || (___) || (_____    | (___) || (__    | (____)|| (__    
--|  _____)| |   | || | ____ | |   | |   | |( )| ||  ___  |(_____  )   |  ___  ||  __)   |     __)|  __)   
--| (      | |   | || | \_  )| |   | |   | || || || (   ) |      ) |   | (   ) || (      | (\ (   | (      
--| )      | (___) || (___) || (___) |   | () () || )   ( |/\____) |   | )   ( || (____/\| ) \ \__| (____/\
--|/       (_______)(_______)(_______)   (_______)|/     \|\_______)   |/     \|(_______/|/   \__/(_______/

-- BetterReplication version 7 (V7.0)

--Hi there! Here is a small readme of how to implement this replication system!
-- Have a look at the Example folder on a very basic set-up for BetterReplication. The method documentation below should
-- already provide a good overview of all the functionalities!

-- ⭐ For more advanced users; 
-- > You can configure the position and orientation speed to your likings in the Config module 
-- > You can get the accurate position data on the server by using the getCFrame method (on both the server and client)

-- and thats it! Enjoy! Please feel free to add me on Discord; @PogoDigitalism to ask me any questions or report bugs!

-- update LOG:
--[[ 
> 18/04/2025: Finally a new update! V7 has now released with a refactor! BetterReplication is no longer a plug-and-play based model but a proper framework instead!

> 15/02/2025: V6 BetterReplication has moved away from ByteNet and now has its own buffer reader and writer!
- new config option; makeRagdollFriendly. Replicates the player's entire CFrame orientation instead of solely its yaw.
Results in higher bandwidth consumption however. It is recommended to not enable this setting when its not directly necessary.
More elaboration on this config option soon.
- V6.1; reduced replication packet size by 40%!

> 30/01/2025: V5 contains some back-end changes that should make replication much more reliable.
- For the advanced users under us; clients now forward their own ticks instead of the server doing this for them. 
In V4; BetterReplication assumed the same tick for every client (as it forwarded the position cache in bulk at 20hz). This
is not the proper way to do it as receiving the tick information from the original client is the most accurate. This does mean an
increase of 4 bytes (f32) per packet (but also less overhead at the same time as we dont use a ByteNet map anymore). 
- The position forwarder on the client has been reduced from 30hz to 20hz, reduced send and recv for the same result!

> 23/01/2025: Late happy new year! V4 contains huge improvements and a big refactor. 
- BetterReplication now supports a replication buffer this makes BetterReplication much more compatible with production-ready scenarios!
- Proximity based replication has also been added! You can easily configure this and decide on how much bandwith you wish to save.
(Notice that swapping in-and-outside of the replication zone causes jitters as the Roblox replication buffer will take over.)
(Make sure therefore that it is not intrusive to the gameplay when people enter and leave this proximity.)
- Easier configurations

> 24/11/2024: added easier PlayerPositionsHandler configurations, finetuned and fixed vertical position updates!

> 18/11/2024: fixed buggy player collisions, large networking improvements and R6 incorrect position fix!
]]

local RunService = game:GetService("RunService")
local PositionCache = require(script.Client.PositionCache)
local BufferUtils = require(script.Lib.BufferUtils)

local module = {}

if RunService:IsServer() then
	local ServerHandler = require(script.Server.ReplicationHandler)
	
	module.start = ServerHandler.start
	module.bindSanityCheck = ServerHandler.bindSanityCheck
	module.toggle = ServerHandler.toggle
	module.getCFrame = ServerHandler.getCFrame
	
elseif RunService:IsClient() then
	local InterpolationHandler = require(script.Client.InterpolationHandler)
	local ReplicationHandler = require(script.Client.ReplicationHandler)
	
	module.startReplication = ReplicationHandler.start
	module.setCharacter = ReplicationHandler.setCharacter
	module.startInterpolater = InterpolationHandler.start
	
	module.toggle = InterpolationHandler.toggle
	module.continue = InterpolationHandler.continue
	module.pause = InterpolationHandler.pause
	
	module.getCFrame = function(player: Player): CFrame
		return PositionCache[player]
	end
end

return module :: {
	start: typeof(
		--[[
		Initialize and start the replication handler
		
		@contexts server
		]]
		function()end
	),
	bindSanityCheck: typeof(
		--[[
		Add a sanity checker callback function to sanity check incoming client input
		
		@contexts server
		
		@param func - a callback function that should return true if the data is valid, if not then return false to ignore the replication packet
		- data.t = the client tick
		- data.c = the CFrame passed by the client
		]]
		function(func: (data: BufferUtils.from_client_packet) -> boolean)end
	),
	toggle: typeof(
		--[[
		server: Toggle the replication handler on/off
		client: Toggle the interpolation handler on/off
		
		@contexts server, client
		
		@param state - true if on, false if off
		]]
		function(state: boolean)end
	),
	getCFrame: typeof(
		--[[
		server: Get the latest non-interpolated CFrame snapshot of a player (will be changed to interpolated in the future for accurate interpolated hitboxes support)
		client: Get the latest non-interpolated CFrame snapshot of a player
		
		@contexts server, client
		
		@param player - a Player object
		
		@return a CFrame
		]]
		function(player: Player): CFrame end
	),

	startReplication: typeof(
		--[[
		Starts the client -> server position replication.
		Requires a player Character to allow start. The replication handler will manage character respawns.
		
		@help recommended to use this in StarterCharacterScripts script
		
		@contexts client
		]]
		function()end
	),

	setCharacter: typeof(
		--[[
		Optional method to manually set the character object (assuming it has a HumanoidRootPart) for the client -> server replication handler.
		Requires a player Character to allow start. The replication handler will manage character respawns.
		
		@contexts client
		
		@param character - a Player's Character
		]]
		function(character: typeof(script.Rig))end
	),

	startInterpolater: typeof(
		--[[
		Starts the server -> client positions interpolater.
		
		@help recommended to use this in StarterPlayerScripts script
		
		@contexts client
		]]
		function()end
	),
	continue: typeof(
		--[[
		Continues the server -> client positions interpolater.
		
		@contexts client
		]]
		function()end
	),
	pause: typeof(
		--[[
		Pauses the server -> client positions interpolater. The client will still receive the latest data and capture the snapshots, just not interpolate.
		
		@contexts client
		]]
		function()end
	),
}
