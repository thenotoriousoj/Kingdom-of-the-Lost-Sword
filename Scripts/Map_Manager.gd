extends Node

class_name Tile_Generator
var rng
var textures = {
	"grass": {
		"material": preload("res://Assets/Textures/Grass2/Grass007_1K-JPG.tres"),
		"scale": .1
	},
	"mountain": {
		"material": preload("res://Assets/Textures/Rock2/Rock050_1K-JPG.tres"),
		"scale": .1
		},
	"desert": {
		"material" : preload("res://Assets/Textures/Sand/Ground097_1K-JPG.tres"),
		"scale": .1,
	},
	"forest": {
		"material": preload("res://Assets/Textures/Grass2/Grass007_1K-JPG.tres"),
		"scale": .1
	},
	"dirt": {
		"material": preload("res://Assets/Textures/Dirt2/Ground082L_1K-JPG.tres"),
		"scale": .1
	}
}
# Elevation varies from 0 to 100
var biomes = {
	"lowerFields": {
		"humidity": {
			"low": .3,
			"high": 1
		},
		"elevation": {
			"low": 0,
			"high": 40
		},
		"terrainMultiplier": .7,
		"name": "lowerFields"
	},
	"upperFields": {
		"humidity": {
			"low": .3,
			"high": 1
		},
		"elevation": {
			"low": 40,
			"high": 60
		},
		"terrainMultiplier": 1,
		"name": "upperFields"
	},
	"Mountains": {
		"humidity": {
			"low": .3,
			"high": 1
		},
		"elevation": {
			"low": 60,
			"high": 100
		},
		"terrainMultiplier": 1.5,
		"name": "Mountains"
	},
	"desert": {
		"humidity": {
			"low": 0,
			"high": .3
		},
		"elevation": {
			"low": 0,
			"high": 40
		},
		"terrainMultiplier": .7,
		"name": "desert"
	},
	"salts": {
		"humidity": {
			"low": 0,
			"high": .3
		},
		"elevation": {
			"low": 40,
			"high": 60
		},
		"terrainMultiplier": .2,
		"name": "salts"
	},
	"volcano": {
		"humidity": {
			"low": 0,
			"high": .3
		},
		"elevation": {
			"low": 60,
			"high": 100
		},
		"terrainMultiplier": 2,
		"name": "volcano"
	},
}

var world_generator = {
	"lowerFields": [
		{"type": "grass", "priority": 5},
		{"type": "forest", "priority": 1},
	],
	"upperFields": [
		{"type": "grass", "priority": 1},
		{"type": "forest", "priority": 5},
		{"type": "mountain", "priority": 1},
	],
	"Mountains": [
		{"type": "forest", "priority": 2},
		{"type": "mountain", "priority": 5},
	],
	"desert": [
		{"type": "grass", "priority": 2},
		{"type": "desert", "priority": 6},
	],
	"salts": [
		{"type": "mountain", "priority": 3},
		{"type": "desert", "priority": 3},
	],
	"volcano": [
		{"type": "mountain", "priority": 10},
		{"type": "desert", "priority": 3},
	],
	
}
var relVertices = [
	'right',
	'bottom_right',
	'bottom_left',
	'left',
	'top_left',
	'top_right'
]
func _init(requestedSeed : int):
	rng = RandomNumberGenerator.new()
	rng.seed = requestedSeed
func generateBiome(humidity, elevation):
	humidity = (humidity + 1) / 2
	elevation = ((elevation + 1) / 2) * 100
	for biome in biomes:
		if (humidity <= biomes[biome].humidity.high && humidity >= biomes[biome].humidity.low):
			if (elevation <= biomes[biome].elevation.high && elevation >= biomes[biome].elevation.low):
				return biomes[biome]
	return biomes['upperFields']
		
func generateTile(biome):
	var worldPool = world_generator[biome]
	var totalPriority: int = 0
	for hextype in worldPool:
		totalPriority += hextype.priority
			
	if (totalPriority <=0): return null
	var num = rng.randi_range(1, totalPriority)
	for tileObj in worldPool:
		var priority = tileObj["priority"]
		if (num <= priority):
			var hex = {
				"type": tileObj["type"],
				"biome": biome,
				"texture": {
					"top": textures[tileObj["type"]],
					"side": textures["dirt"]
					},
			}
			return hex
		else:
			num -= priority
