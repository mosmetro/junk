uniform lowp sampler2D sampler0;
uniform lowp sampler2D sampler1;

varying mediump vec2 screen_uv;
varying mediump vec2 uv;

void main()
{
   lowp vec4 color = texture2D(sampler0, uv);
   lowp vec4 mask_color = texture2D(sampler1, screen_uv);
   
   gl_FragColor = color * mask_color.a;
}
