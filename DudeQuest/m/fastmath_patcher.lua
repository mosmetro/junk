local sqrt = math.sqrt
-- local mathmax = math.max
-- local mathabs = math.abs
local fastmath = fastmath
local random_int = fastmath.random_int

local select = select
local matrix_make
local matrix_multiply
local sign
local abs
local clamp01
local clamp
local lerp
local lerp_unclamped
local smooth_step
local smooth_step_unclamped
local fast_step
local fast_step_unclamped
local get_distance
local get_distance_squared
local min
local max
local maxs
local ensure_zero
local is_equal
local length
local safe_normalize
local truncate
local ease
local clear_array
local clear_arrays
local pick_next
local pick_reset
local pick_any
local pick_first
local pick_last
local shuffle

local TO_DEG = 180 / math.pi
local TO_RAD = math.pi / 180
local IDENTITY = vmath.quat()
-- local get_uuid

-- https://gist.github.com/jrus/3197011
-- function get_uuid()
--    return ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", function(c)
--       local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
--       return ("%x"):format(v)
--    end)
-- end

function matrix_make(a, c, tx,
   b, d, ty)
   return {
      a, b, 0, 0,
      c, d, 0, 0,
      0, 0, 1, 0,
      tx,ty,0, 1
   }
end

function matrix_multiply(a, b)
   return matrix_make(
   a[1] * b[1] + a[5] * b[2], a[1] * b[5] + a[5] * b[6], a[1] * b[13] + a[5] * b[14] + a[13],
   a[2] * b[1] + a[6] * b[2], a[2] * b[5] + a[6] * b[6], a[2] * b[13] + a[6] * b[14] + a[14]
)
end

function sign(arg)
   return arg < 0 and -1 or (arg > 0 and 1 or 0)
end

function abs(value)
   return value >= 0 and value or -value
end

function clamp01(value)
   return value < 0 and 0 or (value > 1 and 1 or value)
end

function clamp(value, a, b)
   -- if a > b then
   -- 	a, b = b, a
   -- end
   return value < a and a or (value > b and b or value)
end

function lerp(from, to, t)
   return from + (to - from) * clamp01(t)
end

function lerp_unclamped(from, to, t)
   return from + (to - from) * t
end

function smooth_step(from, to, t)
   t = clamp01(t)
   t = -2 * t * t * t + 3 * t * t
   return to * t + from * (1 - t)
end

function smooth_step_unclamped(from, to, t)
   t = -2 * t * t * t + 3 * t * t
   return to * t + from * (1 - t)
end

function fast_step(from, to, t)
   t = clamp01(t)
   t = -2 * t * t + 3 * t
   return to * t + from * (1 - t)
end

function fast_step_unclamped(from, to, t)
   t = -2 * t * t + 3 * t
   return to * t + from * (1 - t)
end

function get_distance(from, to)
   local x = from[1] - to[1]
   local y = from[2] - to[2]
   return sqrt(x * x + y * y)
end

-- function get_distance_ext(array_x, array_y, from_index, to_index)
--    local dx = array_x[from_index] - array_x[to_index]
--    local dy = array_y[from_index] - array_y[to_index]
--    return sqrt(dx * dx + dy * dy)
-- end

function get_distance_squared(from, to)
   local x = from[1] - to[1]
   local y = from[2] - to[2]
   return x * x + y * y
end

-- function length(v)
--    return sqrt(v[1] * v[1] + v[2] * v[2])
-- end

function length(x, y)
   return sqrt(x * x + y * y)
end -- length

-- function safe_normalize(v)
--    local len = length(v)
--    if len > 0.001 then
--       v[1] = v[1] / len
--       v[2] = v[2] / len
--    else
--       v[1] = 1
--       v[2] = 0
--    end
--    return v
-- end

function safe_normalize(x, y)
   local len = sqrt(x * x + y * y)
   if len > 0.001 then
      x = x / len
      y = y / len
   else
      x = 1
      y = 0
   end
   return x, y
end -- safe_normalize

function truncate(x, y, max_len)
   local len = sqrt(x * x + y * y)
   if len > max_len then
      x = (x / len) * max_len
      y = (y / len) * max_len
   end
   return x ,y
end -- truncate

function ease (x, f)
   return x ^ f / (x ^ f + (1 - x) ^ f)
end

function min(a, b)
   return a < b and a or b
end

function max(a, b)
   return a > b and a or b
end

function maxs(values)
   local count = #values
   if count == 0 then
      return 0
   end
   local result = values[1]
   for i = 1, count do
      if values[i] > result then
         result = values[i]
      end
   end
   return result
