local BufferUtils = {}

type from_client_packet = {
	t: number,
	c: CFrame
}
type to_client_packet = {
	t: number,
	p: number,
	c: CFrame
}
type register_identifier = {
	p: string,
	id: number
}

local function writeCFrame(b: buffer, cframe: CFrame): buffer
	local oldBlen = buffer.len(b)
	
	local newB = buffer.create(oldBlen + 24)
	buffer.copy(b, 0, newB)
	
	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local rx, ry, rz = cframe:ToEulerAnglesYXZ()

	buffer.writef32(newB, oldBlen + 0, x)
	buffer.writef32(newB, oldBlen + 4, y)
	buffer.writef32(newB, oldBlen + 8, z)
	buffer.writef32(newB, oldBlen + 12, rx)
	buffer.writef32(newB, oldBlen + 16, ry)
	buffer.writef32(newB, oldBlen + 20, rz)
	
	return newB
end

local function readCFrame(b: buffer, cursor: number): CFrame
	local x = buffer.readf32(b, cursor + 0)
	local y = buffer.readf32(b, cursor + 4)
	local z = buffer.readf32(b, cursor + 8)
	local rx = buffer.readf32(b, cursor + 12)
	local ry = buffer.readf32(b, cursor + 16)
	local rz = buffer.readf32(b, cursor + 20)

	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
end

local function writeSimpleCFrame(b: buffer, cframe: CFrame): buffer
	local oldBlen = buffer.len(b)
	
	local newB = buffer.create(oldBlen + 16)
	buffer.copy(newB, 0, b)

	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local rx, ry, rz = cframe:ToEulerAnglesYXZ()

	buffer.writef32(newB, oldBlen + 0, x)
	buffer.writef32(newB, oldBlen + 4, y)
	buffer.writef32(newB, oldBlen + 8, z)
	buffer.writef32(newB, oldBlen + 12, ry)
	
	return newB
end

local function readSimpleCFrame(b: buffer, cursor: number): CFrame
	local x = buffer.readf32(b, cursor + 0)
	local y = buffer.readf32(b, cursor + 4)
	local z = buffer.readf32(b, cursor + 8)
	local ry = buffer.readf32(b, cursor + 12)

	return CFrame.new(x, y, z) * CFrame.Angles(0, ry, 0)
end

local function writeOutOfProximityArray(arr: {number}): buffer
	local b = buffer.create(#arr)
	
	for i = 0, #arr-1 do
		buffer.writeu8(b, i, arr[i+1])
	end
	return b
end

local function readOutOfProximityArray(b:  buffer): {number}
	local itrs = buffer.len(b)-1
	
	local arr = {}
	for i = 0, itrs do
		table.insert(
			arr,
			buffer.readu8(b, i)
		)
	end
	return arr
end

local function readFromClient(b: buffer): from_client_packet
	local t = buffer.readf32(b, 0)
	local c = readCFrame(b, 4)
	
	return {t = t, c = c}
end

local function readFromClientSimplified(b: buffer): from_client_packet
	local t = buffer.readf32(b, 0)
	local c = readSimpleCFrame(b, 4)

	return {t = t, c = c}
end

local function writeFromClientSimplified(t: number, cframe: CFrame): buffer
	local b = buffer.create(4)
	buffer.writef32(b, 0, t)

	return writeSimpleCFrame(b, cframe)
end

local function writeFromClient(t: number, cframe: CFrame): buffer
	local b = buffer.create(4)
	buffer.writef32(b, 0, t)
	
	return writeCFrame(b, cframe)
end

local function readToClientSimplified(b: buffer): to_client_packet
	local t = buffer.readf32(b, 0)
	local p = buffer.readu8(b, 4)
	local c = readSimpleCFrame(b, 5)

	return {t = t, p = p, c = c}
end

local function writeToClientSimplified(t: number, p: number, cframe: CFrame): buffer
	local b = buffer.create(4 + 1)
	buffer.writef32(b, 0, t)
	buffer.writeu8(b, 4, p)

	return writeSimpleCFrame(b, cframe)
end

local function readToClient(b: buffer): to_client_packet
	local t = buffer.readf32(b, 0)
	local p = buffer.readu8(b, 4)
	local c = readCFrame(b, 5)

	return {t = t, p = p, c = c}
end

local function writeToClient(t: number, p: number, cframe: CFrame): buffer
	local b = buffer.create(4 + 1)
	buffer.writef32(b, 0, t)
	buffer.writeu8(b, 4, p)

	return writeCFrame(b, cframe)
end

local function readRegisterIdentifier(b: buffer): register_identifier
	local id = buffer.readu8(b, 0)
	local p = buffer.readstring(b, 1, buffer.len(b) - 1)
	
	return {p = p, id = id}
end

local function writeRegisterIdentifier(p: string, id: number): buffer
	local pLen = string.len(p)
	local b = buffer.create(1 + pLen)
	
	buffer.writeu8(b, 0, id)
	buffer.writestring(b, 1, p)
	
	return b
end

return {
	writeToClient = writeToClient,
	writeToClientSimplified = writeToClientSimplified,
	readToClient = readToClient,
	readToClientSimplified = readToClientSimplified,
	
	writeFromClient = writeFromClient,
	writeFromClientSimplified = writeFromClientSimplified,
	readFromClient = readFromClient,
	readFromClientSimplified = readFromClientSimplified,
	
	readRegisterIdentifier = readRegisterIdentifier,
	writeRegisterIdentifier = writeRegisterIdentifier,
	
	writeOutOfProximityArray = writeOutOfProximityArray,
	readOutOfProximityArray = readOutOfProximityArray,
}