func generateChunkData(cx, cz, elevation_map, humidity_map, chunk_size, tileSize, worldGrid):
	var height_multiplier = 20 * tileSize.value
	var chunk_data = {
		'position': {
			"chunk": Vector2i(cx, cz),
			"hex": Vector2i(cx * chunk_size.value, cz * chunk_size.value),
			'actual': Vector3(cx * chunk_size.w, 0, cz * chunk_size.h)
			},
		}
	chunk_data['biome'] = generateBiome(humidity_map.get_noise_2d(chunk_data.position.hex.x, chunk_data.position.hex.y), elevation_map.get_noise_2d(chunk_data.position.hex.x, chunk_data.position.hex.y))
	var hex_key = {}
	var noiseMap = {}
	for x in range(chunk_size.value + 2):
		x -= 1
		for z in range(chunk_size.value + 2):
			z -= 1
			if !hex_key.has(x): hex_key[x] = {}
			if !hex_key[x].has(z): hex_key[x][z] = {}
			hex_key[x][z].vertices = {}
			var worldKeyX = x + (chunk_size.value * cx)
			var worldKeyZ = z + (chunk_size.value * cz)
			if !noiseMap.has(x): noiseMap[x] = {}
			noiseMap[x][z] = (elevation_map.get_noise_2d(worldKeyX, worldKeyZ) * height_multiplier + height_multiplier)
	for x in range(chunk_size.value):
		for z in range(chunk_size.value):
			var offset = x % 2
			var tile = generateTile(chunk_data.biome.name)
			hex_key[x][z].tile_data = tile
			hex_key[x][z].chunk_position = Vector2i(x, z)
			var x_pos = x * tileSize.w
			var z_pos = z * tileSize.h + (x % 2) * (tileSize.h / 2)
			var y_pos = noiseMap[x][z]
			hex_key[x][z].position = Vector3(x_pos, y_pos, z_pos)
			var worldKeyX = x + (chunk_size.value * cx)
			var worldKeyZ = z + (chunk_size.value * cz)
			hex_key[x][z].world_position = Vector2i(worldKeyX, worldKeyZ)
			# Array must be done in the following order [right, br, bl, left, tl, tr]
			var tl = noiseMap[x-1][z-1+offset] if (x != 0 and z !=0) else elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ - 1 + offset)  * height_multiplier + height_multiplier
			var t = noiseMap[x][z-1] if (z != 0) else elevation_map.get_noise_2d(worldKeyX, worldKeyZ - 1) *  height_multiplier + height_multiplier
			var tright = noiseMap[x+1][z-1+offset] if (x != chunk_size.value - 1 and z != 0) else elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ - 1 + offset) *  height_multiplier + height_multiplier
			var top_left_height = GetVertices(y_pos, tl, t, tileSize.value)
			var top_right_height = GetVertices(y_pos, t, tright, tileSize.value)
			hex_key[x][z].vertices.top_left = top_left_height.main
			hex_key[x][z].vertices.top_right = top_right_height.main
			if (z != 0 and not (offset == 0 and x == 0)):
				hex_key[x-1][z-1+offset].vertices.right = top_left_height['1']
			if (z != 0):
				hex_key[x][z-1].vertices.bottom_left = top_left_height['2']
				hex_key[x][z-1].vertices.bottom_right = top_right_height['1']
			if (x != chunk_size.value - 1 and not (offset == 0 and z == 0)):
				hex_key[x+1][z-1+offset].vertices.left = top_right_height['2']
			var bl
			var br
			var b
			# Assigning Vertices on Edge Cases
			if (z == 0 and offset == 0):
				if (x == 0):
					bl = elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
					noiseMap[x-1][z+offset] = bl
				else: bl = noiseMap[x-1][z+offset]
				br = elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
				noiseMap[x+1][z+offset] = br
				var left_height =  GetVertices(y_pos, bl, tl, tileSize.value)
				var right_height = GetVertices(y_pos, tright, br, tileSize.value)
				hex_key[x][z].vertices.left = left_height.main
				hex_key[x][z].vertices.right = right_height.main
			if (x == 0):
				if bl == null:
					bl = elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
					noiseMap[x-1][z+offset] = bl
				if (z == chunk_size.value - 1):
					b = elevation_map.get_noise_2d(worldKeyX, worldKeyZ + 1)  * height_multiplier + height_multiplier
					noiseMap[x][z+1] = b
				else: b = noiseMap[x][z+1]
				var bottom_left_height = GetVertices(y_pos, b, bl, tileSize.value)
				hex_key[x][z].vertices.bottom_left = bottom_left_height.main
				if !hex_key[x][z].vertices.has('keft'):
					var left_height = GetVertices(y_pos, bl, tl, tileSize.value)
					hex_key[x][z].vertices["left"] = left_height.main
			if (x == chunk_size.value - 1):
				if br == null: 
					br = elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
					noiseMap[x+1][z+offset] = br
				if (z == chunk_size.value - 1):
					b = elevation_map.get_noise_2d(worldKeyX, worldKeyZ + 1)  * height_multiplier + height_multiplier
					noiseMap[x][z+1] = b
				else: b = noiseMap[x][z+1]
				var bottom_right_height = GetVertices(y_pos, br, b, tileSize.value)
				hex_key[x][z].vertices.bottom_right = bottom_right_height.main
				if !hex_key[x][z].vertices.has('right') == null:
					var right_height = GetVertices(y_pos, tright, br, tileSize.value)
					hex_key[x][z].vertices.right = right_height.main
			if (z == chunk_size.value - 1):
				if b == null: 
					b = elevation_map.get_noise_2d(worldKeyX, worldKeyZ + 1) *  height_multiplier + height_multiplier
					noiseMap[x][z+1] = b
				if offset == 1:
					if bl == null: 
						bl = elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ + offset) * height_multiplier + height_multiplier
						noiseMap[x-1][z + offset] = bl
					if br == null: 
						br = elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
						noiseMap[x+1][z+offset] = br
					var left_height = GetVertices(y_pos, bl, tl, tileSize.value)
					var right_height = GetVertices(y_pos, tright, br, tileSize.value)
					hex_key[x][z].vertices.left = left_height.main
					hex_key[x][z].vertices.right = right_height.main
				elif offset == 0:
					if bl == null and x == 0:
						bl = elevation_map.get_noise_2d(worldKeyX - 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
						noiseMap[x-1][z+offset] = bl
					elif bl == null: bl = noiseMap[x-1][z+offset]
					if br == null and x == chunk_size.value - 1:
						br = elevation_map.get_noise_2d(worldKeyX + 1, worldKeyZ + offset)  * height_multiplier + height_multiplier
						noiseMap[x+1][z+offset] = br
					elif br == null: br = noiseMap[x+1][z+offset]
				var bottom_left_height = GetVertices(y_pos, b, bl, tileSize.value)
				var bottom_right_height = GetVertices(y_pos, br, b, tileSize.value)
				hex_key[x][z].vertices.bottom_left = bottom_left_height.main
				hex_key[x][z].vertices.bottom_right = bottom_right_height.main
				worldGrid[hex_key[x][z].world_position] = hex_key[x][z]
	var mesh = ArrayMesh.new()
	for x in range(chunk_size.value):
		for z in range(chunk_size.value):
			var hex_mesh = getHexMesh(tileSize.value, hex_key[x][z])
			hex_key[x][z].corners = hex_mesh.corners
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, hex_mesh.st.commit_to_arrays())
			mesh.surface_set_material(mesh.get_surface_count() - 1, hex_key[x][z].tile_data.texture.top.material)
	for x in range(chunk_size.value):
		for z in range(chunk_size.value):
			var walls_mesh = getWallMesh(hex_key[x][z], noiseMap)
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, walls_mesh.commit_to_arrays())
			mesh.surface_set_material(mesh.get_surface_count() - 1, hex_key[x][z].tile_data.texture.side.material)
			pass
	var shape = mesh.create_trimesh_shape()
	chunk_data["hex_key"] = hex_key
	chunk_data["mesh"] = mesh
	chunk_data["shape"] = shape
	return chunk_data
			
