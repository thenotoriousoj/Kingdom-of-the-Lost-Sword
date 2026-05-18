extends CharacterBody3D

@export var SPEED = 8.0
@export var RUN_MULTIPLIER = 2
@export var WALK_MULTIPLIER = .5
@export var JUMP_VELOCITY = 5
@onready var camera = $SpringArm3D/Camera3D
var hexBelow

func _ready() -> void:
	pass
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# For falling through map
	if global_position.y < -200:
		var Yteleport = hexBelow.position.y + 5 if hexBelow != null else 200
		global_position = Vector3(global_position.x, Yteleport, global_position.z)
		velocity = Vector3.ZERO
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# -------- MOVEMENT --------
	var speed_multiplier := 1.0
	if Input.is_action_pressed("walk"):
		speed_multiplier = WALK_MULTIPLIER
	elif Input.is_action_pressed("run"):
		speed_multiplier = RUN_MULTIPLIER
	var current_speed = SPEED * speed_multiplier
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var forward = camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	# flatten so camera tilt doesn't affect movement
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction = (forward * input_dir.y + right * input_dir.x).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	
	move_and_slide()
