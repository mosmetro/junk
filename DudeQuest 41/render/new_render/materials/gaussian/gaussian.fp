uniform lowp sampler2D sampler;
uniform mediump vec4 coefficients;
uniform mediump vec4 offset;

varying mediump vec2 uv;

void main()
{
	mediump vec3 a = coefficients.x * texture2D(sampler, uv - offset.xy).xyz;
	mediump vec3 b = coefficients.y * texture2D(sampler, uv).xyz;
	mediump vec3 c = coefficients.z * texture2D(sampler, uv + offset.xy).xyz;
	mediump vec3 color = a + b + c;
	gl_FragColor = vec4(color, 1.0);
}
