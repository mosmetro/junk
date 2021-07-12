-- import
local LAYER = require("scripts.shared.layers")

-- localization
local hash = hash
local vector3 = vmath.vector3

return {
	PRINCESS_HOOK       = { animation = hash("princess_chain_hook"),          offset = vector3(0.0,  0.0, LAYER.FX_A) },
	PRINCESS_CHAIN_A    = { animation = hash("princess_chain_a"),             offset = vector3(0.0,  0.0, LAYER.FX_A) },
	PRINCESS_CHAIN_B    = { animation = hash("princess_chain_b"),             offset = vector3(0.0,  0.0, LAYER.FX_A) },
	IMPACT_SMALL        = { animation = hash("impact_small"),                 offset = vector3(0.0,  0.0, LAYER.FX_A) },
	DESTROY             = { animation = hash("goblin-sword-fx-destroy"),      offset = vector3(1.0,  5.5, LAYER.FX_A) },
	HERO_GET_HIT        = { animation = hash("goblin-sword-fx-hero-get-hit"), offset = vector3(0.0, -1.0, LAYER.FX_A) },
}
