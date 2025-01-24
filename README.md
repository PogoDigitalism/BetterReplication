https://devforum.roblox.com/t/betterreplication-vastly-improve-your-combat-experience-by-fighting-lag/3260027?u=baukeblox12
### This read me is copied from the .luau readme file. Will format this properly soon                                                                                                
-- BetterReplication version 4 (V4)

--Hi there! Here is a small readme of how to implement this replication system!
-- I recommend to follow the steps below unless you know what you are doing!

--1. put the BetterReplication folder below ReplicatedStorage (so it is a child of ReplicatedStorage and NOT a descendant!)
--2. put the PositionReplicator folder anywhere in ServerScriptService
--3. put the ReplicationHandler localscript anywhere in StarterPlayerScripts

-- and thats it! Enjoy! Please feel free to add me on Discord; @PogoDigitalism to ask me any questions or report bugs!

-- update LOG:
--[[ 
> 23/01/2025: Late happy new year! V3 contains huge improvements and a big refactor. 
- BetterReplication now supports a replication buffer this makes BetterReplication much more compatible with production-ready scenarios!
- Proximity based replication has also been added! You can easily configure this and decide on how much bandwith you wish to save.
(Notice that swapping in-and-outside of the replication zone causes jitters as the Roblox replication buffer will take over.)
(Make sure therefore that it is not intrusive to the gameplay when people enter and leave this proximity.)
- Easier configurations

> 24/11/2024: added easier PlayerPositionsHandler configurations, finetuned and fixed vertical position updates!

> 18/11/2024: fixed buggy player collisions, large networking improvements and R6 incorrect position fix!
]]
