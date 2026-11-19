shader_type sky;

uniform vec4 zenith : source_color = vec4(0.12, 0.18, 0.30, 1.0);
uniform vec4 haze : source_color = vec4(0.43, 0.33, 0.39, 1.0);
uniform vec4 soft_cloud : source_color = vec4(0.66, 0.43, 0.38, 1.0);
uniform float celestial = 1.0;
uniform float daylight = 0.0;
uniform float cloud_detail : hint_range(0.0,1.0) = 0.6;

float speck(vec2 cell) {
	vec3 p = fract(vec3(cell.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float cloud_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 blend = smoothstep(vec2(0.0), vec2(1.0), fract(point));
	return mix(mix(speck(cell), speck(cell + vec2(1.0, 0.0)), blend.x), mix(speck(cell + vec2(0.0, 1.0)), speck(cell + vec2(1.0, 1.0)), blend.x), blend.y);
}

void sky() {
	vec3 ray = normalize(EYEDIR);
	float height = max(ray.y, 0.0);
	float above = smoothstep(-0.21, 0.08, ray.y);
	vec3 background = mix(haze.rgb, zenith.rgb, pow(smoothstep(0.0, 0.69, height), 0.58));
	background = mix(zenith.rgb * 0.67, background, above);
	vec2 cloud_dir = ray.xz / (0.22 + height) + vec2(3.2, -1.8);
	float cloud = 0.0;
	if (cloud_detail > 0.0) {
		float coarse = cloud_noise(cloud_dir * vec2(2.2, 1.25));
		float crest = cloud_detail > 0.75 ? cloud_noise(cloud_dir * vec2(4.1, 2.8) + 3.7) : 0.5;
		cloud = smoothstep(0.52, 0.72, coarse * 0.73 + crest * 0.27);
	}
	float horizon_tint = 1.0 - smoothstep(0.01, 0.52, height);
	float light_side = smoothstep(-0.85, 0.45, ray.x + ray.z * 0.23);
	background = mix(background, soft_cloud.rgb, cloud * horizon_tint * (0.14 + 0.24 * light_side) * above);
	float lunar = dot(ray, normalize(vec3(-0.12, 0.265, -0.94)));
	float disc = smoothstep(0.99951, 0.99962, lunar);
	float halo = smoothstep(0.967, 0.9999, lunar);
	float stars = step(0.992, speck(floor(SKY_COORDS * 584.0))) * smoothstep(0.20, 0.92, height);
	float night = (1.0 - daylight) * celestial;
	COLOR = background + vec3(0.73, 0.78, 0.91) * (disc * 0.76 + halo * halo * 0.080 + stars * 0.22) * night;
}
