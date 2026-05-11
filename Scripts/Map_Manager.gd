extends Node

class_name Tile_Generator
var rng
var materials = {
	"Dirt": preload("res://Assets/Textures/Dirt2/Ground082L_1K-JPG.tres"),
	"Grass": preload("res://Assets/Textures/Grass2/Grass007_1K-JPG.tres"),
	"Sand" : preload("res://Assets/Textures/Sand/Ground097_1K-JPG.tres"),
	"Stone": preload("res://Assets/Textures/Rock2/Rock050_1K-JPG.tres"),
}
var side_textures = {
	"Dirt": {
		"material": materials["Dirt"],
		"scale": .1,
		"map": {},
	},
	"Sandstone": {
		"material": materials["Sand"],
		"scale": .1,
		"map": {},
	},
	"Stone": {
		"material": materials["Stone"],
		"scale": .1,
		"map": {},
	},
}
var textures = {
	"Grass": {
		"material": materials["Grass"],
		"scale": .1,
		"map": {},
		"side": side_textures["Dirt"]
	},
	"Mountain": {
		"material": materials["Stone"],
		"scale": .1,
		"map": {},
		"side": side_textures["Stone"]
		},
	"Sand": {
		"material" : materials["Sand"],
		"scale": .1,
		"map": {},
		"side": side_textures["Sandstone"]
	},
	"Forest": {
		"material": materials["Grass"],
		"scale": .1,
		"map": {},
		"side": side_textures["Dirt"]
	},
	"Dirt": {
		"material": materials["Dirt"],
		"scale": .1,
		"map": {},
		"side": side_textures["Dirt"]
	}
}
# Elevation varies from 0 to 100
var biomes = {
	"Grassy Plains": {
		"humidity": .5,
		"elevation": .4,
		"terrainMultiplier": .8,
		"tint": {
			"Mountain": Color(0.985, 0.88, 0.828, 1.0),
			"Grass": Color (1, 1, 1)
		},
		"fog_tint": null,
		"light_energy": null
		
	},
	"Forest Peaks": {
		"humidity": .5,
		"elevation": .55,
		"terrainMultiplier": 1,
		"tint": {
			"Grass": Color(0.622, 0.999, 0.618, 1.0),
			"Forest": Color(0.622, 0.999, 0.618, 1.0),
		},
		"fog_tint": null,
		"light_energy": null
	},
	"Stone Plateaus": {
		"humidity": .5,
		"elevation": .7,
		"terrainMultiplier": 2,
		"tint": {
		},
		"fog_tint": Color(1, 1, 1),
		"light_energy": 1.1
	},
	"Arid Desert": {
		"humidity": .25,
		"elevation": .3,
		"terrainMultiplier": .8,
		"tint": {
			"Grass": Color(0.89, 0.71, 0.075, 1.0)
		},
		"fog_tint": Color(0.982, 0.717, 0.25, 1.0),
		"light_energy": 1.4
	},
	"Salt Flats": {
		"humidity": .2,
		"elevation": .4,
		"terrainMultiplier": .4,
		"tint": {
			"Desert": Color(0.982, 0.982, 0.982, 1.0)
		},
		"fog_tint": Color(0.982, 0.982, 0.982, 1.0),
		"light_energy": 1.6
	},
	"Volcanic Peaks": {
		"humidity": .35,
		"elevation": .65,
		"terrainMultiplier": 2,
		"tint": {
		},
		"fog_tint": Color(0.872, 0.426, 0.341, 1.0),
		"light_energy": .8
	},
}
var world_generator = {
	"Grassy Plains": [
		{"type": "Grass", "priority": 8},
		{"type": "Forest", "priority": 3},
		{"type": "Mountain", "priority": 1},
	],
	"Forest Peaks": [
		{"type": "Grass", "priority": 4},
		{"type": "Forest", "priority": 6},
		{"type": "Mountain", "priority": 1},
	],
	"Stone Plateaus": [
		{"type": "Forest", "priority": 2},
		{"type": "Grass", "priority": 2},
		{"type": "Mountain", "priority": 5},
	],
	"Arid Desert": [
		{"type": "Grass", "priority": 2},
		{"type": "Sand", "priority": 6},
	],
	"Salt Flats": [
		{"type": "Mountain", "priority": 3},
		{"type": "Sand", "priority": 3},
	],
	"Volcanic Peaks": [
		{"type": "Mountain", "priority": 10},
		{"type": "Sand", "priority": 3},
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
	humidity = (humidity + 1.0) / 2.0 
	elevation = ((elevation + 1.0) / 2.0)
	var humidity_weight = 1
	var elevation_weight = 1
	
	var biome_distances = []
	var distance

	for biome_name in biomes:
		var biome = biomes[biome_name]
		var dh = humidity - biome.humidity
		var de = elevation - biome.elevation
		# Euclidean distance
		distance = sqrt(pow(dh * humidity_weight, 2) + pow(de * elevation_weight, 2))
		biome_distances.append({
			"name": biome_name,
			"biome": biome,
			"distance": distance
		})
	biome_distances.sort_custom(func(a, b):
		return a.distance < b.distance
	)
	var b1 = biome_distances[0].biome
	b1.name = biome_distances[0].name
	return b1
func getTerrainMultiplier(elevation, humidity):
	humidity = (humidity + 1.0) / 2.0 
	elevation = (elevation + 1.0) / 2.0
	var humidity_weight = 1.0
	var elevation_weight = 1.0
	var sharpness = 20.0 # controls how “tight” biome regions are
	var weights = {}
	var total_weight = 0.0
	# STEP 1: compute weight for EVERY biome
	for biome_name in biomes:
		var biome = biomes[biome_name]
		var dh = humidity - biome.humidity
		var de = elevation - biome.elevation
		# squared distance (faster than sqrt, same behavior for weighting)
		var d2 = (dh * humidity_weight) * (dh * humidity_weight) + \
				 (de * elevation_weight) * (de * elevation_weight)
		# continuous influence function
		var w = exp(-d2 * sharpness)
		weights[biome_name] = w
		total_weight += w
	# STEP 2: normalize weights + blend
	var terrainMultiplier = 0.0
	for biome_name in weights:
		var biome = biomes[biome_name]
		var w = weights[biome_name] / total_weight

		terrainMultiplier += biome.terrainMultiplier * w

	return terrainMultiplier
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
			var texture = textures[tileObj["type"]]
			var hex = {
				"type": tileObj["type"],
				"biome": biome,
				"texture": {
					"top": texture,
					"side": texture.side
					},
			}
			return hex
		else:
			num -= priority
func generateChunkData(cx, cz, elevation_map, humidity_map, chunk_size, tileSize, worldGrid):
	var half_chunk = round(chunk_size.value / 2)
	var chunk_data = {
		'position': {
			"chunk": Vector2i(cx, cz),
			"hex": Vector2i(cx * chunk_size.value, cz * chunk_size.value),
			'actual': Vector3(cx * chunk_size.w, 0, cz * chunk_size.h)
			},
		}
	var chunk_CenterX = chunk_data.position.hex.x + half_chunk
	var chunk_CenterY = chunk_data.position.hex.y + half_chunk
	chunk_data['biome'] = generateBiome(humidity_map.get_noise_2d(chunk_CenterX, chunk_CenterY), elevation_map.get_noise_2d(chunk_CenterX, chunk_CenterY))
	var nearby_biomes = {
		"top": generateBiome(humidity_map.get_noise_2d(cx * chunk_size.value + half_chunk, (cz-1) * chunk_size.value + half_chunk), elevation_map.get_noise_2d(cx * chunk_size.value + half_chunk, (cz-1) * chunk_size.value + half_chunk)),
		"left": generateBiome(humidity_map.get_noise_2d((cx-1) * chunk_size.value + half_chunk, (cz) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx-1) * chunk_size.value + half_chunk, (cz) * chunk_size.value + half_chunk)),
		"right": generateBiome(humidity_map.get_noise_2d((cx+1) * chunk_size.value + half_chunk, (cz) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx+1) * chunk_size.value + half_chunk, (cz) * chunk_size.value + half_chunk)),
		"bottom": generateBiome(humidity_map.get_noise_2d((cx) * chunk_size.value + half_chunk, (cz+1) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx) * chunk_size.value + half_chunk, (cz+1) * chunk_size.value + half_chunk)),
		"top_left": generateBiome(humidity_map.get_noise_2d((cx-1) * chunk_size.value + half_chunk, (cz-1) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx-1) * chunk_size.value + half_chunk, (cz-1) * chunk_size.value + half_chunk)),
		"top_right": generateBiome(humidity_map.get_noise_2d((cx+1) * chunk_size.value + half_chunk, (cz-1) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx+1) * chunk_size.value + half_chunk, (cz-1) * chunk_size.value + half_chunk)),
		"bottom_left": generateBiome(humidity_map.get_noise_2d((cx-1) * chunk_size.value + half_chunk, (cz+1) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx-1) * chunk_size.value + half_chunk, (cz+1) * chunk_size.value + half_chunk)),
		"bottom_right": generateBiome(humidity_map.get_noise_2d((cx+1) * chunk_size.value + half_chunk, (cz+1) * chunk_size.value + half_chunk), elevation_map.get_noise_2d((cx+1) * chunk_size.value + half_chunk, (cz+1) * chunk_size.value + half_chunk)),
	}
	var height_multiplier = 15 * tileSize.value
	var hex_key = {}
	var noiseMap = {}
	var elevationMap = {}
	var humidityMap = {}
	for x in range(chunk_size.value + 2):
		x -= 1
		for z in range(chunk_size.value + 2):
			z -= 1
			if !hex_key.has(x): hex_key[x] = {}
			if !hex_key[x].has(z): hex_key[x][z] = {}
			hex_key[x][z].vertices = {}
			var worldKeyX = x + (chunk_size.value * cx)
			var worldKeyZ = z + (chunk_size.value * cz)
			var elevation = elevation_map.get_noise_2d(worldKeyX, worldKeyZ)
			var humidity = humidity_map.get_noise_2d(worldKeyX, worldKeyZ)
			if !noiseMap.has(x): noiseMap[x] = {}
			if !elevationMap.has(x): elevationMap[x] = {}
			if !humidityMap.has(x): humidityMap[x]= {}

			humidityMap[x][z] = humidity
			var terrainMultiplier = getTerrainMultiplier(elevation, humidity)
			elevationMap[x][z] = terrainMultiplier
			noiseMap[x][z] = elevation * height_multiplier * terrainMultiplier
			


	for x in range(chunk_size.value):
		for z in range(chunk_size.value):
			var offset = x % 2
			var tile = generateTile(chunk_data.biome.name)
			hex_key[x][z].tile_data = tile
			hex_key[x][z].terrainData = elevationMap[x][z]
			hex_key[x][z].chunk_position = Vector2i(x, z)
			var x_pos = x * tileSize.w
			var z_pos = z * tileSize.h + (x % 2) * (tileSize.h / 2)
			var y_pos = noiseMap[x][z]
			hex_key[x][z].position = Vector3(x_pos, y_pos, z_pos)
			var worldKeyX = x + (chunk_size.value * cx)
			var worldKeyZ = z + (chunk_size.value * cz)
			hex_key[x][z].tile_data.elevation = y_pos
			hex_key[x][z].tile_data.humidity = humidity_map.get_noise_2d(worldKeyX, worldKeyZ)
			hex_key[x][z].world_position = Vector2i(worldKeyX, worldKeyZ)
			# Array must be done in the following order [right, br, bl, left, tl, tr]
			# Fetch nearby elevation data
			var tl = noiseMap[x-1][z-1+offset]
			var t = noiseMap[x][z-1] 
			var tright = noiseMap[x+1][z-1+offset]
			var br = noiseMap[x+1][z+offset]
			var b = noiseMap[x][z+1] 
			var bl = noiseMap[x-1][z+offset] 
			
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
			# Assigning Vertices on Edge Cases
			if (z == 0 and offset == 0):
				var left_height =  GetVertices(y_pos, bl, tl, tileSize.value)
				var right_height = GetVertices(y_pos, tright, br, tileSize.value)
				hex_key[x][z].vertices.left = left_height.main
				hex_key[x][z].vertices.right = right_height.main
			if (x == 0):
				var bottom_left_height = GetVertices(y_pos, b, bl, tileSize.value)
				hex_key[x][z].vertices.bottom_left = bottom_left_height.main
				if !hex_key[x][z].vertices.has('left'):
					var left_height = GetVertices(y_pos, bl, tl, tileSize.value)
					hex_key[x][z].vertices["left"] = left_height.main
			if (x == chunk_size.value - 1):
				var bottom_right_height = GetVertices(y_pos, br, b, tileSize.value)
				hex_key[x][z].vertices.bottom_right = bottom_right_height.main
				if !hex_key[x][z].vertices.has('right') == null:
					var right_height = GetVertices(y_pos, tright, br, tileSize.value)
					hex_key[x][z].vertices.right = right_height.main
			if (z == chunk_size.value - 1):
				if offset == 1:
					var left_height = GetVertices(y_pos, bl, tl, tileSize.value)
					var right_height = GetVertices(y_pos, tright, br, tileSize.value)
					hex_key[x][z].vertices.left = left_height.main
					hex_key[x][z].vertices.right = right_height.main

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
			var tile_data = hex_key[x][z].tile_data
			var mat = getColor(chunk_data.biome.name, tile_data.type, tile_data.texture.top.material, x, z, nearby_biomes, chunk_size.value)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	for x in range(chunk_size.value):
		for z in range(chunk_size.value):
			var walls_mesh = getWallMesh(hex_key[x][z], noiseMap)
			if walls_mesh.has_geometry:
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, walls_mesh.tool.commit_to_arrays())
				mesh.surface_set_material(mesh.get_surface_count() - 1, hex_key[x][z].tile_data.texture.side.material)
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
func getColor(biome_name, hex_type, texture, x, z, nearby_biomes, chunk_size):
	var tint = biomes.get(biome_name).get("tint").get(hex_type)
	if tint == null: return texture
	var neighbor_tints = []
	var multiplier = .4 if x == 0 or x == chunk_size - 1 or z == 0 or z == chunk_size - 1 else .2
	var leftTint = nearby_biomes.left.get("tint")
	var rightTint =  nearby_biomes.right.get("tint")
	var topTint = nearby_biomes.top.get("tint")
	var bottomTint = nearby_biomes.bottom.get("tint")
	if (x == 0 or x == 1) and leftTint:
		var tileTint = leftTint.get(hex_type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	elif (x == chunk_size - 1 or x == chunk_size - 2) and rightTint:
		var tileTint = rightTint.get(hex_type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	if (z == 0 or z == 1) and topTint:
		var tileTint = topTint.get(hex_type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	elif (z == chunk_size - 1 or z == chunk_size - 2) and bottomTint:
		var tileTint = bottomTint.get(hex_type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	# Blend neighboring biome colors
	if neighbor_tints.size() > 0:
		var avg = Color(0, 0, 0)
		for c in neighbor_tints:
			avg += c
		avg /= neighbor_tints.size()
		tint = tint.lerp(avg, multiplier)
	# Slight color variation
	var variation = rng.randf_range(0.85, 1.0)
	tint = Color(
		tint.r * variation,
		tint.g * variation,
		tint.b * variation
	)
	var tint_key = tint.to_html()
	for key in textures:
		var entry = textures[key]
		if entry.material != texture:
			continue
		var map = entry.map
		if map.has(tint_key):
			return map[tint_key]
		var new_texture = texture.duplicate()
		new_texture.albedo_color = tint
		map[tint_key] = new_texture
		return new_texture
	return texture

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
	if tile_data.tile_data.type == "Mountain":
		center.y += tileSize / 1.5
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
	var has_geometry = false
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
		if (corners[i].y - height1 > .01 or corners[plus].y - height2 > .01):
			var up1 = corners[i] 
			var up2 = corners[plus]
			up1.y = height1
			up2.y = height2
			create_wall_mesh(st, corners[i], corners[plus], up1, up2, hex.tile_data.texture.side.scale)
			has_geometry=true
			
	st.generate_normals()
	return {
	"tool": st,
	"has_geometry": has_geometry
}
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
