-- _______  _______  _______  _______              _______  _______              _______  _______  _______ 
--(  ____ )(  ___  )(  ____ \(  ___  )   |\     /|(  ___  )(  ____ \   |\     /|(  ____ \(  ____ )(  ____ \
--| (    )|| (   ) || (    \/| (   ) |   | )   ( || (   ) || (    \/   | )   ( || (    \/| (    )|| (    \/
--| (____)|| |   | || |      | |   | |   | | _ | || (___) || (_____    | (___) || (__    | (____)|| (__    
--|  _____)| |   | || | ____ | |   | |   | |( )| ||  ___  |(_____  )   |  ___  ||  __)   |     __)|  __)   
--| (      | |   | || | \_  )| |   | |   | || || || (   ) |      ) |   | (   ) || (      | (\ (   | (      
--| )      | (___) || (___) || (___) |   | () () || )   ( |/\____) |   | )   ( || (____/\| ) \ \__| (____/\
--|/       (_______)(_______)(_______)   (_______)|/     \|\_______)   |/     \|(_______/|/   \__/(_______/
                                                                                                       
-- BetterReplication version 6.1 (V6.1)

--Hi there! Here is a small readme of how to implement this replication system!
-- I recommend to follow the steps below unless you know what you are doing!

--1. put the BetterReplication folder below ReplicatedStorage (so it is a child of ReplicatedStorage and NOT a descendant!)
--2. put the PositionReplicator folder anywhere in ServerScriptService
--3. put the ReplicationHandler localscript anywhere in StarterPlayerScripts


-- ⭐ For more advanced users; 
-- > You can configure the position and orientation speed to your likings in the Config module located under PlayerPositionsHandler 
-- > You can get the accurate position data on the server by using the getCFrame method in UptodatePositions (located under PositionReplicator)

-- and thats it! Enjoy! Please feel free to add me on Discord; @PogoDigitalism to ask me any questions or report bugs!

-- update LOG:
--[[ 
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