varying mediump vec2 var_texcoord0;
varying lowp vec4 var_color;

uniform lowp sampler2D texture_sampler;

vec3 hsb2rgb(in vec3 c)
{
   vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) -3.0) - 1.0, 0.0, 1.0);
   rgb = rgb * rgb * (3.0 - 2.0 * rgb);
   return c.z * mix(vec3(1.0), rgb, c.y);
}

void main()
{
   vec2 st = var_texcoord0;//gl_FragCoord.xy/u_resolution;
   //    vec3 color = vec3(0.0);

   // We map x (0.0 - 1.0) to the hue (0.0 - 1.0)
   // And the y (0.0 - 1.0) to the brightness
   vec3 color = hsb2rgb(vec3(st.x, 1.0, 1.0));

   gl_FragColor = vec4(color, 1.0);


   // lowp vec4 tex = texture2D(texture_sampler, var_texcoord0.xy);
   // gl_FragColor = tex * var_color;
}
