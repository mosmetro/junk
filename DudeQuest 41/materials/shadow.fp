varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;

void main()
{
    lowp vec4 color = vec4(0.0, 0.0, 0.0, texture2D(texture_sampler, var_texcoord0.xy).a);
    gl_FragColor = color;
}
