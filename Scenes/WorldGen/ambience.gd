extends Node3D

@onready var sun = $Sun

var time := 0.0
var day_length := 120.0 # seconds for full day
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	var t = (time / day_length) * TAU
	sun.rotation.x = t
	var intensity = max(cos(t), 0.0)
	sun.light_energy = lerp(0.1, 1.5, intensity)
	pass
