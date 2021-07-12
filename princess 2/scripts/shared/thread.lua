-- import
local MSG = require("scripts.shared.messages")
local utils = require("scripts.shared.utils")

-- localization
local post = msg.post
local next = next
local create = coroutine.create
local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running

-- functions
local get_metadata
local new
local delete
local update
local on_message
local wait_for_seconds
local wait_for_frames
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

---------------------------------------

-- get_metadata

---------------------------------------

function get_metadata (context, co)
	local scope = context_scope[context] or {}
	local metadata = scope[co]
	if not metadata then
		metadata = { ready_to_resume = true }
		scope[co] = metadata
		context_scope[context] = scope
	end
	return metadata
end -- get_metadata

---------------------------------------

-- new

---------------------------------------

function new (context, fn)
	return get_metadata(context, create(fn))
end -- new

---------------------------------------

-- delete

---------------------------------------

function delete (context, metadata)
	local scope = context_scope[context]
	for co, meta in next, scope do
		if meta == metadata then
			scope[co] = nil
			break
		end
	end
end -- delete

---------------------------------------

-- update

---------------------------------------

function update (context, dt)
	local scope = context_scope[context]
	if not scope or (not next(scope)) then return end -- in there is no scope or table is empty

	for co, metadata in next, scope do
		if metadata.condition and metadata.condition(dt) then
			metadata.condition = nil
			metadata.ready_to_resume = true
		end
		if metadata.ready_to_resume then
			if not resume(co) then
				scope[co] = nil
			end
		end
	end
end -- update

---------------------------------------

-- on_message

---------------------------------------

function on_message (context, message_id, message, sender)
	local scope = context_scope[context]
	if not scope or (not next(scope)) then return end -- in there is no scope or table is empty

	for _, metadata in next, scope do
		if metadata.on_message then
			metadata.on_message(message_id, message, sender)
		end
	end
end -- on_message

---------------------------------------
-- wait_for_seconds
---------------------------------------

function wait_for_seconds (context, seconds)
	local metadata = get_metadata(context, running())
	metadata.ready_to_resume = false
	metadata.condition = function (dt)
		seconds = seconds - dt
		return seconds <= 0
	end
	yield()
end -- wait_for_seconds

---------------------------------------

-- wait_for_frames

---------------------------------------

function wait_for_frames (context, frames)
	local metadata = get_metadata(context, running())
	metadata.ready_to_resume = false
	metadata.condition = function ()
		frames = frames - 1
		return frames == 0
	end
	yield()
end -- wait_for_frames

---------------------------------------

-- load

---------------------------------------

function load (context, proxy, enable)
	local metadata = get_metadata(context, running())
	metadata.ready_to_resume = false
	metadata.on_message = function (message_id, _, sender)
		if message_id == MSG.PROXY_LOADED and sender == proxy then
			if enable then
				post(proxy, MSG.ENABLE)
			end
			metadata.on_message = nil
			metadata.ready_to_resume = true
		end
	end
	post(proxy, MSG.ASYNC_LOAD)
	yield()
end -- load

---------------------------------------

-- unload

---------------------------------------

function unload (context, proxy)
	local metadata = get_metadata(context, running())
	metadata.ready_to_resume = false
	metadata.on_message = function (message_id, _, sender)
		if message_id == MSG.PROXY_UNLOADED and sender == proxy then
			metadata.on_message = nil
			metadata.ready_to_resume = true
		end
	end
	post(proxy, MSG.UNLOAD)
	yield()
end -- unload

---------------------------------------

-- play_animation

---------------------------------------

function play_animation (context, target, animation)
	local metadata = get_metadata(context, running())
	metadata.ready_to_resume = false
	metadata.on_message = function (message_id, _, sender)
		if message_id == MSG.ANIMATION_DONE and sender == target then
			metadata.on_message = nil
			metadata.ready_to_resume = true
		end
	end
	post(target, MSG.PLAY_ANIMATION, animation)
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
	load = load,
	unload = unload,
	play_animation = play_animation,
}
