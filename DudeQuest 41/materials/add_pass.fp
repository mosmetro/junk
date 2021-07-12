uniform lowp sampler2D source1;
uniform lowp sampler2D source2;

varying mediump vec2 var_texcoord0;

void main()
{
	vec4 first_color = texture2D(source1, var_texcoord0);
	vec4 second_color = texture2D(source2, var_texcoord0);
	gl_FragColor = first_color + second_color;
}