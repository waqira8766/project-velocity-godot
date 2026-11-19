shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec4 mortar : source_color = vec4(0.28, 0.32, 0.36, 1.0);
uniform vec4 tint : source_color = vec4(0.17, 0.30, 0.38, 1.0);
uniform vec4 window_light : source_color = vec4(0.91, 0.63, 0.29, 1.0);
uniform vec2 bay = vec2(1.75, 3.16);
uniform float lamps : hint_range(0.0, 1.0) = 0.8;
varying vec3 point;
varying vec3 normal_world;

void vertex() {
	point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_world = MODEL_NORMAL_MATRIX * NORMAL;
}

float seed_for(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

void fragment() {
	float along = abs(normal_world.x) > 0.5 ? point.z : point.x;
	vec2 coordinate = vec2(along, point.y + 0.11) / bay;
	vec2 cell = fract(coordinate);
	float seed = seed_for(floor(coordinate));
	float wall_face = 1.0 - step(0.55, abs(normal_world.y));
	float border = step(0.12, cell.x) * (1.0 - step(0.88, cell.x));
	float window_band = step(0.21, cell.y) * (1.0 - step(0.88, cell.y));
	float mullion = step(0.025, abs(cell.x - 0.51));
	float glass = border * window_band * mullion * wall_face;
	float awning = smoothstep(0.08, 0.12, cell.y) * (1.0 - step(0.18, cell.y));
	float reveal = smoothstep(0.0, 0.24, cell.x) * (1.0 - smoothstep(0.85, 1.0, cell.x));
	vec3 wall = mortar.rgb * (0.74 + seed * 0.24 + awning * 0.15 + reveal * 0.15);
	vec3 reflected = tint.rgb * (0.37 + seed * 0.27 + cell.y * 0.43);
	float panel = step(0.72, seed) * (1.0 - step(0.72, cell.y));
	float activated = panel * lamps;
	vec3 pane = mix(reflected, window_light.rgb * (0.31 + cell.y * 0.18), activated * 0.87);
	ALBEDO = mix(wall, pane, glass);
	EMISSION = window_light.rgb * glass * activated * (0.22 + seed * 0.26);
	ROUGHNESS = mix(0.88, 0.54, glass);
	METALLIC = glass * 0.18;
}
