local Config = {
	-- from how many studs should players not be replicated with BetterReplication anymore?
	proximityThreshold = 50, 
	
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