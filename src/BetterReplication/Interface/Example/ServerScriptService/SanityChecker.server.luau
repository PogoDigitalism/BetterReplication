local BetterReplication = require(game.ReplicatedStorage.BetterReplication.Interface)

BetterReplication.start()
BetterReplication.bindSanityCheck(function(data)
	print(data.t, data.c)
	return true
end)