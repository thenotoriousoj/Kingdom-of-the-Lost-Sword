extends Node3D
var VERSION = '0.1.3.1'
@export var Render_Distance := 2
@export var Physics_Render := 2
@export var Tile_Size := 2
@export var Chunk_Size := 16
@export var worldSeed : int
var world_grid = {}
var RNG = RandomNumberGenerator.new()

@onready var chunkManager = preload("res://Scripts/ChunkManager.gd")
@onready var player = preload("res://Scenes/Characters/Player/Capsule.tscn")
@onready var AmbienceControl = preload("res://Scenes/WorldGen/Ambience.tscn")
var playerInstance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var ambience = AmbienceControl.instantiate()
	#add_child(ambience)
	#Generate World Tile System
	if (worldSeed == 0):
		RNG.randomize()
		worldSeed = RNG.seed
	playerInstance = player.instantiate()
	var chunkLoader = chunkManager.new(worldSeed, playerInstance, Render_Distance, Physics_Render, Chunk_Size, Tile_Size, world_grid)
	add_child(chunkLoader)
	playerInstance.position = chunkLoader._spawnplayer(Vector2i(4, 5))
	add_child(playerInstance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
