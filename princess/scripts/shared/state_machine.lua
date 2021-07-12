local function new(current_state)
	local machine = {}

	function machine.enter_state(new_state)
		local previous_state = current_state
		if current_state.on_exit then
			current_state.on_exit(new_state)
		end
		current_state = new_state
		if new_state.on_enter then
			new_state.on_enter(previous_state)
		end
	end

	function machine.update (dt)
		if current_state.execute then
			current_state.execute(dt)
		end
	end

	-- function self.revert_to_previous_state ()
	-- 	self.enter_state(self.previous_state)
	-- end

	function machine.on_message (message_id, message, sender)
		if current_state.on_message then
			current_state.on_message(machine, message_id, message, sender)
		end
	end

	function machine.stop()
		machine.enter_state = function() end
	end

	machine.enter_state(current_state)
	return machine
end

return {
	new = new,
}
