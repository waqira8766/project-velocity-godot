shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec4 blue : source_color = vec4(0.15, 0.35, 0.42, 1.0);
uniform float motion = 0.0;
uniform float detail : hint_range(0.0, 1.0) = 1.0;
varying vec2 position_xz;

void vertex() {
	position_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float shift = TIME * motion;
	float interference = sin(position_xz.x * 0.26 + position_xz.y * 0.19 - shift * 0.66);
	float broad = sin(position_xz.y * 1.16 + position_xz.x * 0.37 + shift * 0.79 + interference * 1.46);
	float ripple = sin(position_xz.x * 1.32 - position_xz.y * 3.20 + shift * 1.09 + broad * 1.31);
	float reflected = smoothstep(0.72, 0.96, broad * 0.54 + ripple * 0.23 + interference * 0.23);
	ALBEDO = blue.rgb * (0.69 + 0.085 * broad + 0.095 * ripple * detail + 0.064 * interference);
	EMISSION = vec3(0.048, 0.090, 0.113) * (0.24 + reflected * detail * 0.60);
	ROUGHNESS = 0.40 + ripple * 0.125;
	METALLIC = 0.18;
}
