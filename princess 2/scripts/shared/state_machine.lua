local function new (owner, current_state)
	local self = {
		owner = owner,
		previous_state = current_state
	}

	function self.enter_state (new_state)
		self.previous_state = current_state
		if current_state.on_exit then
			current_state.on_exit(self)
		end
		current_state = new_state
		if new_state.on_enter then
			new_state.on_enter(self)
		end
	end

	function self.update (dt)
		if current_state.execute then
			current_state.execute(self, dt)
		end
	end

	function self.revert_to_previous_state ()
		self.enter_state(self.previous_state)
	end

	function self.on_message (message_id, message, sender)
		if current_state.on_message then
			current_state.on_message(self, message_id, message, sender)
		end
	end

	self.enter_state(current_state)
	return self
end

return {
	new = new,
}
