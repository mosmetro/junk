uniform lowp sampler2D sampler;

varying mediump vec2 var_texcoord0;

void main()
{
	if (var_texcoord0.y < 0.25) {
		gl_FragColor = vec4(1.0, 1.0, 1.0, 0.0);
	} else {
		gl_FragColor = texture2D(sampler, var_texcoord0);
	}
}