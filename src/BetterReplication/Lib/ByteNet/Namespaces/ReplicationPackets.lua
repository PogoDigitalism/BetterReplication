local ByteNet = require(script.Parent.Parent.ByteNet)

return ByteNet.defineNamespace("Replication", function()
	return {
		ReplicatePosition = ByteNet.definePacket({
			value =  ByteNet.simplecframe,
			reliabilityType = "unreliable"
		}),
		
		OutOfProximity = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.playerIdentifier)
		}),
		
		GetReplicatedPosition = ByteNet.definePacket({
			value = ByteNet.struct({
				t = ByteNet.float32,
				m = ByteNet.map(ByteNet.playerIdentifier, ByteNet.simplecframe),
			}),
			reliabilityType = "unreliable"
		}),
		
		RegisterPlayerIdentifer = ByteNet.definePacket({
			value = ByteNet.struct({
				player = ByteNet.playerName,
				id = ByteNet.playerIdentifier
			})
		})
	}
end)