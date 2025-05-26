local Config = {
	-- not recommended to change these values at runtime
	
	-- from how many studs should players not be replicated with BetterReplication anymore?
	proximityThreshold = 100, -- default: 100
	
	-- ship the whole cframe orientation instead of only the yaw axis to make the humanoidrootpart interpolate accurately
	-- this setting is only relevant for when the humanoidrootpart doesnt just rotate around its yaw axis (f.e. ragdolls)
	makeRagdollFriendly = false, -- default: false
	
	-- stops the client from sending position data when they do not move
	optimizeInactivity = true, -- default: true
	
	-----------------------
	
	-- emulate packet loss to see how BetterReplication performs
	-- -1 = disabled, <0,1> = a rate (fe.e .5 = 50%)
	packetLossRate = -1,
	
	-- dont touch this part of the config
	-- unless you know what youre doing! :D
	tickRate = 1/20,
	interpolationDelay = 1/10
}

return Config
