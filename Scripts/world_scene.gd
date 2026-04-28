extends Node3D

@export var Render_Distance := 2
@export var Tile_Size := 2
@export var Chunk_Size := 16
@export var worldSeed : int
var world_grid = {}
var RNG = RandomNumberGenerator.new()

@onready var chunkManager = preload("res://Scripts/ChunkManager.gd")
@onready var player = preload("res://Scenes/Characters/Player/Capsule.tscn")
var playerInstance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Generate World Tile System
	if (worldSeed == 0):
		RNG.randomize()
		worldSeed = RNG.seed
	playerInstance = player.instantiate()
	var chunkLoader = chunkManager.new(worldSeed, playerInstance, Render_Distance, Chunk_Size, Tile_Size, world_grid)
	add_child(chunkLoader)
	add_child(playerInstance)
	#var startingHeight = chunkManager.elevation_noise.get_noise_2d(0, 0) * (20 * Tile_Size) + (20 * Tile_Size)
	playerInstance.position = Vector3(0, 255, 0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
