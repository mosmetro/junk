varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;
uniform lowp vec4 scale;
uniform lowp vec4 offset;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    // lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    // lowp vec2 uv = vec2(var_texcoord0.x + offset.x, var_texcoord0.y + offset.y);
    // lowp vec2 uv = var_texcoord0 + offset.xy;
    // gl_FragColor = texture2D(texture_sampler, uv) * tint_pm;

    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    lowp vec2 uv = vec2(var_texcoord0.x * scale.x + offset.x, var_texcoord0.y * scale.y + offset.y);
    gl_FragColor = texture2D(texture_sampler, uv) * tint_pm;
}