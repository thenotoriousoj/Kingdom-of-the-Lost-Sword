extends Node3D
var VERSION = '0.1.6.1'
@export var Render_Distance := 3
@export var Tile_Size := 16
@export var Chunk_Size := 8
@export var worldSeed : int = 1
var RNG = RandomNumberGenerator.new()
@onready var chunkManager = preload("res://Scenes/World/Chunk System/Chunk_Manager.gd")
@onready var player = preload("res://Assets/Characters/Player/Capsule/Capsule.tscn")
@onready var AmbienceControl = preload("res://Scenes/World/Ambience/Ambience.tscn")
@onready var BiomeLabel = $"Hex Label"
var ambience
var playerInstance
var currentBiome
var currentHex
var world_grid: World_Grid
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load Ambience
	ambience = AmbienceControl.instantiate()
	add_child(ambience)
	#Generate World Tile System
	if (worldSeed == 0):
		RNG.randomize()
		worldSeed = RNG.seed
		$"FPS Label".worldSeed = str(worldSeed)
	playerInstance = player.instantiate()
	world_grid = World_Grid.new(worldSeed, Chunk_Size, Tile_Size)
	var chunkLoader = ChunkManager.new(worldSeed, playerInstance, Render_Distance, Chunk_Size, Tile_Size, world_grid)
	add_child(chunkLoader)
	chunkLoader.hex_changed.connect(update_Hex_Label)
	chunkLoader.chunk_changed.connect(update_Chunk)
	chunkLoader.initialChunkLoaded.connect(spawn_player)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
func spawn_player():
	var playerStartTile = world_grid.getHex(Vector2i(4,4))
	var playerStartPosition = Vector3(0,0,0)
	for vertex in playerStartTile.corners:
		playerStartPosition += vertex
	playerStartPosition /= playerStartTile.corners.size()
	playerStartPosition.y += playerStartTile.tile_data.attributes.point + 1
	playerInstance.position = playerStartPosition
	add_child(playerInstance)
	ambience.biome = world_grid.getChunkBiome(0, 0)
func update_Chunk(chunk):
	ambience.biome = chunk.biome
func update_Hex_Label(playerLoc, hex):
	currentHex = hex.tile_data.type
	var terrain = hex.terrainData
	BiomeLabel.currentHex = str(playerLoc) + "   " + str(currentHex) + "  " + str(terrain)
	currentBiome = hex.tile_data.biome.name
	BiomeLabel.currentBiome = currentBiome
	pass
