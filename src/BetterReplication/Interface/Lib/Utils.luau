-- Thanks Tazmondo for this util suggestion
local RunService = game:GetService('RunService')

local Utils = {}

function Utils.FrequencyPostSimulation(callback: (number) -> (), frequency: number)
	local last = time()
	frequency = 1/frequency
	return RunService.PostSimulation:Connect(function()
		local dt = time() - last
		if dt < frequency then
			return
		end
		last = time()
		callback(dt)
	end)
end

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

return Utils