func GetVertices(origin, vertex1, vertex2, tile_size):
	var maxDifference = tile_size
	var newHeight = origin 
	var newHeightV1 = vertex1
	var newHeightV2 = vertex2
	var determinant = 1
	var determinantV1 = 1
	var determinantV2 = 1
	if abs(origin - vertex1) <= maxDifference:
		newHeight += vertex1
		determinant += 1
		determinantV1 += 1
		newHeightV1 += origin
	if abs(origin - vertex2) <= maxDifference:
		newHeight += vertex2
		determinant += 1
		determinantV2 += 1
		newHeightV2 += origin
	if abs(vertex1 - vertex2) <= maxDifference:
		newHeightV1 += vertex2
		newHeightV2 += vertex1
		determinantV1 += 1
		determinantV2 += 1
	return {
		'main': {
			"main": newHeight / determinant - origin,
			"1": newHeightV1 / determinantV1 - vertex1,
			"2": newHeightV2 / determinantV2 - vertex2,
		},
		'1': {
			"2": newHeight / determinant - origin,
			"main": newHeightV1 / determinantV1 - vertex1,
			"1": newHeightV2 / determinantV2 - vertex2,
		},
		'2': {
			"1": newHeight / determinant - origin,
			"2": newHeightV1 / determinantV1 - vertex1,
			"main": newHeightV2 / determinantV2 - vertex2,
		},
		}
