uniform lowp sampler2D sampler;

varying mediump vec2 uv;

const float burn = 0.15;
const float saturation = 0.45;
const float r = 1.0;
const float g = 0.98;
const float b = 0.85;
const float brite = 0.05;

const lowp vec3 r3 = vec3(1.0 / 3.0);
const lowp vec2 center = vec2(0.5);

void main()
{
	lowp vec4 color = texture2D(sampler, uv);
	lowp float d = distance(uv, center);
	color.rgb -= d * burn;
	float a = dot(color.rgb, r3);
	a *= 1.0 - saturation;
	color.r = (color.r * saturation + a) * r;
	color.g = (color.g * saturation + a) * g;
	color.b = (color.b * saturation + a) * b;
	color.rgb += brite;	
	gl_FragColor = color;
}
