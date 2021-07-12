components {
  id: "script"
  component: "/maze/e1/props/effects/effect_small_flame.script"
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
  data: "tile_set: \"/maze/e1/e1_effects.atlas\"\n"
  "default_animation: \"small_flame\"\n"
  "material: \"/maze/e1/props/effects/effect.material\"\n"
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
embedded_components {
  id: "light"
  type: "sprite"
  data: "tile_set: \"/maze/e1/props/lights/lights.atlas\"\n"
  "default_animation: \"light_mask_yellow_64-export\"\n"
  "material: \"/maze/e1/props/lights/light.material\"\n"
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
