components {
  id: "script"
  component: "/pixelfrog/effects/small_puff/effect_small_puff.script"
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
  "default_animation: \"small_puff\"\n"
  "material: \"/pixelfrog/render/materials/effect/effect.material\"\n"
  "blend_mode: BLEND_MODE_ADD\n"
  ""
  position {
    x: 0.0
    y: 8.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
