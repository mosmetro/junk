uniform lowp sampler2D source_sampler;

varying mediump vec2 var_texcoord0;

void main()
{
	gl_FragColor = texture2D(source_sampler, var_texcoord0);
}