-- import
local UI = require("scripts.shared.ui.ui")

-- localization
local pick_node = gui.pick_node
local is_enabled = gui.is_enabled
local get_parent = gui.get_parent
local POINTER_DOWN      = UI.POINTER_DOWN
local POINTER_UP        = UI.POINTER_UP
local POINTER_DRAGGED   = UI.POINTER_DRAGGED
local POINTER_CANCELLED = UI.POINTER_CANCELLED

-- functions
local check_enabled
local hit_test
local new

---------------------------------------

-- check_enabled

---------------------------------------

function check_enabled (node)
	local parent = get_parent(node)
	if parent then
		return check_enabled(parent)
	end
	return is_enabled(node)
end -- check_enabled

---------------------------------------

-- hit_test

---------------------------------------

function hit_test (node, x, y)
	return check_enabled(node) and pick_node(node, x, y) or false
end -- hit_test

---------------------------------------

-- new

---------------------------------------

function new (self)
	self.is_active = true

	local tracking = false
	local pointer_inside = false

	---------------------------------------

	-- on_event

	---------------------------------------

	function self.on_event (event)
		if not self.is_active then return false end

		if event.type == POINTER_DOWN then
			if hit_test(self.node, event.x, event.y) then
				tracking = true
				pointer_inside = true
				if self.pointer_down_entered then self.pointer_down_entered(event) end
				return true
			end

		elseif event.type == POINTER_UP then
			if tracking then
				if pointer_inside then
					if self.pointer_up_inside then self.pointer_up_inside(event) end
				else
					if self.pointer_up_outside then self.pointer_up_outside(event) end
				end
				tracking = false
				pointer_inside = false
				return true
			end

		elseif event.type == POINTER_DRAGGED then
			if tracking then
				if hit_test(self.node, event.x, event.y) then
					if not pointer_inside then
						pointer_inside = true
						if self.pointer_down_entered then self.pointer_down_entered(event) end
					end
				else
					if pointer_inside then
						pointer_inside = false
						if self.pointer_down_exited then self.pointer_down_exited(event) end
					end
				end

				if self.pointer_dragged then	self.pointer_dragged(event) end
				return true
			end

		elseif event.type == POINTER_CANCELLED then
			tracking = false
			pointer_inside = false
			if self.pointer_cancelled then self.pointer_cancelled() end
		end
		return false
	end -- on_event

	return self
end -- new

-- export
return {
	new = new,
	hit_test,
}
