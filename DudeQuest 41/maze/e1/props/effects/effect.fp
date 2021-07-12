varying mediump vec2 var_texcoord0;

uniform lowp sampler2D sampler;
uniform lowp vec4 tint;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    gl_FragColor = texture2D(sampler, var_texcoord0) * tint_pm;
}
