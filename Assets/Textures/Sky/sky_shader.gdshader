shader_type sky;

uniform sampler2D sky_day;
uniform sampler2D sky_night;
uniform float time_of_day;
uniform vec3 rotation;
uniform vec3 sun_color : source_color;

mat3 rotation_matrix(vec3 r) {
	float cx = cos(r.x);
	float sx = sin(r.x);
	float cy = cos(r.y);
	float sy = sin(r.y);
	float cz = cos(r.z);
	float sz = sin(r.z);

	mat3 rotX = mat3(
	vec3(1.0, 0.0, 0.0),
	vec3(0.0, cx, sx),
	vec3(0.0, -sx, cx)
	);
	mat3 rotY = mat3(
		vec3(cy, 0.0, -sy),
		vec3(0.0, 1.0, 0.0),
		vec3(sy, 0.0, cy)
	);
	mat3 rotZ = mat3(
		vec3(cz, -sz, 0.0),
		vec3(sz, cz, 0.0),
		vec3(0.0, 0.0, 1.0)
	);

	return rotZ * rotY * rotX;
}

void sky() {
	// 1. get direction
	vec3 dir = normalize(rotation_matrix(rotation) * EYEDIR);

	// 2. convert to vec2 UV
	vec2 dayuv = vec2(
		atan(dir.x, dir.z) / (2.0 * PI) + 0.5,
		asin(dir.y) / PI + 0.5
	);
	dayuv.y = -dayuv.y;
	vec2 nightuv = vec2(
		atan(dir.x, dir.z) / (2.0 * PI) + 0.5,
		asin(dir.y) / PI + 0.5
	);
	// 3. sample textures (vec2 input → vec3 output)
	vec3 day = texture(sky_day, dayuv).rgb;
	vec3 night = texture(sky_night, nightuv).rgb;
	// 4. blend
	float blend = smoothstep(0.25, 0.75, time_of_day);
	vec3 sky_color = mix(day, night, blend);
	sky_color *= sun_color;
	COLOR = sky_color;
}