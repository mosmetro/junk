-- localization
local next = next
-- local utils = require("m.utils")

local dispatch_table = {}
local anyone = hash("anyone")

local function add_observer(callback, notification, sender)
   sender = sender or anyone
   local senders = dispatch_table[notification]
   if not senders then
      senders = {}
      dispatch_table[notification] = senders
   end
   local callbacks = senders[sender]
   if not callbacks then
      callbacks = {}
      senders[sender] = callbacks
   end
   callbacks[callback] = true
end -- add_observer

local function remove_observer(callback, notification, sender)
   sender = sender or anyone
   local senders = dispatch_table[notification]
   if senders then
      local callbacks = senders[sender]
      if callbacks then
         callbacks[callback] = nil
         if not next(callbacks) then
            senders[sender] = nil
            if not next(senders) then
               dispatch_table[notification] = nil
            end
         end
      end
   end
end -- remove_observer

local function post_notification(notification, sender, ...)
   local senders = dispatch_table[notification]
   if senders then
      local callbacks = senders[sender or anyone]
      if callbacks then
         for callback, _ in next, callbacks do
            callback(sender, ...)
         end
      end
   end
end -- post_notification

local function inspect()
   pprint(dispatch_table)
end

-- export
return {
   add_observer = add_observer,
   remove_observer = remove_observer,
   post_notification = post_notification,
   inspect = inspect,
}
