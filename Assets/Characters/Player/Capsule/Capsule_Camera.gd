extends Camera3D



@export var mouse_sensitivity := 0.005
@export var zoom_speed := 2.0
@export var zoom_smoothness := 10.0
@export var min_distance := 3.0
@export var max_distance := 15.0

var rotating := false
var yaw := 0.0
var pitch := -30.0
var distance := 10.0
var target_distance := 10.0

func _ready():
	update_camera_position()

func _process(_delta):
	distance = lerp(distance, target_distance, zoom_smoothness * _delta)
	update_camera_position()
	
func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			rotating = false
	# Right-click to rotate
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			rotating = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			rotating = true

	# Mouse movement → rotate
	if event is InputEventMouseMotion and rotating:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity * 100
		pitch = clamp(pitch, -80, 50)

		update_camera_position()

	# Scroll → zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance += zoom_speed

		target_distance = clamp(target_distance, min_distance, max_distance)
		update_camera_position()

# -------------------
# CORE LOGIC
# -------------------
func update_camera_position():
	# Convert angles to direction
	var rot = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(pitch))

	# Position camera behind player at distance
	var offset = rot * Vector3(0, 0, distance)

	global_position = get_parent().global_position + offset

	# Always look at player
	look_at(get_parent().global_position, Vector3.UP)
