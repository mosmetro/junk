uniform lowp sampler2D sampler;
// uniform mediump vec2 direction;
// uniform mediump vec2 resolution;

uniform mediump vec4 params;

varying mediump vec2 uv;

void main()
{
	// mediump vec4 color = vec4(0.0);
	// mediump vec2 off1 = vec2(1.3333333333333333) * params.xy; // direction
	// color += texture2D(sampler, uv) * 0.29411764705882354;
	// color += texture2D(sampler, uv + (off1 / params.zw)) * 0.35294117647058826; // resolution
	// color += texture2D(sampler, uv - (off1 / params.zw)) * 0.35294117647058826; // resolution
	// gl_FragColor = color;

	mediump vec2 direction = params.xy;
	mediump vec2 resolution = params.zw;

	mediump vec4 color = vec4(0.0);
	mediump vec2 off1 = vec2(1.3846153846) * direction;
	mediump vec2 off2 = vec2(3.2307692308) * direction;
	color += texture2D(sampler, uv) * 0.2270270270;
	color += texture2D(sampler, uv + (off1 / resolution)) * 0.3162162162;
	color += texture2D(sampler, uv - (off1 / resolution)) * 0.3162162162;
	color += texture2D(sampler, uv + (off2 / resolution)) * 0.0702702703;
	color += texture2D(sampler, uv - (off2 / resolution)) * 0.0702702703;
	gl_FragColor = color;
}