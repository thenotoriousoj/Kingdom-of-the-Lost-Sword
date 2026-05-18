extends SpringArm3D

@export var mouse_sensitivity := 0.005
@export var zoom_speed := 2.0
@export var zoom_smoothness := 10.0

@export var min_distance := 3.0
@export var max_distance := 15.0

var rotating := false

var yaw := 0.0
var pitch := deg_to_rad(-30)

var target_distance := 10.0

func _ready():
	yaw = rotation.y
	pitch = rotation.x

	target_distance = spring_length

func _process(delta):
	spring_length = lerp(
		spring_length,
		target_distance,
		zoom_smoothness * delta
	)

func _input(event):

	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			rotating = false

	if event is InputEventMouseButton:

		if event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_LEFT]:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			rotating = true

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clamp(
				target_distance - zoom_speed,
				min_distance,
				max_distance
			)

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clamp(
				target_distance + zoom_speed,
				min_distance,
				max_distance
			)

	if event is InputEventMouseMotion and rotating:

		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity

		pitch = clamp(
			pitch,
			deg_to_rad(-80),
			deg_to_rad(50)
		)

		rotation.y = yaw
		rotation.x = pitch
