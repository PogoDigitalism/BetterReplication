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

local writef16, readf16

do
	local EXPONENT_BIAS = 14

	local SIGN_OFFSET = 2 ^ 15
	local EXPONENT_OFFSET = 2 ^ 10
	local MANTISSA_OFFSET = 2 ^ 10

	local MANTISSA_RANGE = 2 ^ 11
	local SUBNORMAL_RANGE = MANTISSA_RANGE // 2

	-- https://en.wikipedia.org/wiki/Half-precision_floating-point_format#Precision_limitations
	local INTERVAL_BIAS = 10

	local FLOAT16_MAX = 0b1111111_111100000

	function writef16(b: buffer, offset: number, value: number)
		if value > FLOAT16_MAX then
			buffer.writeu16(b, offset, 0b0_11111_0000000000)
		elseif value < -FLOAT16_MAX then
			buffer.writeu16(b, offset, 0b1_11111_0000000000)
		elseif value ~= value then
			buffer.writeu16(b, offset, 0b1_11111_0000000001)
		elseif value == 0 then
			buffer.writeu16(b, offset, 0)
		else
			local absoluteValue = math.abs(value)

			local interval = 2 ^ ( math.floor(math.log(absoluteValue, 2)) - INTERVAL_BIAS )
			local representableValue = math.floor(absoluteValue / interval) * interval

			local fraction, unbiasedExponent = math.frexp(representableValue)
			local exponent = unbiasedExponent + EXPONENT_BIAS

			local mantissa = if exponent <= 0
				then fraction * SUBNORMAL_RANGE / 2 ^ math.abs(exponent)
				else fraction * MANTISSA_RANGE

			local floatRepresentation =
				  math.round(mantissa) % MANTISSA_OFFSET
				+ math.max(exponent, 0) * EXPONENT_OFFSET
				+ if value < 0 then SIGN_OFFSET else 0

			buffer.writeu16(b, offset, floatRepresentation)
		end
	end

	function readf16(b: buffer, offset: number): number
		local uintForm = buffer.readu16(b, offset)

		local isSigned = uintForm // SIGN_OFFSET == 1
		local signlessRepresentation = uintForm % SIGN_OFFSET

		if signlessRepresentation == 0b11111_0000000000 then
			return if isSigned then -math.huge else math.huge
		elseif signlessRepresentation == 0b11111_0000000001 then
			return 0 / 0
		elseif signlessRepresentation == 0b00000_0000000000 then
			return 0
		else
			local mantissa = signlessRepresentation % MANTISSA_OFFSET
			local exponent = signlessRepresentation // MANTISSA_OFFSET

			local fraction = if exponent == 0
				then mantissa / SUBNORMAL_RANGE
				else mantissa / MANTISSA_RANGE + 0.5

			local value = math.ldexp(fraction, exponent - EXPONENT_BIAS)
			return if isSigned then -value else value
		end
	end
end

local function writei24(b: buffer, offset: number, value: number)
	local uint = (value + 0x1000000) % 0x1000000
	buffer.writeu8(b, offset, uint)
	buffer.writeu16(b, offset + 1, uint // 0x100)
end

local function readi24(b: buffer, offset: number): number
	local uint = buffer.readu8(b, offset) + buffer.readu16(b, offset + 1) * 0x100
	return (uint + 0x800000) % 0x1000000 - 0x800000
end

local function writeCFrame(b: buffer, cframe: CFrame): buffer
	local oldBlen = buffer.len(b)

	local newB = buffer.create(oldBlen + 15)
	buffer.copy(newB, 0, b)

	local x, y, z = cframe.X, cframe.Y, cframe.Z

	writei24(newB, oldBlen + 0, x*128)
	writei24(newB, oldBlen + 3, y*128)
	writei24(newB, oldBlen + 6, z*128)

	local axis, angle = cframe:ToAxisAngle()
	axis *= angle

	writef16(newB, oldBlen + 9, axis.X)
	writef16(newB, oldBlen + 11, axis.Y)
	writef16(newB, oldBlen + 13, axis.Z)

	return newB
end

local function readCFrame(b: buffer, cursor: number): CFrame
	local position = Vector3.new(
		readi24(b, cursor + 0)/128,
		readi24(b, cursor + 3)/128,
		readi24(b, cursor + 6)/128
	)

	local axisAngle = Vector3.new(
		readf16(b, cursor + 9),
		readf16(b, cursor + 11),
		readf16(b, cursor + 13)
	)
	local angle = axisAngle.Magnitude

	return if angle ~= 0
		then CFrame.fromAxisAngle(axisAngle, angle) + position
		else CFrame.new(position)
end

local function writeSimpleCFrame(b: buffer, cframe: CFrame): buffer
	local oldBlen = buffer.len(b)

	local newB = buffer.create(oldBlen + 11)
	buffer.copy(newB, 0, b)

	local x, y, z = cframe.X, cframe.Y, cframe.Z
	local _, ry, _ = cframe:ToEulerAnglesYXZ()

	writei24(newB, oldBlen + 0, x*128)
	writei24(newB, oldBlen + 3, y*128)
	writei24(newB, oldBlen + 6, z*128)
	writef16(newB, oldBlen + 9, ry)

	return newB
end

local function readSimpleCFrame(b: buffer, cursor: number): CFrame
	local x = readi24(b, cursor + 0)/128
	local y = readi24(b, cursor + 3)/128
	local z = readi24(b, cursor + 6)/128

	local ry = readf16(b, cursor + 9)

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
