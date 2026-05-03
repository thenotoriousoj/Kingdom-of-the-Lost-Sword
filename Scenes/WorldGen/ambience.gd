extends Node3D

@onready var sun = $Sun
@onready var moon = $Moon
@onready var env = $WorldEnvironment
@onready var sky_mat = env.environment.sky.sky_material

var time_of_day := 0.0 # 0 = day, 1 = night
var speed := 0.01
var rot := Vector3(0, 0, 0)
var day_count = 0
var skyrotation = 0
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
	rot.x = skyrotation * skyTune + (PI / 2)
	rot.z = t * 3
	# Send to Shader
	sky_mat.set_shader_parameter("time_of_day", time_of_day)
	# optional rotation (sky movement)
	sky_mat.set_shader_parameter("rotation", rot)
	# Sun and Moon Lighting
	sun.rotation.x = -rot.x
	rot.z = t * 3
	sun.light_energy = 1 - t
	moon.light_energy = t / 3
	# sunsets
	var sunsetFade = smoothstep(0.35, 0.5, time_of_day) * (1.0 - smoothstep(0.5, 0.55, time_of_day))
	var daytimeColor = Color(1.0, 0.95, 0.8)
	var transparency = Color(1, 1, 1,0)
	var sunsetColor = Color(0.976, 0.438, 0.182, 1.0)
	var skySunsetColor = Color(0.997, 0.743, 0.64, 1.0)
	sun.light_color = daytimeColor.lerp(sunsetColor, sunsetFade)
	var sun_color = transparency.lerp(skySunsetColor, sunsetFade)
	sky_mat.set_shader_parameter("sun_color", sun_color)
	
	
