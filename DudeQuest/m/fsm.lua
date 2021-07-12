local function new(owner, current_state)
   local machine = {}
   local next_state = current_state

   function machine.enter_state(new_state)
      next_state = new_state
   end

   function machine.update(dt)
      if next_state ~= current_state then
         if current_state.on_exit then
            current_state.on_exit(next_state, owner)
         end
         if next_state.on_enter then
            next_state.on_enter(current_state, owner)
         end
         current_state = next_state
      end

      if current_state.update then
         current_state.update(dt, owner)
      end
   end -- update

   return machine
end -- new

-- export
return {
   new = new,
}
