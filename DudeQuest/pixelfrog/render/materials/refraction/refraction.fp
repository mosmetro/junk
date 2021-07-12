uniform lowp sampler2D sampler;
uniform lowp sampler2D refract_sampler;
uniform lowp sampler2D light_sampler;

varying mediump vec2 var_texcoord0;

const float burn = 0.25;
const float saturation = 0.45;
const lowp vec3 color_correction = vec3(1.0, 0.98, 0.85);
const float brite = 0.0;//0.05;

const lowp vec3 r3 = vec3(1.0 / 3.0);
const lowp vec2 center = vec2(0.5);

mediump vec2 get_diff(mediump vec2 _tex) 
{
	mediump vec2 dif;

	mediump vec2 tex = _tex;
	mediump vec2 btex = _tex;
	tex.x -= 0.003;
	btex.x += 0.003;
	dif.x = texture2D(refract_sampler, tex).r - texture2D(refract_sampler, btex).r;

	tex = _tex;
	btex = _tex;
	tex.y -= 0.003;
	btex.y += 0.003;

	dif.y = texture2D(refract_sampler, tex).r - texture2D(refract_sampler, btex).r;

	dif *= (1.5 - texture2D(refract_sampler, _tex).r);

	return dif;
}

void main()
{
	mediump vec2 tex = get_diff(var_texcoord0) * 0.033 + var_texcoord0;
	lowp vec4 color = texture2D(sampler, tex);
	lowp vec3 c = color.rgb;
	lowp float d = distance(tex, center);
	c.rgb -= d * burn;
	lowp float a = dot(c, r3);
	a *= 1.0 - saturation;
	c = (c * saturation + a) * color_correction;
	c += brite;	
	
	lowp vec4 light_color = texture2D(light_sampler, var_texcoord0);
	gl_FragColor = vec4(c, color.a) * light_color;
}
