❗ Even though BetterReplication performs stable and is considered ready for production, a refactor will be needed to clean up the codebase a bit.
I appreciate any PR's to help along the way!

https://devforum.roblox.com/t/betterreplication-vastly-improve-your-combat-experience-by-fighting-lag/3260027?u=baukeblox12
### This read me is copied from the .luau readme file. Will format this properly soon  
> 15/02/2025: V6 BetterReplication has moved away from ByteNet and now has its own buffer reader and writer!
- new config option; makeRagdollFriendly. Replicates the player's entire CFrame orientation instead of solely its yaw.
Results in higher bandwidth consumption however. It is recommended to not enable this setting when its not directly necessary.
More elaboration on this config option soon.
                                                                                              
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
