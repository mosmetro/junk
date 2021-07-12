varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;

uniform lowp vec4 shield_a;
uniform lowp vec4 shield_b;
uniform lowp vec4 sword;

vec3 cian = vec3(0.0, 1.0, 1.0);
vec3 magenta = vec3(1.0, 0.0, 1.0);
vec3 yellow = vec3(1.0, 1.0, 0.0);

void main()
{    
    vec3 qwerty[2];
    qwerty[0] = magenta;
    qwerty[1] = cian;
 
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    lowp vec4 color = texture2D(texture_sampler, var_texcoord0);

    if (color.rgb == magenta) {
        color.rgb = shield_a.rgb;
    } else if (color.rgb == cian) {
        color.rgb = shield_b.rgb;
    } else if (color.rgb == yellow) {
        color.rgb = sword.rgb;
    }

    gl_FragColor = color * tint_pm;
}
