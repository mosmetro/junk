varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;

void main()
{   
    vec2 offset_x = vec2(1.0 / 256.0, 0.0);
    vec2 offset_y = vec2(0.0, 1.0 / 128.0);
    float alpha = texture2D(texture_sampler, var_texcoord0).a;
    vec4 v = vec4(1.0);
    if (alpha > 0.0) {
        v = texture2D(texture_sampler, var_texcoord0);
    } else {
    alpha += ceil(texture2D(texture_sampler, var_texcoord0 + offset_x).a);
    alpha += ceil(texture2D(texture_sampler, var_texcoord0 - offset_x).a);
    alpha += ceil(texture2D(texture_sampler, var_texcoord0 + offset_y).a);
    alpha += ceil(texture2D(texture_sampler, var_texcoord0 - offset_y).a);

    v = vec4(1.0 * alpha, 1.0 * alpha, 1.0 * alpha, alpha);
    // v = vec4(0.0, 0.0, 0.0, alpha);
}
    gl_FragColor = v;
}
