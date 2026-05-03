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

#func _notready():
#	Map = MapManager.new(chunk_Seed)
#	chunk_data = {
#		'position': {
#			'x': cx,
#			'z': cz,
#			},
#		'biome': Map.generateBiome(humidity, elevation_map.get_noise_2d(position.x, position.z)),
#		}
#	var height_multiplier = 20 * tileSize.value
#	position = Vector3(chunk_size.w * cx, 0, chunk_size.h * cz)
#	var noiseMap = {}
#	for x in range(chunk_size.value):
#		for z in range(chunk_size.value):
#			var worldKeyX = x + (chunk_size.value * cx)
#			var worldKeyZ = z + (chunk_size.value * cz)
#			if !noiseMap.has(x): noiseMap[x] = {}
#			noiseMap[x][z] = elevation_map.get_noise_2d(worldKeyX, worldKeyZ) * height_multiplier + height_multiplier
#	for x in range(chunk_size.value):
		#for z in range(chunk_size.value):
			#var tile = Map.generateTile(chunk_data.biome.name)
			#var hex = hex_template.instantiate()
#
			 #Getting position values
			#var x_pos = x * tileSize.w
#			var offset = x % 2
#			var z_pos = z * tileSize.h + (x % 2) * (tileSize.h / 2)
#			var worldKeyX = x + (chunk_size.value * cx)
#			var worldKeyZ = z + (chunk_size.value * cz)
#			var y_pos = elevation_map.get_noise_2d(worldKeyX, worldKeyZ) * height_multiplier + height_multiplier
#			# Modify hex to mesh with terrain
#			var tl = noiseMap[x-1][z-1+offset] if (noiseMap.has(x-1) and noiseMap[x-1].has(z-1+offset)) else elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ - 1 + offset)  * height_multiplier + height_multiplier
#			var t = noiseMap[x][z-1] if (noiseMap.has(x) and noiseMap[x].has(z-1)) else elevation_map.get_noise_2d(worldKeyX, worldKeyZ - 1) *  height_multiplier + height_multiplier
#			var tright = noiseMap[x+1][z-1+offset] if (noiseMap.has(x+1) and noiseMap[x+1].has(z-1+offset)) else elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ - 1 + offset) *  height_multiplier + height_multiplier
#			var br = noiseMap[x+1][z+offset] if (noiseMap.has(x+1) and noiseMap[x+1].has(z+offset)) else elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
#			var b = noiseMap[x][z+1] if (noiseMap.has(x) and noiseMap[x].has(z+1)) else elevation_map.get_noise_2d(worldKeyX, worldKeyZ + 1) * height_multiplier + height_multiplier
#			var bl = noiseMap[x-1][z+offset] if (noiseMap.has(x-1) and noiseMap[x-1].has(z+offset)) else elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ + offset) * height_multiplier + height_multiplier
#			var right = _GetVertexHeight(y_pos, br, tright)
#			var bRight = _GetVertexHeight(y_pos, br, b) 
#			var bLeft = _GetVertexHeight(y_pos, b, bl)
#			var left = _GetVertexHeight(y_pos, tl, bl) 
#			var tLeft = _GetVertexHeight(y_pos, tl, t)
#			var tRight = _GetVertexHeight(y_pos, t, tright)
#			var heightMap = [right.vertex, bRight.vertex, bLeft.vertex, left.vertex, tLeft.vertex, tRight.vertex]
#			var wallMap = [right.wall, bRight.wall, bLeft.wall, left.wall, tLeft.wall, tRight.wall]
			

			# instantiating
#			hex.height_map = heightMap
#			hex.wall_map = wallMap
#			hex.top_texture = tile.texture.top
#			hex.wall_texture = tile.texture.side
#			hex.tileSize = tileSize.value
#			hex.position = Vector3(x_pos, y_pos, z_pos)
#			add_child(hex)
			# Storing hex position in chunk and world
#			tile["instance"] = hex
#			hex_key[Vector2i(x, z)] = tile
#			var hexWorldPos = Vector2i(worldKeyX,worldKeyZ)
#			worldGrid[hexWorldPos] = {"hex": tile}
			
func _GetVertexHeight(origin, vertex1, vertex2):
	var maxDifference = 1
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
