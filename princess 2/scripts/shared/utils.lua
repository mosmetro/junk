local defold = _G

local vmath = vmath
-- local min = math.min
local max = math.max
-- local exp = math.exp
local random = math.random
local randomseed = math.randomseed
local time = os.time
local acos = math.acos

local abs = math.abs
local sqrt = math.sqrt
local dot = vmath.dot
local length_sqr = vmath.length_sqr
local length = vmath.length
-- local normalize = vmath.normalize
local vector3 = vmath.vector3
local tonumber = tonumber
local type = type
local next = next
local open = io.open
local getinfo = debug.getinfo
local print = print

-- functions
local deep_copy_table
local execute_in_context
local trim_whitespaces

function trim_whitespaces (str)
	return str:match("^%s*(.-)%s*$")
end

-- https://gist.github.com/jrus/3197011
local function get_uuid()
	return ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", function (c)
		local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
		return ("%x"):format(v)
	end)
end

function execute_in_context(context, fn, ...)
	local current = _G[3700146495]
	_G[3700146495] = context
	local result = fn(context, ...)
	_G[3700146495] = current
	return result
end

local function tocolor (hex, alpha)
	local r, g, b = hex:match("(%w%w)(%w%w)(%w%w)")
	r = (tonumber(r, 16) or 0) / 255
	g = (tonumber(g, 16) or 0) / 255
	b = (tonumber(b, 16) or 0) / 255
	return r, g, b, alpha or 1
end

local function clamp (value, a, b)
	return value < a and a or (value > b and b or value)
end

local function log (...)
	local t = getinfo(2, "Sl")
	local s = t.short_src .. ":" .. t.currentline
	print(s, ...)
end

local function random_seed ()
	local file = open("/dev/urandom", "rb")
	if file then
		local a, b, c, d = file:read(4):byte(1, 4)
		file:close()
		local seed = a * 0x1000000 + b * 0x10000 + c * 0x100 + d
		randomseed(seed)
		log("randomseed with /dev/urandom")
	else
		local seed = time()
		randomseed(seed)
		random()
		randomseed(random(seed))
		random()
		log("randomseed with os.time")
	end
end

local function random_minus_one_one ()
	return  (random() - 0.5) * 2
end

local function random_range (lower, upper)
	return lower + random() * (upper - lower)
end

local function sign (arg)
	-- if arg < 0 then return -1 end
	-- return 1
	return (arg < 0) and -1 or 1
end

local function wrap (value, a, b)
	return value < a and b or (value > b and a or value)
end

local function inverse (vector)
	vector.x = -vector.x
	vector.y = -vector.y
	return vector
end

local function inversed (vector)
	local result = vector3(vector)
	return inverse(result)
end

local function reflect (vector, norm)
	local v = 2 * dot(vector, norm) * inversed(norm)
	vector.x = vector.x + v.x
	vector.y = vector.y + v.y
	return vector
end

local function perp(vector)
	return vector3(-vector.y, vector.x, 0)
end

local function safe_normalize (vector)
	local len = length(vector)
	if len > 0.000001 then
		vector.x = vector.x / len
		vector.y = vector.y / len
	else
		vector.x = 1
		vector.y = 0
	end
	return vector
end

local function safe_normalized (vector)
	local result = vector3(vector)
	return safe_normalize(result)
end

local function unsafe_normalize (vector)
	local len = length(vector)
	vector.x = vector.x / len
	vector.y = vector.y / len
	return vector
end

local function unsafe_normalized (vector)
	local result = vector3(vector)
	return unsafe_normalize(result)
end

local function try_normalized (vector)
	local result = vector3(vector)
	local success = true
	if abs(result.x) > 0.001 or abs(result.y) > 0.001 then
		local len = length(result)
		result.x = result.x / len
		result.y = result.y / len
	else
		result.x = 1
		result.y = 0
		success = false
	end
	return result, success
end

