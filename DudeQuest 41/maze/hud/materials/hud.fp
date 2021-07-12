varying mediump vec2 var_texcoord0;
varying lowp vec4 var_color;

uniform lowp sampler2D sampler;

void main()
{
    lowp vec4 tex = texture2D(sampler, var_texcoord0);
    gl_FragColor = tex * var_color;
}
