extends Node3D


var MapManager = preload("res://Scripts/Map_Manager.gd")
var Map
var hex_key = {}
var worldGrid = {}
var tileSize: Dictionary
var cx: int
var cz: int
var elevation_map: FastNoiseLite
var humidity
var chunk_Seed: int
var chunk_size: Dictionary
var chunk_data
@onready var hex_template = preload("res://Scenes/WorldGen/Hex/Hex_Template.tscn")
# Called when the node enters the scene tree for the first time.
func init() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _ready():
	Map = MapManager.new(chunk_Seed)
	position = Vector3(chunk_size.w * cx, 0, chunk_size.h * cz)
	var chunk_data = {
		'position': {
			'x': cx,
			'z': cz,
			},
		'biome': Map.generateBiome(humidity, elevation_map.get_noise_2d(position.x, position.z)),
		}
	for x in range(chunk_size.value):
		for z in range(chunk_size.value):
			var tile = Map.generateTile(chunk_data.biome.name)
			var hex = hex_template.instantiate()

			# Getting position values
			var x_pos = x * tileSize.w
			var offset = x % 2
			var z_pos = z * tileSize.h + (x % 2) * (tileSize.h / 2)
			var worldKeyX = x + (chunk_size.value * cx)
			var worldKeyZ = z + (chunk_size.value * cz)
			var y_pos = elevation_map.get_noise_2d(worldKeyX, worldKeyZ) * (20 * tileSize.value) + (20 * tileSize.value)
			#hex.position = Vector3(x_pos, y_pos, z_pos)
			# Modify hex to mesh with terrain
			var tl = elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ - 1 + offset) * (20 * tileSize.value) + (20 * tileSize.value)
			var t = elevation_map.get_noise_2d(worldKeyX, worldKeyZ - 1) * (20 * tileSize.value) + (20 * tileSize.value) 
			var tright = elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ - 1 + offset) * (20 * tileSize.value) + (20 * tileSize.value) 
			var br = elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ + offset) * (20 * tileSize.value) + (20 * tileSize.value)
			var b = elevation_map.get_noise_2d(worldKeyX, worldKeyZ + 1) * (20 * tileSize.value) + (20 * tileSize.value)
			var bl = elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ + offset) * (20 * tileSize.value) + (20 * tileSize.value)
			var right = _GetVertexHeight(y_pos, br, tright, tileSize.value)
			var bRight = _GetVertexHeight(y_pos, br, b, tileSize.value) 
			var bLeft = _GetVertexHeight(y_pos, b, bl, tileSize.value)
			var left = _GetVertexHeight(y_pos, tl, bl, tileSize.value) 
			var tLeft = _GetVertexHeight(y_pos, tl, t, tileSize.value)
			var tRight = _GetVertexHeight(y_pos, t, tright, tileSize.value)
			var heightMap = [right.vertex, bRight.vertex, bLeft.vertex, left.vertex, tLeft.vertex, tRight.vertex]
			var wallMap = [right.wall, bRight.wall, bLeft.wall, left.wall, tLeft.wall, tRight.wall]
			

			# instantiating
			hex.height_map = heightMap
			hex.wall_map = wallMap
			hex.top_texture = tile.texture.top
			hex.wall_texture = tile.texture.side
			hex.tileSize = tileSize.value
			hex.position = Vector3(x_pos, y_pos, z_pos)
			add_child(hex)
			# Storing hex position in chunk and world
			tile["instance"] = hex
			hex_key[Vector2i(x, z)] = tile
			var hexWorldPos = Vector2i(worldKeyX,worldKeyZ)
			worldGrid[hexWorldPos] = {"hex": tile}
			
func _GetVertexHeight(origin, vertex1, vertex2, tileSize):
	var maxDifference = tileSize
	var newHeight = origin 
	var determinant = 1
	if abs(origin - vertex1) <= maxDifference:
		newHeight += vertex1
		determinant += 1
	if abs(origin - vertex2) <= maxDifference:
		newHeight += vertex2
		determinant += 1
	newHeight = (newHeight / determinant - origin)
	if (determinant == 3 && newHeight > origin):
		return {
			'vertex': newHeight,
			"wall": 0
		}
	var wallHeight = max(0, origin - min(vertex1, vertex2))
	return {
		'vertex': newHeight,
		"wall": wallHeight
		}
