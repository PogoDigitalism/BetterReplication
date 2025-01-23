local bufferWriter = require(script.Parent.Parent.process.bufferWriter)
local types = require(script.Parent.Parent.types)

local f32NoAlloc = bufferWriter.f32NoAlloc
local alloc = bufferWriter.alloc

local simplecframe = {
	read = function(b: buffer, cursor: number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)
		local ry = buffer.readf32(b, cursor + 12)
		
		return CFrame.new(x, y, z) * CFrame.Angles(0, ry, 0), 16
	end,
	write = function(value: CFrame)
		local x, y, z = value.X, value.Y, value.Z
		local rx, ry, rz = value:ToEulerAnglesYXZ()
		
		alloc(16)
		f32NoAlloc(x)
		f32NoAlloc(y)
		f32NoAlloc(z)
		f32NoAlloc(ry)
	end,
}

return function(): types.dataTypeInterface<CFrame>
	return simplecframe
end