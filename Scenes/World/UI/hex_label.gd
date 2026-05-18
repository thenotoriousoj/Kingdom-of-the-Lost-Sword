extends Label

var currentHex = '...'
var currentBiome = '...'
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0

	offset_right = -10
	offset_top = 10
	offset_left = -500  # gives it width room
	offset_bottom = 40
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	set_text("Current Hex Tile: %s\nCurrent Biome: %s" % [currentHex, currentBiome])
	pass
