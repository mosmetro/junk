uniform lowp sampler2D sampler0;
uniform lowp sampler2D sampler1;

varying mediump vec2 var_texcoord0;
varying mediump vec2 var_texcoord1;

uniform lowp vec4 water_level; // x - water level

const lowp vec2 distort_strength = vec2(0.06, 0.4);

varying highp vec2 v_position_r;
varying highp vec2 v_position_g;
varying highp vec2 v_position_b;

const lowp vec3 water_color = vec3(0.098, 0.173, 0.235) * 0.25;
const lowp vec3 water_line_color = vec3(0.4);

void main()
{
    lowp vec3 distort_sample;
    distort_sample.r = texture2D(sampler1, fract(v_position_r)).r;
    distort_sample.g = texture2D(sampler1, fract(v_position_g)).g;
    distort_sample.b = texture2D(sampler1, fract(v_position_b)).b;
    distort_sample -= 0.5;

    lowp vec2 distort = distort_sample.rg * distort_sample.b * distort_strength * (0.2 + 0.8 * var_texcoord1.y);
    
    lowp vec3 color = texture2D(sampler0, clamp(var_texcoord0 + distort, 0.0, 1.0)).rgb; 

    lowp float a = smoothstep(water_level.x, water_level.x + 0.01, clamp(var_texcoord0.y + distort.y, 0.0, 1.0)); 
    lowp vec3 combined_water_color = mix(water_line_color, water_color, a);   
    
    lowp float k = smoothstep(water_level.x, water_level.x + 0.7, var_texcoord0.y);
    lowp vec3 c = mix(color, water_color, k) + combined_water_color;
    gl_FragColor = vec4(c, 1.0);
}