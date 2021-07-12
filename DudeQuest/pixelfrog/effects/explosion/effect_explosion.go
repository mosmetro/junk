components {
  id: "script"
  component: "/pixelfrog/effects/explosion/effect_explosion.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/pixelfrog/effects/effects.atlas\"\n"
  "default_animation: \"explosion\"\n"
  "material: \"/pixelfrog/render/materials/effect/effect.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  ""
  position {
    x: 1.0
    y: 1.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
