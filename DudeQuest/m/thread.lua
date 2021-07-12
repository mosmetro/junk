local utils = require("m.utils")
-- localization
local post = msg.post
local next = next
local create = coroutine.create
local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running
local status = coroutine.status

-- functions
local get_metadata
local new
local delete
local update
local on_message
local wait_for_seconds
local wait_for_frames
local wait_for_condition
local load
local unload
local play_animation

--[[
context_scope = {
context = scope,
context = scope,
...
}
context == script instance (self). in scripts, __dm_script_instance__ == self
]]
local context_scope = {}

--[[ scope - set of pairs coroutine (key) and metadata table (value)
scope = {
co = metadata,
co = metadata,
...
}
]]

function get_metadata (context, co, tag)
   local scope = context_scope[context] or {}
   local metadata = scope[co]
   if not metadata then
      metadata = { ready_to_resume = true, tag = tag or "not set", }
      scope[co] = metadata
      context_scope[context] = scope
   end
   return metadata
end -- get_metadata

function new(context, tag, fn)
   return get_metadata(context, create(fn), tag)
end -- new

function delete (context, metadata)
   local scope = context_scope[context]
   for co, meta in next, scope do
      if meta == metadata then
         scope[co] = nil
         break
      end
   end
end -- delete

function update (context, dt)
   local scope = context_scope[context]
   if not scope or (not next(scope)) then -- if there is no scope or table is empty
      -- utils.log("there is no scope or table is empty", context, runtime.current_frame)
      -- pprint(scope)
      return
   end
   -- pprint(scope)
   -- utils.log("processing", context, runtime.current_frame)
   for co, metadata in next, scope do
      if metadata.condition and metadata.condition(dt) then
         metadata.condition = nil
         metadata.ready_to_resume = true
      end
      if metadata.ready_to_resume then
         -- utils.log("resuming", coroutine.status(co), metadata.tag, runtime.current_frame)
         local success, message = resume(co)
         if not success then
            print(message, metadata.tag)
            -- utils.log(message, metadata.tag)
            scope[co] = nil
         end
         if status(co) == "dead" then
            -- utils.log("dead", metadata.tag, runtime.current_frame)
            scope[co] = nil
         end
      end
   end
end -- update

function on_message (context, message_id, message, sender)
   local scope = context_scope[context]
   if not scope or (not next(scope)) then return end

   for _, metadata in next, scope do
      if metadata.on_message then
         metadata.on_message(message_id, message, sender)
      end
   end
end -- on_message

function wait_for_seconds (context, seconds)
   local metadata = get_metadata(context, running())
   metadata.ready_to_resume = false
   metadata.condition = function (dt)
      seconds = seconds - dt
      return seconds <= 0
   end
   yield()
end -- wait_for_seconds

function wait_for_frames (context, frames)
   local metadata = get_metadata(context, running())
   metadata.ready_to_resume = false
   metadata.condition = function()
      frames = frames - 1
      return frames <= 0
   end
   yield()
end -- wait_for_frames

function wait_for_condition(context, condition)
   local metadata = get_metadata(context, running())
   metadata.ready_to_resume = false
   metadata.condition = condition
   yield()
end -- wait_for_condition

function load(context, proxy, enable)
   local metadata = get_metadata(context, running())
   metadata.ready_to_resume = false
   metadata.on_message = function (message_id, _, sender)
      if message_id == msg.PROXY_LOADED and sender == proxy then
         if enable then
            post(proxy, msg.ENABLE)
         end
         metadata.on_message = nil
         metadata.ready_to_resume = true
      end
   end
   post(proxy, msg.ASYNC_LOAD)
   yield()
end -- load

function unload(context, proxy)
   local metadata = get_metadata(context, running())
   metadata.ready_to_resume = false
   metadata.on_message = function (message_id, _, sender)
      if message_id == msg.PROXY_UNLOADED and sender == proxy then
         metadata.on_message = nil
         metadata.ready_to_resume = true
      end
   end
   post(proxy, msg.UNLOAD)
   yield()
end -- unload

function play_animation (context, target, animation)
   local metadata = get_metadata(context, running())
   metadata.ready_to_resume = false
   metadata.on_message = function (message_id, _, sender)
      if message_id == msg.ANIMATION_DONE and sender == target then
         metadata.on_message = nil
         metadata.ready_to_resume = true
      end
   end
   post(target, msg.PLAY_ANIMATION, animation)
   yield()
end -- play_animation

-- export
return {
   new = new,
   delete = delete,
   update = update,
   on_message = on_message,
   wait_for_seconds = wait_for_seconds,
   wait_for_frames = wait_for_frames,
   wait_for_condition = wait_for_condition,
   load = load,
   unload = unload,
   play_animation = play_animation,
}
