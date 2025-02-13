-- Thanks Tazmondo for this util suggestion
local RunService = game:GetService('RunService')

local Utils = {}

function Utils.FrequencyHeartbeat(callback: (number) -> (), frequency: number)
	local last = time()
	frequency = 1/frequency
	return RunService.Heartbeat:Connect(function()
		local dt = time() - last
		if dt < frequency then
			return
		end
		last = time()
		callback(dt)
	end)
end

function Utils.PreRender(callback: (number) -> (), frequency: number)
	local last = time()
	frequency = 1/frequency
	return RunService.PreRender:Connect(function()
		local dt = time() - last
		if dt < frequency then
			return
		end
		last = time()
		callback(dt)
	end)
end

@native
function Utils.BinarySearch(Array, Value)
	local Low = 1
	local High = #Array

	while Low <= High do
		local Middle = Low + math.floor((High - Low) / 2)
		local MiddleValue = Array[Middle]

		if Value < MiddleValue then
			High = Middle - 1
		elseif MiddleValue < Value then
			Low = Middle + 1
		else
			while Middle >= 1 and not (Array[Middle] < Value or Value < Array[Middle]) do
				Middle -= 1
			end

			return Middle + 1
		end
	end

	return nil
end

return Utils