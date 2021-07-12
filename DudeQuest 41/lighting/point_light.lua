local Queue = require("m.queue")
-- local utils = require("m.utils")
local game = require("maze.game")
-- local debug_draw = require("m.debug_draw")
-- local colors = require("m.colors")

local global = require("game.global")


local sqrt = math.sqrt
local ceil = math.ceil
local sign_test = fastmath.sign_test
local clamp = fastmath.clamp

local PointLight = {}
local available_lights
local TILE_SIZE = 16
local SHADOW_LENGTH = 10000
local tilemap_layer = hash("static_geometry")
local POSITION_STREAM = hash("position")
local shadow_declaration = {
   { name = POSITION_STREAM, type = 8, count = 2 },
}

function PointLight.init(lights_data, context)
   PointLight.context = context
   available_lights = Queue.new(lights_data)
end -- init

function PointLight.new()
   local light = {}
   local data
   local positions = {}
   local previous_size = 0
   local shadow_buffer
   local position_stream
   -- local mx, my, mw, mh

   function light.enable()
      data = available_lights.pop_right()
      if data then
         PointLight[data.index] = data
      end
      -- utils.log("lights left: ", available_lights.length())
      -- mx = game.tilemap_x
      -- my = game.tilemap_y
      -- mw = game.tilemap_w
      -- mh = game.tilemap_h
      return data
   end -- enable

   function light.disable()
      if not data then return end
      available_lights.push_right(data)
      PointLight[data.index] = nil
      data = nil
      -- utils.log("lights left: ", available_lights.length())
   end -- disable

   local function project_shadow(ax, ay, bx, by, lx, ly)
      local dx = ax - lx
      local dy = ay - ly
      local len = sqrt(dx * dx + dy * dy)
      local adx = ax + (dx / len) * SHADOW_LENGTH
      local ady = ay + (dy / len) * SHADOW_LENGTH

      -- debug_draw.line(ax, ay, adx, ady, colors.YELLOW_500)

      dx = bx - lx
      dy = by - ly
      len = sqrt(dx * dx + dy * dy)
      local bdx = bx + ((dx / len) * SHADOW_LENGTH)
      local bdy = by + ((dy / len) * SHADOW_LENGTH)

      -- debug_draw.line(bx, by, bdx, bdy, colors.YELLOW_500)

      positions[#positions + 1] = ax
      positions[#positions + 1] = ay

      positions[#positions + 1] = bx
      positions[#positions + 1] = by

      positions[#positions + 1] = adx
      positions[#positions + 1] = ady

      positions[#positions + 1] = adx
      positions[#positions + 1] = ady

      positions[#positions + 1] = bx
      positions[#positions + 1] = by

      positions[#positions + 1] = bdx
      positions[#positions + 1] = bdy

   end -- project_shadow

   function light.update(aabb, x, y)
      if not data then return end
      for _, caster in next, game.shadow_casters do
         if (caster.aabb and (fastmath.aabb_overlap(aabb, caster.aabb))) or fastmath.aabb_contains_point(aabb, caster.x, caster.y) then
         -- if fastmath.aabb_overlap(aabb, caster.aabb) then
            for _, edge in next, caster.shadow_edges do
               local x1 = caster.x + edge[1]
               local y1 = caster.y + edge[2]
               local x2 = caster.x + edge[3]
               local y2 = caster.y + edge[4]
               if sign_test(x1, y1, x2, y2, x, y) > 0 then
                  -- debug_draw.line(x1, y1, x2, y2, colors.RED)
                  project_shadow(x1, y1, x2, y2, x, y)
               end
            end
         end
      end

      local mx, my, mw, mh = global.tilemap_x, global.tilemap_y, global.tilemap_w, global.tilemap_h

      local sx = clamp(ceil((aabb[1]) / TILE_SIZE), mx - 1, mx + mw - 1)
      local sy = clamp(ceil((aabb[2]) / TILE_SIZE), my - 1, my + mh - 1)
      local ex = clamp(ceil((aabb[3]) / TILE_SIZE), mx - 1, mx + mw - 1)
      local ey = clamp(ceil((aabb[4]) / TILE_SIZE), my - 1, my + mh - 1)
      -- debug_draw.rect_minmax(sx * TILE_SIZE, sy * TILE_SIZE, ex * TILE_SIZE, ey * TILE_SIZE, colors.YELLOW_500)

      for ty = sy, ey - 1 do
         for tx = sx, ex - 1 do
            local tile = tilemap.get_tile(global.tilemap_url, tilemap_layer, tx + 1, ty + 1)
            if tile > 0 then
               local x1 = tx * TILE_SIZE
               local y1 = ty * TILE_SIZE
               local x2 = x1 + TILE_SIZE
               local y2 = y1 + TILE_SIZE

               if sign_test(x1, y1, x1, y2, x, y) > 0 then
                  -- debug_draw.line(x1, y1, x1, y2, colors.RED)
                  project_shadow(x1, y1, x1, y2, x, y)
               end

               if sign_test(x1, y2, x2, y2, x, y) > 0 then
                  -- debug_draw.line(x1, y2, x2, y2, colors.RED)
                  project_shadow(x1, y2, x2, y2, x, y)
               end

               if sign_test(x2, y2, x2, y1, x, y) > 0 then
                  -- debug_draw.line(x2, y2, x2, y1, colors.RED)
                  project_shadow(x2, y2, x2, y1, x, y)
               end

               if sign_test(x2, y1, x1, y1, x, y) > 0 then
                  -- debug_draw.line(x2, y1, x1, y1, colors.RED)
                  project_shadow(x2, y1, x1, y1, x, y)
               end
            end
         end
      end

      local size = #positions

      if size == 0 then return end

      if size > previous_size then
         previous_size = size
         shadow_buffer = buffer.create(size / 2, shadow_declaration)
         position_stream = buffer.get_stream(shadow_buffer, POSITION_STREAM)
      end
      for j = 1, previous_size do
         position_stream[j] = positions[j] or 0
         positions[j] = nil
      end
      resource.set_buffer(data.resource, shadow_buffer)
   end -- update

   return light
end -- new

return PointLight
