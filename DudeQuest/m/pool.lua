-- import
local Queue = require("m.queue")
-- local utils = require("m.utils")

local function new(fn)
   local pool = {}
   local storage = Queue.new()

   function pool.new(context)
      local instance = storage.pop_right()
      if not instance then
         -- utils.log("creating new instance")
         instance = fn() -- fn {}
      -- else
      --    utils.log("get instance from pool, pool size: ", pool.count())
      end
      instance.init(context)
      return instance
   end

   function pool.free(instance)
      instance.deinit()
      storage.push_right(instance)
   end

   function pool.count()
      return storage.length()
   end

   function pool.fill(count)
      for _ = 1, count do
         local instance = fn() -- fn {}
         storage.push_right(instance)
      end
   end

   function pool.purge()
      while not storage.is_empty() do
         storage.pop_right()
      end
   end

   return pool
end

-- export
return {
   new = new,
}