local function truncate (vector, max_length)
	local len_sqr = length_sqr(vector)
	if len_sqr > max_length * max_length then
		local len = sqrt(len_sqr)
		vector.x = vector.x / len * max_length
		vector.y = vector.y / len * max_length
	end
	return vector
end

local function truncated (vector, max_length)
	local result = vector3(vector)
	return truncate(result, max_length)
end

local function angle_between( v1, v2 )
	-- assert(vmath.length(v1) == 1)
	-- assert(vmath.length(v2) == 1)
	return acos(dot(v1, v2))
end

local function distance (p1, p2)
	local dx = p1.x - p2.x
	local dy = p1.y - p2.y
	return sqrt(dx * dx + dy * dy)
end

local function smooth_damp (current, target, current_speed, smooth_time, max_speed, dt)
	smooth_time = max(0.0001, smooth_time)
	local num = 2 / smooth_time
	local num2 = num * dt
	local num3 = 1 / (1 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2)
	local num4 = current - target
	local num5 = target
	local num6 = max_speed * smooth_time
	num4 = clamp(num4, -num6, num6)
	target = current - num4
	local num7 = (current_speed + num * num4) * dt
	current_speed = (current_speed - num * num7) * num3
	local num8 = target + (num4 + num7) * num3
	if ((num5 - current) > 0) == (num8 > num5) then
		num8 = num5
		current_speed = (num8 - num5) / dt
	end
	return num8, current_speed
end

local function reverse (tbl)
	local i, j = 1, #tbl
	while i < j do
		tbl[i], tbl[j] = tbl[j], tbl[i]
		i = i + 1
		j = j - 1
	end
end

local function ease (x, f)
	return x ^ f / (x ^ f + (1 - x) ^ f)
end

local function shuffle (seq)
	for i = #seq, 3, -1 do
		local j = random(i)
		seq[i], seq[j] = seq[j], seq[i]
	end
end

local function select_shuffle (seq, prob)
	if prob and random(100) > prob then
		return nil
	end

	if seq.next then
		seq.next = seq.next + 1
		seq.next = seq.next % #seq
	else
		seq.next = 0
	end

	if seq.next == 0 then shuffle(seq) end
	return seq[seq.next + 1]
end

local function select_next (seq, prob)
	if prob and random(100) > prob then
		return nil
	end

	if seq.next then
		seq.next = seq.next + 1
		seq.next = seq.next % #seq
	else
		seq.next = 0
	end
	return seq[seq.next + 1]
end

local function select_random (seq, prob)
	if prob and random(100) > prob then
		return nil
	end
	local nxt = random(#seq)
	return seq[nxt]
end

function deep_copy_table (t)
	local copy = {}
	for k, v in next, t do
		if type(v) == "table" then
			copy[k] = deep_copy_table(v)
		else
			copy[k] = v
		end
	end
	return copy
end

return {
	log = log,
	trim_whitespaces = trim_whitespaces,
	get_uuid = get_uuid,
	execute_in_context = execute_in_context,
	tocolor = tocolor,
	random_seed = random_seed,
	random_minus_one_one = random_minus_one_one,
	random_range = random_range,
	sign = sign,
	clamp = clamp,
	wrap = wrap,
	truncate = truncate,
	truncated = truncated,
	safe_normalize = safe_normalize,
	safe_normalized = safe_normalized,
	unsafe_normalize = unsafe_normalize,
	unsafe_normalized = unsafe_normalized,
	try_normalized = try_normalized,
	angle_between = angle_between,
	smooth_damp = smooth_damp,
	reverse = reverse, -- table array
	inverse = inverse, -- vector
	inversed = inversed, -- vector
	reflect = reflect,
	perp = perp,
	ease = ease,
	shuffle = shuffle,
	select_shuffle = select_shuffle,
	select_random = select_random,
	select_next = select_next,
	distance = distance,
	deep_copy_table = deep_copy_table,
}
