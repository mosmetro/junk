varying mediump vec2 var_texcoord0;

uniform lowp sampler2D original;
uniform mediump vec4 resolution;

uniform mediump vec4 light0_position;
uniform lowp vec4 light0_color;
uniform lowp vec4 light0_falloff;

uniform mediump vec4 light1_position;
uniform lowp vec4 light1_color;
uniform lowp vec4 light1_falloff;

uniform mediump vec4 light2_position;
uniform lowp vec4 light2_color;
uniform lowp vec4 light2_falloff;

uniform mediump vec4 light3_position;
uniform lowp vec4 light3_color;
uniform lowp vec4 light3_falloff;

uniform mediump vec4 light4_position;
uniform lowp vec4 light4_color;
uniform lowp vec4 light4_falloff;

uniform mediump vec4 light5_position;
uniform lowp vec4 light5_color;
uniform lowp vec4 light5_falloff;

uniform lowp vec4 ambient_color;

void main()
{
	mediump vec2 st = gl_FragCoord.xy / resolution.xy;
	lowp vec4 diffuse_color = texture2D(original, var_texcoord0);
	mediump float aspect_correction = resolution.z;
	lowp vec3 final_color = ambient_color.rgb * ambient_color.a;

	mediump vec2 light_dir;
	lowp float distance;
	lowp float attenuation;

	{
		light_dir = light0_position.xy - st;
		light_dir.x *= aspect_correction;
		distance = dot(light_dir, light_dir);
		attenuation = light0_falloff.w / (light0_falloff.x + light0_falloff.z * distance);
		final_color += light0_color.rgb * attenuation;
	}

	{
		light_dir = light1_position.xy - st;
		light_dir.x *= aspect_correction;
		distance = dot(light_dir, light_dir);
		attenuation = light1_falloff.w / (light1_falloff.x + light1_falloff.z * distance);
		final_color += light1_color.rgb * attenuation;
	}

	{
		light_dir = light2_position.xy - st;
		light_dir.x *= aspect_correction;
		distance = dot(light_dir, light_dir);
		attenuation = light2_falloff.w / (light2_falloff.x + light2_falloff.z * distance);
		final_color += light2_color.rgb * attenuation;
	}

	{
		light_dir = light3_position.xy - st;
		light_dir.x *= aspect_correction;
		distance = dot(light_dir, light_dir);
		attenuation = light3_falloff.w / (light3_falloff.x + light3_falloff.z * distance);
		final_color += light3_color.rgb * attenuation;
	}

	{
		light_dir = light4_position.xy - st;
		light_dir.x *= aspect_correction;
		distance = dot(light_dir, light_dir);
		attenuation = light4_falloff.w / (light4_falloff.x + light4_falloff.z * distance);
		final_color += light4_color.rgb * attenuation;
	}

	{
		light_dir = light5_position.xy - st;
		light_dir.x *= aspect_correction;
		distance = dot(light_dir, light_dir);
		attenuation = light5_falloff.w / (light5_falloff.x + light5_falloff.z * distance);
		final_color += light5_color.rgb * attenuation;
	}

	// gl_FragColor = vec4(clamp(final_color  * diffuse_color.rgb, vec3(0), diffuse_color.rgb * 3.0), diffuse_color.a);
	gl_FragColor = vec4(final_color * diffuse_color.rgb, diffuse_color.a);
}
