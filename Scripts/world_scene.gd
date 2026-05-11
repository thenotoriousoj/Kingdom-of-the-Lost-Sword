extends Node3D
var VERSION = '0.1.6.1'
@export var Render_Distance := 2
@export var Physics_Render := 2
@export var Tile_Size := 2
@export var Chunk_Size := 16
@export var worldSeed : int
var world_grid = {}
var RNG = RandomNumberGenerator.new()
var ambience
var chunkLoader
@onready var chunkManager = preload("res://Scripts/ChunkManager.gd")
@onready var player = preload("res://Assets/Models/PlayerStarter.tscn")
@onready var AmbienceControl = preload("res://Scenes/WorldGen/Ambience.tscn")
@onready var BiomeLabel = $"Hex Label"
var playerInstance
var currentBiome
var currentHex
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load Ambience
	ambience = AmbienceControl.instantiate()
	add_child(ambience)
	#Generate World Tile System
	if (worldSeed == 0):
		RNG.randomize()
		worldSeed = RNG.seed
	playerInstance = player.instantiate()
	chunkLoader = chunkManager.new(worldSeed, playerInstance, Render_Distance, Physics_Render, Chunk_Size, Tile_Size, world_grid)
	add_child(chunkLoader)
	# Spawn Player
	playerInstance.position = chunkLoader._spawnplayer(Vector2i(4, 5))
	add_child(playerInstance)
	
	chunkLoader.hex_changed.connect(update_Hex_Label)
	chunkLoader.chunk_changed.connect(update_Chunk)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
func update_Chunk(chunk):
	ambience.biome = chunk.biome
func update_Hex_Label(playerLoc, hex):
	currentHex = hex.tile_data.type
	var terrain = hex.terrainData
	BiomeLabel.currentHex = str(playerLoc) + "   " + str(currentHex) + "  " + str(terrain)
	currentBiome = hex.tile_data.biome
	BiomeLabel.currentBiome = currentBiome
	pass
