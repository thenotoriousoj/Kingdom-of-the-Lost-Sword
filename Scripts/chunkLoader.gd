extends Node3D

@onready var MapManager = preload("res://Scripts/Map_Manager.gd")
@onready var HexTemplate = preload("res://Scenes/WorldGen/Hex/Hex_Template.tscn")
var Map
var chunkSize : int
var tileWidth : float
var tileHeight : float
var tileSize : float
var chunk_x : int
var chunk_z : int
var chunkSeed : int
var collision_body
var collision_enabled
var height_value
var elevation_noise
var hex_key = {}
var worldGrid
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Map = MapManager.new(chunkSeed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func generate():
	for x in range(chunkSize):
		for z in range(chunkSize):
			var tile = Map.generateTile("lowerFields")
			var hex = HexTemplate.instantiate()
			hex.texture = tile.texture
			hex.tileSize = tileSize
			#hex.scale = Vector3(tileSize, 1, tileSize)

			# Getting position values
			var x_pos = x * tileWidth
			var offset = x % 2
			var z_pos = z * tileHeight + (x % 2) * (tileHeight / 2)
			var worldKeyX = x + (chunkSize * chunk_x)
			var worldKeyZ = z + (chunkSize * chunk_z)
			var y_pos = elevation_noise.get_noise_2d(worldKeyX, worldKeyZ) * (20 * tileSize) + (20 * tileSize)
			hex.position = Vector3(x_pos, y_pos, z_pos)
			# Modify hex to mesh with terrain
			var tl = elevation_noise.get_noise_2d(worldKeyX - 1, worldKeyZ - 1 + offset) * (20 * tileSize) + (20 * tileSize)
			var t = elevation_noise.get_noise_2d(worldKeyX, worldKeyZ - 1) * (20 * tileSize) + (20 * tileSize)
			var tright = elevation_noise.get_noise_2d(worldKeyX + 1, worldKeyZ - 1 + offset) * (20 * tileSize) + (20 * tileSize)
			var br = elevation_noise.get_noise_2d(worldKeyX + 1, worldKeyZ + offset) * (20 * tileSize) + (20 * tileSize)
			var b = elevation_noise.get_noise_2d(worldKeyX, worldKeyZ + 1) * (20 * tileSize) + (20 * tileSize)
			var bl = elevation_noise.get_noise_2d(worldKeyX - 1, worldKeyZ + offset) * (20 * tileSize) + (20 * tileSize)
			var right = GetVertexHeight(y_pos, br, tright)
			var bRight = GetVertexHeight(y_pos, br, b)
			var bLeft = GetVertexHeight(y_pos, b, bl)
			var left = GetVertexHeight(y_pos, tl, bl)
			var tLeft = GetVertexHeight(y_pos, tl, t)
			var tRight = GetVertexHeight(y_pos, t, tright)
			hex.heightMap = [right.vertex, bRight.vertex, bLeft.vertex, left.vertex, tLeft.vertex, tRight.vertex]
			hex.wallMap = [right.wall, bRight.wall, bLeft.wall, left.wall, tLeft.wall, tRight.wall]
			if (worldKeyX == 0 && worldKeyZ == 0):
				print (hex.heightMap)
				print(hex.wallMap)
			add_child(hex)
			# Storing hex position in chunk and world
			tile["instance"] = hex
			hex_key[Vector2i(x, z)] = tile
			var hexWorldPos = Vector2i(worldKeyX,worldKeyZ)
			worldGrid[hexWorldPos] = {"hex": tile}
			
func GetVertexHeight(origin, vertex1, vertex2):
	var maxDifference = tileSize
	var newHeight = origin
	var determinant = 1
	if abs(origin - vertex1) <= maxDifference:
		newHeight += vertex1
		determinant += 1
	if abs(origin - vertex2) <= maxDifference:
		newHeight += vertex2
		determinant += 1
	newHeight = newHeight / determinant - origin
	if (determinant == 3 && newHeight > origin):
		return {
			'vertex': newHeight,
			"wall": 0
		}
	# Calculating Adjusted Vertices to properly calculate wall height
	var vertex1NewHeight = vertex1
	var vertex1Determinant = 1
	if abs(vertex1 - origin) <= maxDifference:
		vertex1NewHeight += origin
		vertex1Determinant += 1
	if abs(vertex1 - vertex2) <= maxDifference:
		vertex1NewHeight += vertex2
		vertex1Determinant += 1
	vertex1NewHeight = vertex1NewHeight / vertex1Determinant - vertex1
	
	var vertex2NewHeight = vertex1
	var vertex2Determinant = 1
	if abs(vertex2 - origin) <= maxDifference:
		vertex2NewHeight += origin
		vertex2Determinant += 1
	if abs(vertex2 - vertex1) <= maxDifference:
		vertex2NewHeight += vertex1
		vertex2Determinant += 1
	vertex2NewHeight = vertex2NewHeight / vertex2Determinant - vertex2
	
	# Calculating Wall Height
	var top = max(newHeight, vertex1NewHeight, vertex2NewHeight)
	var bottom = min(newHeight, vertex1NewHeight, vertex2NewHeight)
	var wallHeight = max(0, origin - min(vertex1, vertex2))
	return {
		'vertex': newHeight,
		"wall": wallHeight
		}