end

function is_equal(a, b)
   if abs(a - b) < 0.001 then
      return true
   end
   return false
end

-- function is_equal(a, b)
--    if abs(a - b) < 0.0001 * (abs(a) + abs(b) + 1.0) then
--       return true
--    end
--    return false
-- end

function ensure_zero(value)
   if (value < -0.001) or (value > 0.001) then
      return value
   end
   return 0
end

function clear_array(t)
   for i = 1, #t do
      t[i] = nil
   end
end

function clear_arrays(...)
   local n = select("#", ...)
   for i = 1, n do
      local t = select(i, ...)
      for j = 1, #t do
         t[j] = nil
      end
   end
end

function pick_next(seq, upper_limit)
   seq.next = seq.next and (seq.next + 1) or 0
   return seq[seq.next % upper_limit + 1]
end -- pick_next

function pick_reset(seq)
   seq.next = nil
end

function pick_any(t, upper_limit)
   return t[random_int(upper_limit or #t)]
end

function pick_first(t)
   return t[1]
end

function pick_last(t)
   return t[#t]
end

function shuffle(t)
   for i = #t, 1, -1 do
      local j = random_int(i)
      t[i], t[j] = t[j], t[i]
   end
end

-- https://github.com/EmmanuelOga/easing
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

local function easing_linear(t, b, c, d)
   return c * t / d + b
end -- easing_linear

local function easing_out_quad(t, b, c, d)
   t = t / d
   return -c * t * (t - 2) + b
end --easing_out_quad

-- 1 min_x
-- 2 min_y
-- 3 max_x
-- 4 max_y
local function aabb_overlap(a, b)
   if (a[3] < b[1]) or (a[1] > b[3]) then return false end
   if (a[4] < b[2]) or (a[2] > b[4]) then return false end
   return true
end -- aabb_overlap

local function aabb_contains_point(a, x, y)
   if (a[3] < x) or (a[1] > x) then return false end
   if (a[4] < y) or (a[2] > y) then return false end
   return true
end -- aabb_overlap

local function get_absolute_node_position(node)
   local x, y = fastmath.vector3_get_xy(gui.get_position(node))
   local parent = gui.get_parent(node)
   if parent then
      local px, py = get_absolute_node_position(parent)
      x = x + px
      y = y + py
   end
   return x, y
end -- get_absolute_node_position

local function sign_test(x1, y1, x2, y2, x3, y3)
	return (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
end -- sign_test

fastmath.sign_test = sign_test
fastmath.get_absolute_node_position = get_absolute_node_position
-- fastmath.get_uuid = get_uuid
fastmath.coin_toss = fastmath.bernoulli(0.5)
fastmath.vector3_stub = vmath.vector3()
fastmath.vector4_stub = vmath.vector4()
fastmath.ray_start = vmath.vector3()
fastmath.ray_end = vmath.vector3()
fastmath.pick_first = pick_first
fastmath.pick_last = pick_last
fastmath.pick_any = pick_any
fastmath.shuffle = shuffle
fastmath.aabb_overlap = aabb_overlap
fastmath.aabb_contains_point = aabb_contains_point
fastmath.easing_linear = easing_linear
fastmath.easing_out_quad = easing_out_quad
fastmath.IDENTITY = IDENTITY
fastmath.TO_DEG = TO_DEG
fastmath.TO_RAD = TO_RAD
fastmath.length = length
fastmath.safe_normalize = safe_normalize
fastmath.truncate = truncate
fastmath.is_equal = is_equal
fastmath.ensure_zero = ensure_zero
fastmath.matrix_make = matrix_make
fastmath.matrix_multiply = matrix_multiply
fastmath.sign = sign
fastmath.abs = abs
fastmath.clamp01 = clamp01
fastmath.clamp = clamp
fastmath.lerp = lerp
fastmath.lerp_unclamped = lerp_unclamped
fastmath.smooth_step = smooth_step
fastmath.smooth_step_unclamped = smooth_step_unclamped
fastmath.fast_step = fast_step
fastmath.fast_step_unclamped = fast_step_unclamped
fastmath.get_distance = get_distance
fastmath.get_distance_squared = get_distance_squared
fastmath.min = min
fastmath.max = max
fastmath.maxs = maxs
fastmath.ease = ease
fastmath.clear_array = clear_array
fastmath.clear_arrays = clear_arrays
fastmath.pick_next = pick_next
fastmath.pick_reset = pick_reset
