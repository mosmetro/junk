varying mediump vec2 uv;

uniform mediump sampler2D tex_sampler;

const mediump vec3 k  = vec3(5.0/16.0, 6.0/16.0, 5.0/16.0);
// const mediump vec2 offset = vec2(1.2/256.0, 0.0);
const mediump vec2 offset = vec2(0.0, 1.2/256.0);

void main()
{
	mediump vec3 a = k.x * texture2D(tex_sampler, uv - offset).xyz;
	mediump vec3 b = k.y * texture2D(tex_sampler, uv).xyz;
	mediump vec3 c = k.z * texture2D(tex_sampler, uv + offset).xyz;
	mediump vec3 color = a + b + c;
	gl_FragColor = vec4(color, 1.0);
}