#extension GL_OES_standard_derivatives : enable

varying mediump vec2 var_texcoord0;
varying lowp vec4 var_face_color;

uniform lowp sampler2D texture_sampler;

// Rotated grid UV offsets
const mediump float offset_x = 0.125;
const mediump float offset_y = 0.375;

void main()
{
   // Per pixel partial derivatives
   mediump vec2 dx = dFdx(var_texcoord0);
   mediump vec2 dy = dFdy(var_texcoord0);

   // Supersampled using 2x2 rotated grid
   mediump vec4 col = texture2D(texture_sampler, var_texcoord0 + offset_x * dx + offset_y * dy);
   col += texture2D(texture_sampler, var_texcoord0 - offset_x * dx - offset_y * dy);
   col += texture2D(texture_sampler, var_texcoord0 + offset_y * dx - offset_x * dy);
   col += texture2D(texture_sampler, var_texcoord0 - offset_y * dx + offset_x * dy);

   gl_FragColor = col * 0.25 * var_face_color * var_face_color.a;
}
