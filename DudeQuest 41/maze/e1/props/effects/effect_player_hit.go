components {
  id: "script"
  component: "/maze/e1/props/effects/effect_player_hit.script"
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
  "default_animation: \"player_hit\"\n"
  "material: \"/maze/e1/props/effects/effect_linear.material\"\n"
  "blend_mode: BLEND_MODE_ADD\n"
  ""
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
