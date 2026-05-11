extends Node3D
@onready var mesh_instance = $MeshInstance3D
@onready var collision = $StaticBody3D/CollisionShape3D
var data
var fromCache = false
# Called when the node enters the scene tree for the first time.
func init() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
func _ready():

	position = data.position.actual
	mesh_instance.mesh = data.mesh
	collision.shape = data.shape
