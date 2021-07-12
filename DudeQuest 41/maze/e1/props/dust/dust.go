components {
  id: "script"
  component: "/maze/e1/props/dust/dust.script"
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
  id: "light"
  type: "sprite"
  data: "tile_set: \"/maze/e1/props/lights/lights.atlas\"\n"
  "default_animation: \"dust_light\"\n"
  "material: \"/maze/e1/props/lights/light.material\"\n"
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
embedded_components {
  id: "glow"
  type: "sprite"
  data: "tile_set: \"/maze/e1/e1_props.atlas\"\n"
  "default_animation: \"dust_glow\"\n"
  "material: \"/materials/sprite_linear.material\"\n"
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
