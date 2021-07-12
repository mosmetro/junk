local function new()
   local m = {
      1, 0, 0,
      0, 1, 0,
   }

   function m.set_identity()
      m[1] = 1; m[2] = 0; m[3] = 0
      m[4] = 0; m[5] = 1; m[6] = 0
   end

   function m.set_translation(x, y)
      -- m[1] = 1; m[2] = 0; m[3] = x
      -- m[4] = 0; m[5] = 1; m[6] = y
      m[3] = x
      m[6] = y
   end

   function m.set_rotation(x, y) -- heading (normalized) vector
      -- m[1] = x; m[2] = -y; m[3] = 0
      -- m[4] = y; m[5] =  x; m[6] = 0
      m[1] = x; m[2] = -y
      m[4] = y; m[5] =  x
   end

   function m.translate(x, y)
      m[3] = m[1] * x + m[2] * y
      m[6] = m[4] * x + m[5] * y
   end

   function m.transform_point(x, y)
      local tx = m[1] * x + m[2] * y + m[3]
      local ty = m[4] * x + m[5] * y + m[6]
      return tx, ty
   end

   -- function m.multiply(n)
   --    local m1 = m[1] * n[1] + m[2] * n[4]
   --    local m2 = m[1] * n[2] + m[2] * n[5]
   --    local m3 = m[1] * n[3] + m[2] * n[6] + m[3]
   --
   --    local m4 = m[4] * n[1] + m[5] * n[4]
   --    local m5 = m[4] * n[2] + m[5] * n[5]
   --    local m6 = m[4] * n[3] + m[5] * n[6] + m[6]
   --
   --    m[1] = m1; m[2] = m2; m[3] = m3;
   --    m[4] = m4; m[5] = m5; m[6] = m6;
   -- end

   return m
end

return {
   new = new,
}
