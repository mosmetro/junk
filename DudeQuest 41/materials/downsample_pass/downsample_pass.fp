uniform lowp sampler2D source;
uniform vec4 source_size;

varying mediump vec2 var_texcoord0;

void main()
{
	vec2 pixel_size = vec2(1.0 / source_size.x, 1.0 / source_size.y);
	vec4 color = texture2D(source, var_texcoord0);
	color     += texture2D(source, var_texcoord0 + vec2( 1.0,  0.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2(-1.0,  0.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2( 0.0,  1.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2( 0.0, -1.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2( 1.0,  1.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2(-1.0, -1.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2( 1.0, -1.0) * pixel_size);
	color     += texture2D(source, var_texcoord0 + vec2(-1.0,  1.0) * pixel_size);
	gl_FragColor = color / 9.0;
}