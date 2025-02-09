-- Implementation by Pogo. Used for the replication buffer implementation.
--!strict
local clock = os.clock

local Snapshot = {}
Snapshot.__index = Snapshot

type datetime = number
export type Snapshot = {
	-- fields
	_subject: Player?,
	_cache: {
		{
			o: CFrame,
			at: datetime
		}
	},
	
	-- methods
	pushAt: (self: Snapshot, at:number, o: CFrame) -> (),
	getAt: (self: Snapshot, at: number) -> CFrame,
	getBefore: (self: Snapshot, at: number) -> {o: CFrame, at: datetime},
	getAfter: (self: Snapshot, at: number) -> {o: CFrame, at: datetime},
	destroy: (self: Snapshot) -> (),
}

local maxLength = 10

local snapshotInstances = {}
function Snapshot.getSnapshotInstance(player: Player): Snapshot
	return snapshotInstances[player] or Snapshot.registerPlayer(player)
end

function Snapshot.registerPlayer(player: Player): Snapshot
	local snapshot = Snapshot.new(player)
	snapshotInstances[player] = snapshot
	
	return snapshot
end

function Snapshot.deregisterPlayer(player: Player)
	local snapshot = snapshotInstances[player]
	if snapshot then
		snapshotInstances[player] = nil
		snapshot:destroy()
	end
end

function Snapshot.new(subject: Player): Snapshot
	local self = setmetatable({}, Snapshot) :: Snapshot
	
	self._subject = subject
	self._cache = {}
	
	return self
end

function Snapshot.pushAt(self: Snapshot, at, o): ()
	for i = 1, 10 do
		if self._cache[i] then 
			if self._cache[i].at < at then
				table.insert(self._cache, i, {["at"] = at, ["o"] = o})
				break
			end
		else
			self._cache[i] = {["at"] = at, ["o"] = o}
			break
		end
	end

	if #self._cache > 10 then
		table.remove(self._cache, 11)
	end
end

function Snapshot:getBefore(at)
	local closest, distance = nil, 1e9
	for _, snapshot in self._cache do
		local dist = math.abs(snapshot.at - at)
		if snapshot.at < at and dist < distance then
			closest = snapshot
			distance = dist
		end
	end
	return closest
end

function Snapshot:getAfter(at)
	local closest, distance = nil, 1e9
	for _, snapshot in self._cache do
		local dist = math.abs(snapshot.at - at)
		if snapshot.at > at and dist < distance then
			closest = snapshot
			distance = dist
		end
	end
	return closest
end


function Snapshot.getAt(self: Snapshot, at): CFrame?
	if #self._cache == 0 then return nil end
	if #self._cache == 1 then return self._cache[1].o end
	
	local from, to = self:getAfter(at), self:getBefore(at)
	if not (from and to) then
		to = self._cache[1]
		from = self:getAfter(to.at)
		if not (from and to) then
			return nil
		end
	end

	local a = (at - from.at) / (to.at - from.at)
	return from.o:Lerp(to.o, a)
end

function Snapshot.destroy(self: Snapshot): ()
	self._subject = nil
	table.clear(self._cache)
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self :: {})
end

return Snapshot
