local utils = require("scripts.shared.utils")

local play_flipbook = gui.play_flipbook
local sign = utils.sign
local min = math.min
local max = math.max
local modf = math.modf

local function new (counter)
	counter.delta_value = 0

	function counter:set (value)
		value = self.value_transformer and self.value_transformer:transform(value) or value
		local base = #self.images
		local index = #self.nodes
		while index > 0 do
			play_flipbook(self.nodes[index], self.images[(value % base) + 1])
			value = (value - value % base) / base
			index = index - 1
		end
	end

	function counter:update(new_value, dt)
		if self.current_value ~= new_value then
			self.delta_value = self.delta_value + self.change_speed * dt
			if self.delta_value < 1 then
				return
			end

			local integral, fractional = modf(self.delta_value)
			local next_value = sign(new_value - self.current_value) > 0
			and min(self.current_value + integral, new_value)
			or max(self.current_value - integral, new_value)
			-- print(next_value)
			if self.current_value ~= next_value then
				self:set(next_value)
				self.current_value = next_value
				self.delta_value = fractional
			end
		else
			self.delta_value = 0
		end
	end

	counter:set(counter.current_value)
	return counter
end

return {
	new = new,
}
