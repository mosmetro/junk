uniform lowp sampler2D source;

varying mediump vec2 var_texcoord0;

const float threshold = 0.7;
const float factor   = 4.0;
const vec3 relative_luminance = vec3(0.2126, 0.7152, 0.0722);

void main()
{
	vec4 source_color = texture2D(source, var_texcoord0);
	float luminance = dot(source_color.rgb, relative_luminance);
	source_color *= clamp(luminance - threshold, 0.0, 1.0) * factor;
	gl_FragColor = source_color;
}
