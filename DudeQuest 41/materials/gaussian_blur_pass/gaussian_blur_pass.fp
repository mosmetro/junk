uniform lowp sampler2D source;
uniform vec4 offset;

varying mediump vec2 var_texcoord0;

void main()
{
	vec4 color = vec4(0.0);
	vec2 offset_factor = offset.xy;
	color += texture2D(source, var_texcoord0 - 4.0 * offset_factor) * 0.0162162162;
	color += texture2D(source, var_texcoord0 - 3.0 * offset_factor) * 0.0540540541;
	color += texture2D(source, var_texcoord0 - 2.0 * offset_factor) * 0.1216216216;
	color += texture2D(source, var_texcoord0 - offset_factor) * 0.1945945946;
	color += texture2D(source, var_texcoord0) * 0.2270270270;
	color += texture2D(source, var_texcoord0 + offset_factor) * 0.1945945946;
	color += texture2D(source, var_texcoord0 + 2.0 * offset_factor) * 0.1216216216;
	color += texture2D(source, var_texcoord0 + 3.0 * offset_factor) * 0.0540540541;
	color += texture2D(source, var_texcoord0 + 4.0 * offset_factor) * 0.0162162162;
	gl_FragColor = color;
}