extends Node3D

var chunk_data
@onready var hex_template = preload("res://Scenes/WorldGen/Hex/Hex_Template.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector3(chunk_data.position.global.x, 0, chunk_data.position.global.y)
	for hex in chunk_data.hex_array:
		var tileInstance = hex_template.instantiate()
		tileInstance.mesh = hex.meshData.mesh
		tileInstance.shape = hex.meshData.collision
		tileInstance.position = hex.position.chunk_global
		add_child(tileInstance)
		pass
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
