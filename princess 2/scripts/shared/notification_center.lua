-- import
local utils = require("scripts.shared.utils")

-- localization
local execute_in_context = utils.execute_in_context
local next = next

-- functions
local add_observer
local remove_observer
local post_notification

local dispatch_table = {}

function add_observer (observer, notification, callback)
	local observers = dispatch_table[notification]
	if not observers then
		observers = {}
		dispatch_table[notification] = observers
	end
	observers[observer] = callback
end

function remove_observer (observer, notification)
	if notification then
		local observers = dispatch_table[notification]
		if observers then
			observers[observer] = nil
		end
	else
		for _, observers in next, dispatch_table do
			observers[observer] = nil
		end
	end
end

function post_notification (notification, sender, payload)
	local observers = dispatch_table[notification]
	if not observers then return end

	for observer, callback in next, observers do
		execute_in_context(observer, callback, sender, payload)
	end
end

-- export
return {
	add_observer = add_observer,
	remove_observer = remove_observer,
	post_notification = post_notification,
}
