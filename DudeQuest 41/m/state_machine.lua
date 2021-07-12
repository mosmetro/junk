local function new(current_state)
   local machine = {}
   local previous_state

   function machine.enter_state(new_state)
      if (not new_state) or (current_state == new_state) then
         return
      end

      if current_state and current_state.on_exit then
         current_state.on_exit(new_state)
      end

      if new_state.on_enter then
         new_state.on_enter(current_state)
      end

      previous_state = current_state
      current_state = new_state
   end -- enter_state

   function machine.revert_to_previous_state()
      machine.enter_state(previous_state)
   end -- revert_to_previous_state

   function machine.update(dt)
      if current_state.update then
         current_state.update(dt, previous_state)
      end
   end -- update

   function machine.reset()
      current_state = nil
   end

   function machine.previous_state()
      return previous_state
   end

   function machine.current_state()
      return current_state
   end

   return machine
end -- new

-- export
return {
   new = new,
}
