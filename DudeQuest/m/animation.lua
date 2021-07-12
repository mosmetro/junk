local set_position = go.set_position
local play_flipbook = sprite.play_flipbook

local play_properties = { offset = 0, playback_rate = 1 }

local function play(target, animation_group, index, on_complete, cursor, rate)
   local animation = animation_group[index or 1]
   if target.current_animation == animation then return end
   play_properties.offset = cursor or 0
   play_properties.playback_rate = rate or 1
   set_position(animation.position, target.anchor)
   play_flipbook(target.sprite, animation.id, on_complete, play_properties)
   target.on_complete = on_complete
   target.current_animation_group = animation_group
   target.current_animation = animation
end -- play_animation

local function new_target()
   return {
      pivot = 0,
      anchor = 0,
      sprite = 0,
      current_animation_group = 0,
      current_animation = 0,
      on_complete = 0,
      previous_horizontal_look = 0,
   }
end -- new_target

return {
   play = play,
   new_target = new_target,
   done_sink = function() end,
}
