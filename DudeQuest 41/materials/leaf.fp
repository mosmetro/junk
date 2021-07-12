varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    // gl_FragColor = texture2D(texture_sampler, var_texcoord0.xy) * tint_pm;
    lowp vec4 color = texture2D(texture_sampler, var_texcoord0.xy);
    if (color.rgb == vec3(0.0, 1.0, 1.0)) {
        color.rgb = vec3(205.0/255.0, 5.0/255.0, 12.0/255.0);
    }
    if (color.rgb == vec3(0.0, 157.0/255.0, 157.0/255.0)) {
        color.rgb = vec3(120.0/255.0, 11.0/255.0, 12.0/255.0);
    }
    gl_FragColor = color * tint_pm;//vec4(1.0, 0.0, 0.0, 1.0) * tint_pm;
}
