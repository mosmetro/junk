-- import
-- local Button_base = require("scripts.shared.ui.button_base")
local Control = require("scripts.shared.ui.control")

-- localization
local next = next
local pcall = pcall
local new_box_node = gui.new_box_node
local set_parent = gui.set_parent
local set_texture = gui.set_texture
local play_flipbook = gui.play_flipbook
local set_layer = gui.set_layer
local set_id = gui.set_id
local get_id = gui.get_id
local set_pivot = gui.set_pivot
local get_node = gui.get_node
local set_position = gui.set_position
local get_position = gui.get_position
local get_size = gui.get_size
local set_size = gui.set_size
-- local set_inherit_alpha = gui.set_inherit_alpha
local get_text_metrics_from_node = gui.get_text_metrics_from_node
local vector3 = vmath.vector3
local PIVOT_W = gui.PIVOT_W

-- functions
local new

function new (self)

	local is_on = false
	local radio_group = self.radio_group
	if radio_group then
		radio_group[#radio_group + 1] = self
	end

	function self.is_on ()
		return is_on
	end

	function self.set_on (value)
		is_on = value
		self.release()
	end

	function self.pointer_down_entered ()
		self.press()
		if self.on_press then self:on_press() end
	end

	function self.pointer_down_exited ()
		self.release()
	end

	function self.pointer_up_inside ()
		if radio_group then
			if not is_on then
				is_on = true
				for _, radio_button in next, radio_group do
					if radio_button ~= self then
						radio_button.set_on(false)
					end
				end
				if self.callback then self:callback() end
			end
		else
			is_on = not is_on
			if self.callback then self:callback() end
		end
		self.release(true)
	end

	function self.pointer_up_outside ()
		self.release()
		if self.on_release then self:on_release() end
	end

	function self.pointer_cancelled ()
		self.release()
	end

	function self.resize ()
		local base_position = get_position(self.base_node)
		local base_size = get_size(self.base_node)
		local title_position = get_position(self.title_node)
		local title_width = get_text_metrics_from_node(self.title_node).width
		local parent_id = get_id(self.base_node)
		local node_id = parent_id .. "sensor_node"
		local success, node = pcall(get_node, node_id)
		local position = vector3()
		local size = vector3()
		if not success then
			node = new_box_node(position, size)
			set_id(node, node_id)
			set_pivot(node, PIVOT_W)
			set_parent(node, self.base_node)
			set_layer(node, "image")
			-- set_inherit_alpha(node, false)
			set_texture(node, "shantae_ui")
			play_flipbook(node, "transparent_1x1")
		end
		position.x = -base_size.x * 0.5
		size.x = base_size.x + (title_position.x - base_position.x - base_size.x * 0.5) + title_width
		size.y = base_size.y
		set_position(node, position)
		set_size(node, size)
		self.node = node
	end

	Control.new(self)
	self.resize()
	if self.init then self:init() end
	return self
end -- new

-- export
return {
	new = new,
}
