extends Node
shader_type sky;

uniform sampler2D sky_day;
uniform sampler2D sky_night;
uniform float time_of_day : hint_range(0.0, 1.0);
uniform float rotation;

void sky() {
	vec3 dir = normalize(EYE_DIRECTION);

	vec2 uv = vec2(
		atan(dir.x, dir.z) / (2.0 * PI) + rotation,
		asin(dir.y) / PI + 0.5
	);

	vec3 day_col = texture(sky_day, uv).rgb;
	vec3 night_col = texture(sky_night, uv).rgb;

	// smooth blend curve (important for realism)
	float blend = smoothstep(0.25, 0.75, time_of_day);

	COLOR = mix(day_col, night_col, blend);
}
