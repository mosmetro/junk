uniform lowp sampler2D sampler;

varying mediump vec2 uv;

const float k = 0.005;

void main()
{
	lowp vec4 color = texture2D(sampler, uv + vec2(-0.326212, -0.405805) * k);
	color += texture2D(sampler, uv + vec2(-0.840144, -0.073580) * k);
	color += texture2D(sampler, uv + vec2(-0.695914, 0.457137) * k);
	color += texture2D(sampler, uv + vec2(-0.203345, 0.620716) * k);
	color += texture2D(sampler, uv + vec2(0.962340, -0.194983) * k);
	color += texture2D(sampler, uv + vec2(0.473434, -0.480026) * k);
	color += texture2D(sampler, uv + vec2(0.519456, 0.767022) * k);
	color += texture2D(sampler, uv + vec2(0.185461, -0.893124) * k);
	color += texture2D(sampler, uv + vec2(0.507431, 0.064425) * k);
	color += texture2D(sampler, uv + vec2(0.896420, 0.412458) * k);
	color += texture2D(sampler, uv + vec2(-0.321940, -0.932615) * k);
	color += texture2D(sampler, uv + vec2(-0.791559, -0.597705) * k);
	float a = (color.r + color.g + color.b) / 3.0;
	a /= 12.0;
	color.r = a;
	color.g = a;
	color.b = a;
	gl_FragColor = color;
}