func getHexMesh(tileSize, tile_data):
	# Array must be done in the following order [right, br, bl, left, tl, tr]
	var heightMap = [tile_data.vertices.right, tile_data.vertices.bottom_right, tile_data.vertices.bottom_left, tile_data.vertices.left, tile_data.vertices.top_left, tile_data.vertices.top_right]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var uv_scale =tile_data.tile_data.texture.top.scale
	var center = Vector3(0, 0, 0)


	# Hex corners (flat-top orientation)
	var angles = [
		deg_to_rad(0),
		deg_to_rad(60),
		deg_to_rad(120),
		deg_to_rad(180),
		deg_to_rad(240),
		deg_to_rad(300)
	]
	var radius = tileSize
	var corners = []
	for i in range(6):
		var cx = cos(angles[i]) * radius + tile_data.position.x
		var cz = sin(angles[i]) * radius + tile_data.position.z
		var y = heightMap[i].main + tile_data.position.y
		var origin = Vector3(cx, y, cz)
		corners.append(origin)
	center.y = heightMap.reduce(func(acc, num): return acc + num.main, 0.0) / 6
	center += tile_data.position
	var center_uv = Vector2(center.x, center.z) * uv_scale
	# Build triangles (center → edge pairs)
	for i in range(6):
		var a = corners[i]
		var b = corners[(i + 1) % 6]
		var uv_a = Vector2(a.x, a.z) * uv_scale
		var uv_b = Vector2(b.x, b.z) * uv_scale
		# triangle
		st.set_uv(center_uv)
		st.add_vertex(center)
		st.set_uv(uv_a)
		st.add_vertex(a)
		st.set_uv(uv_b)
		st.add_vertex(b)

	st.generate_normals()
	return {'st': st, 'corners': corners}

func getWallMesh(hex, noiseMap):
	var offset = hex.chunk_position.x % 2
	var relVector = [
		Vector2i(1, 0 + offset),
		Vector2i(0, 1),
		Vector2i(-1, 0 + offset),
		Vector2i(-1, -1 + offset),
		Vector2i(0, -1),
		Vector2i(1, -1 + offset)
	]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var corners = hex.corners
	for i in range(6):
		var plus = i + 1
		if plus > 5: plus = 0
		var anchorTile = noiseMap[hex.chunk_position.x + relVector[i].x][hex.chunk_position.y + relVector[i].y]
		var anchor1 = hex.vertices[relVertices[i]]['2']
		var anchor2 = hex.vertices[relVertices[plus]]['1']
		var height1 = anchorTile + anchor1
		var height2 = anchorTile + anchor2
		if (height1 - corners[i].y > .01 or height1 - corners[plus].y):
			var up1 = corners[i] 
			var up2 = corners[plus]
			up1.y = height1
			up2.y = height2
			create_wall_mesh(st, corners[i], corners[plus], up1, up2, hex.tile_data.texture.side.scale)
	st.generate_normals()
	return st
func create_wall_mesh(st: SurfaceTool, a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3, scale: float = 1.0) -> void:
	# Triangle 1
	var width = a1.distance_to(a2)
	var height_left = a1.distance_to(b1)
	var height_right = a2.distance_to(b2)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(a1)
	st.set_uv(Vector2(0, height_left * scale))
	st.add_vertex(b1)
	st.set_uv(Vector2(width * scale, 0))
	st.add_vertex(a2)
	st.set_uv(Vector2(width * scale, 0))
	st.add_vertex(a2)
	st.set_uv(Vector2(0, height_left * scale))
	st.add_vertex(b1)
	st.set_uv(Vector2(width * scale, height_right * scale))
	st.add_vertex(b2)
