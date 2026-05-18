extends Node3D

@onready var sun = $Sun
@onready var moon = $Moon
@onready var env = $WorldEnvironment
@onready var sky_mat = env.environment.sky.sky_material
@onready var fog_albedo = env.environment.volumetric_fog_albedo
@onready var fog_density = env.environment.volumetric_fog_density
var time_of_day := 0.0 # 0 = day, 1 = night
var speed := 0.001
var rot := Vector3(0, 0, 0)
var day_count = 0
var skyrotation = 0
var biome
var current_sun_energy = 1.0
var current_moon_energy = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Day and Night cycle time
	time_of_day += delta * speed
	if (time_of_day >= 1):
		speed = -speed
		day_count += 1
	if (time_of_day < 0):
		speed = -speed
	# Sky Rotation
	skyrotation += delta * abs(speed) * 2
	var t = (smoothstep(0.2, 0.8, (sin(time_of_day) + 1.0) * 0.5) - .5) * 2
	var skyTune = PI / 2
	rot.x = skyrotation * skyTune + skyTune
	rot.z = t * 3
	# Send to Shader
	sky_mat.set_shader_parameter("time_of_day", time_of_day)
	# optional rotation (sky movement)
	sky_mat.set_shader_parameter("rotation", rot)
	# Sun and Moon Lighting
	sun.rotation.x = -rot.x

	rot.z = t * 3
	var sun_height = clamp((cos(time_of_day * PI) + 0.1) / 1.1, 0.0, 1.0)
	var base_sun_energy = sun_height
	var target_sun_energy = biome.light_energy * base_sun_energy if biome and biome.light_energy else base_sun_energy
	current_sun_energy = lerp(current_sun_energy, target_sun_energy, delta)
	sun.light_energy = current_sun_energy
	if base_sun_energy > 0.02:
		sun.shadow_enabled = true
		sun.shadow_opacity = base_sun_energy
	else:
		sun.shadow_enabled = false
	var base_moon_energy = (.25 - sun_height) * 4
	var target_moon_energy = biome.light_energy * base_moon_energy if biome and biome.light_energy else base_moon_energy
	moon.light_energy = current_moon_energy
	current_moon_energy = lerp(current_moon_energy, target_moon_energy, delta)
	moon.rotation.y = rot.x
	if base_moon_energy > 0.02:
		moon.shadow_enabled = true
		moon.shadow_opacity = base_moon_energy
	else:
		moon.shadow_enabled = false
	
	# sunsets
	var sunsetFade = smoothstep(0.4, 0.5, time_of_day) * (1.0 - smoothstep(0.5, 0.6, time_of_day))
	var daytimeColor = Color(1.0, 1.0, 1.0, 1.0)
	var transparency = Color(1, 1, 1,0)
	var sunsetColor = Color(0.976, 0.438, 0.182, 1.0)
	var skySunsetColor = Color(0.997, 0.743, 0.64, 1.0)
	sun.light_color = daytimeColor.lerp(sunsetColor, sunsetFade)
	var sun_color = transparency.lerp(skySunsetColor, sunsetFade)
	sky_mat.set_shader_parameter("sun_color", sun_color)
	# Fog
	var base_fog = env.environment.volumetric_fog_albedo
	var target_fog = base_fog
	var base_fog_density = env.environment.volumetric_fog_density
	var target_fog_density = base_fog_density
	if biome != null:
		if (biome.night_fog != 0 and sun_height <= 0.0):
			if biome.get("night_fog_tint"): target_fog = biome.night_fog_tint
			target_fog_density = biome.night_fog
		else:
			if biome.get("fog_tint"): target_fog = biome.fog_tint
			target_fog_density = biome.fog_density
		if (biome.morning_fog and speed < 0):
			var morning_fog = sunsetFade * .05
			target_fog_density += morning_fog
		if (biome.evening_fog and speed > 0):
			var evening_fog = sunsetFade * .05
			target_fog_density += evening_fog
	var blend_speed = .5
	var b = 1.0 - exp(-blend_speed * delta)
	env.environment.volumetric_fog_albedo = env.environment.volumetric_fog_albedo.lerp(
		target_fog,
		b
	)
	env.environment.volumetric_fog_density = lerp(
			base_fog_density, target_fog_density,
		b
	)
