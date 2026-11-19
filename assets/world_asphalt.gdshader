shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec4 base : source_color = vec4(0.22, 0.25, 0.29, 1.0);
uniform float reflections : hint_range(0.0, 1.0) = 0.8;
uniform float wetness : hint_range(0.0, 1.0) = 0.7;
uniform float material_detail : hint_range(0.0, 1.0) = 0.5;
varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float grain(vec2 p) {
	vec3 state = fract(vec3(p.xyx) * 0.1031);
	state += dot(state, state.yzx + 33.33);
	return fract((state.x + state.y) * state.z);
}

void fragment() {
	vec2 grit_coord = floor(world_xz * 63.0);
	float grit = grain(grit_coord);
	float large = 0.5;
	float smooth_patch = 0.75;
	float left_track = max(0.0, 1.0 - abs(abs(world_xz.x) - 4.5) * 1.4);
	float patch = 0.5;
	if (material_detail > 0.1) {
		large = grain(floor(world_xz * 1.35));
		smooth_patch = 0.72 + 0.22 * sin(world_xz.x * 1.2 + world_xz.y * 0.08);
		patch = smoothstep(0.43, 0.76, sin(world_xz.x * 0.53 + sin(world_xz.y * 0.13) * 1.4) * 0.42 + 0.52);
	}
	ALBEDO = base.rgb * (0.87 + 0.17 * grit + 0.068 * large - left_track * 0.072 - patch * 0.06);
	ROUGHNESS = mix(0.93, 0.48, smooth_patch * wetness);
	METALLIC = 0.08;
	float lane = 1.0 - smoothstep(0.10, 5.3, abs(abs(world_xz.x) - 6.3));
	float repeat_distance = abs(mod(world_xz.y + 4.0, 25.0) - 12.5);
	float near_station = 1.0 - smoothstep(0.3, 11.0, abs(world_xz.y + 52.4));
	float near_crossing = 1.0 - smoothstep(0.2, 9.0, abs(world_xz.y + 4.0));
	float along = max(1.0 - smoothstep(0.25, 12.5, repeat_distance), max(near_station, near_crossing));
	float zone = step(-305.0, world_xz.y) * step(world_xz.y, 55.0);
	float reach = lane * along * along;
	float broken = 0.38 + 0.36 * patch + 0.17 * grit;
	float smear = 0.62;
	if (material_detail > 0.1) {
		smear = 0.34 + 0.66 * smoothstep(0.35, 0.83, sin(world_xz.x * 4.6 + sin(world_xz.y * 0.72) * 0.43) * 0.5 + 0.5);
	}
	float road_reflect = zone * reflections * wetness * reach * broken * smear;
	vec3 tint = mix(vec3(0.29, 0.105, 0.032), vec3(0.035, 0.116, 0.171), step(0.0, world_xz.x));
	EMISSION = tint * road_reflect + vec3(0.004, 0.007, 0.011) * wetness;
}
