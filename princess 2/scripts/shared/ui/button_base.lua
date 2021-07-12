-- import
local Control = require("scripts.shared.ui.control")

-- localization
-- local set_enabled = gui.set_enabled

-- functions
local new

---------------------------------------

-- new

---------------------------------------

function new (self)

	function self.pointer_down_entered ()
		self.press()
	end

	function self.pointer_down_exited ()
		self.release()
	end

	function self.pointer_up_inside ()
		self.release(true)
		if self.callback then self:callback() end
	end

	function self.pointer_up_outside ()
		self.release()
	end

	function self.pointer_cancelled ()
		self.release()
	end

	Control.new(self)
	return self
end -- new

-- export
return {
	new = new,
}
