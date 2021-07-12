varying mediump vec2 var_texcoord0;

uniform lowp sampler2D original;

uniform mediump vec4 resolution;

//RADIUS of our vignette, where 0.5 results in a circle fitting the screen
const float RADIUS = 0.75;

//softness of our vignette, between 0.0 and 1.0
const float SOFTNESS = 0.45;

//sepia colour, adjust to taste
const vec3 SEPIA = vec3(1.2, 1.0, 0.8);

void main()
{
	vec4 texColor = texture2D(original, var_texcoord0);
	vec2 position = (gl_FragCoord.xy / resolution.xy) - vec2(0.5);
	//OPTIONAL: correct for aspect ratio
	//position.x *= resolution.x / resolution.y;
	float len = length(position);
	float vignette = smoothstep(RADIUS, RADIUS-SOFTNESS, len);
	//apply our vignette with 50% opacity
	texColor.rgb = mix(texColor.rgb, texColor.rgb * vignette, 0.6);
	//texColor.rgb *= vignette;
	//uses NTSC conversion weights
	float gray = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
	gl_FragColor = vec4(vec3(gray) * SEPIA, 1.0);

	
	//vec4 color = texture2D(original, var_texcoord0);
	//float grey = color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
	//gl_FragColor = vec4(grey, grey, grey, 1.0);
	//gl_FragColor = vec4(vec3((1.0 - var_texcoord0.t)*grey ), 1.0);
	
}
