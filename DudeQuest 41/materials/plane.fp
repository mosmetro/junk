uniform lowp sampler2D source_sampler;
uniform lowp sampler2D bloom_sampler;

varying mediump vec2 var_texcoord0;

void main()
{
    vec4 source_color = texture2D(source_sampler, var_texcoord0);
    vec4 bloom_color = texture2D(bloom_sampler, var_texcoord0);
    gl_FragColor = source_color + bloom_color;
}
