local function new()
   local storage = {}
   local head = 0
   local tail = 0

   function storage.push_right(value)
      tail = tail + 1
      storage[tail] = value
   end

   function storage.push_left(value)
      storage[head] = value
      head = head - 1
   end

   function storage.peek_right()
      return storage[tail]
   end

   function storage.peek_left()
      return storage[head + 1]
   end

   function storage.pop_right()
      if head == tail then return nil end
      local result = storage[tail]
      storage[tail] = nil
      tail = tail - 1
      return result
   end

   function storage.pop_left()
      if head == tail then return nil end
      head = head + 1
      local result = storage[head]
      storage[head] = nil
      return result
   end

   function storage.length()
      return tail - head
   end

   function storage.is_empty()
      return (tail - head) == 0
   end

   return storage
end

-- export
return {
   new = new,
}