uniform lowp sampler2D sampler;

varying mediump vec2 uv;

void main()
{
	gl_FragColor = texture2D(sampler, uv);
}