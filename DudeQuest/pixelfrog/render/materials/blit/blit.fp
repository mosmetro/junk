uniform lowp sampler2D tex_sampler;

varying mediump vec2 var_texcoord0;

void main()
{
	gl_FragColor = texture2D(tex_sampler, var_texcoord0);
}