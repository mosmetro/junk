uniform lowp sampler2D sampler;
uniform mediump vec4 threshold;

varying mediump vec2 uv;

const mediump vec3 perception = vec3(0.299, 0.587, 0.114);

void main()
{
	mediump vec3 color = texture2D(sampler, uv).xyz;
	mediump float luminance = dot(perception, color);
	gl_FragColor = (luminance > threshold.x) ? vec4(color, 1.0) : vec4(0.0);
}
