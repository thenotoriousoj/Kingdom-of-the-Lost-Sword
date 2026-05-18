extends Node

class_name Tile_Generator
var rng
var map_hex : Hex_Mapper
var World : World_Grid
var chunkSize : int
var tileSize : float
func _init(requestedSeed : int, WorldGrid, chunk_size, tile_size):
	rng = RandomNumberGenerator.new()
	rng.seed = requestedSeed
	map_hex = Hex_Mapper.new(tile_size)
	World = WorldGrid
	chunkSize = chunk_size
	tileSize = tile_size

func generateChunkData(cx, cz):
	World.generateChunkData(cx, cz)
	var chunkBiome = World.getChunkBiome(cx, cz)
	for x in range(chunkSize):
		for z in range(chunkSize):
			var hx = cx * chunkSize + x
			var hz = cz * chunkSize + z
			var tile = World.HexGrid[hx][hz]
			var offset = x % 2
			# Array must be done in the following order [right, br, bl, left, tl, tr]
			# Fetch nearby elevation data

			var y_pos = tile.position.y
			var top_left_height = map_hex.GetVertices(y_pos, tile.neighbor.tl, tile.neighbor.t)
			var top_right_height = map_hex.GetVertices(y_pos, tile.neighbor.t, tile.neighbor.tr)
			tile.vertices.top_left = top_left_height.main
			tile.vertices.top_right = top_right_height.main
			if (z != 0 and not (offset == 0 and x == 0)):
				World.HexGrid[hx-1][hz-1+offset].vertices.right = top_left_height['1']
			if (z != 0):
				World.HexGrid[hx][hz-1].vertices.bottom_left = top_left_height['2']
				World.HexGrid[hx][hz-1].vertices.bottom_right = top_right_height['1']
			if (x != chunkSize - 1 and not (offset == 0 and z == 0)):
				World.HexGrid[hx+1][hz-1+offset].vertices.left = top_right_height['2']
			# Assigning Vertices on Edge Cases
			if (z == 0 and offset == 0):
				var left_height =  map_hex.GetVertices(y_pos, tile.neighbor.bl, tile.neighbor.tl)
				var right_height = map_hex.GetVertices(y_pos, tile.neighbor.tr, tile.neighbor.br)
				World.HexGrid[hx][hz].vertices.left = left_height.main
				World.HexGrid[hx][hz].vertices.right = right_height.main
			if (x == 0):
				var bottom_left_height = map_hex.GetVertices(y_pos, tile.neighbor.b, tile.neighbor.bl)
				World.HexGrid[hx][hz].vertices.bottom_left = bottom_left_height.main
				if !World.HexGrid[hx][hz].vertices.has('left'):
					var left_height = map_hex.GetVertices(y_pos, tile.neighbor.bl, tile.neighbor.tl)
					World.HexGrid[hx][hz].vertices["left"] = left_height.main
			if (x == chunkSize - 1):
				var bottom_right_height = map_hex.GetVertices(y_pos, tile.neighbor.br, tile.neighbor.b)
				World.HexGrid[hx][hz].vertices.bottom_right = bottom_right_height.main
				if !World.HexGrid[hx][hz].vertices.has('right') == null:
					var right_height = map_hex.GetVertices(y_pos, tile.neighbor.tr, tile.neighbor.br)
					World.HexGrid[hx][hz].vertices.right = right_height.main
			if (z == chunkSize - 1):
				if offset == 1:
					var left_height = map_hex.GetVertices(y_pos, tile.neighbor.bl, tile.neighbor.tl)
					var right_height = map_hex.GetVertices(y_pos, tile.neighbor.tr, tile.neighbor.br)
					World.HexGrid[hx][hz].vertices.left = left_height.main
					World.HexGrid[hx][hz].vertices.right = right_height.main

				var bottom_left_height = map_hex.GetVertices(y_pos, tile.neighbor.b, tile.neighbor.bl)
				var bottom_right_height = map_hex.GetVertices(y_pos, tile.neighbor.br, tile.neighbor.b)
				World.HexGrid[hx][hz].vertices.bottom_left = bottom_left_height.main
				World.HexGrid[hx][hz].vertices.bottom_right = bottom_right_height.main
	var mesh = ArrayMesh.new()
	for x in range(chunkSize):
		for z in range(chunkSize):
			var hx: int = cx * chunkSize + x
			var hz: int = cz * chunkSize + z
			var hex_mesh = map_hex.meshy.Hex_Mesh_Array(tileSize, World.HexGrid[hx][hz])
			World.HexGrid[hx][hz].corners = hex_mesh.corners
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, hex_mesh.st.commit_to_arrays())
			var tile_data = World.HexGrid[hx][hz].tile_data
			var mat = getColor(chunkBiome, tile_data, cx, cz, x, z, tile_data.attributes.material)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	for x in range(chunkSize):
		for z in range(chunkSize):
			var hx = cx * chunkSize + x
			var hz = cz * chunkSize + z
			var walls_mesh = map_hex.getWallMesh(World.HexGrid[hx][hz])
			if walls_mesh.has_geometry:
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, walls_mesh.tool.commit_to_arrays())
				mesh.surface_set_material(mesh.get_surface_count() - 1, World.HexGrid[hx][hz].tile_data.attributes.side.material)
	var shape = mesh.create_trimesh_shape()
	World.ChunkGrid[cx][cz]["mesh"] = mesh
	World.ChunkGrid[cx][cz]["shape"] = shape
	return World.retrieveChunkData(cx, cz)
	
func getColor(biome, hex_data, cx, cz, x, z, texture):
	var tint = biome.get("tint").get(hex_data.type)
	if tint == null: return texture
	var neighbor_tints = []
	var multiplier = .4 if x == 0 or x == chunkSize - 1 or z == 0 or z == chunkSize - 1 else .2
	var leftTint = World.getChunkBiome(cx - 1, cz).get("tint")
	var rightTint =  World.getChunkBiome(cx + 1, cz).get("tint")
	var topTint = World.getChunkBiome(cx, cz - 1).get("tint")
	var bottomTint = World.getChunkBiome(cx, cz + 1).get("tint")
	if (x == 0 or x == 1) and leftTint:
		var tileTint = leftTint.get(hex_data.type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	elif (x == chunkSize - 1 or x == chunkSize - 2) and rightTint:
		var tileTint = rightTint.get(hex_data.type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	if (z == 0 or z == 1) and topTint:
		var tileTint = topTint.get(hex_data.type, Color(1, 1, 1))
		neighbor_tints.append(tileTint)
	elif (z == chunkSize - 1 or z == chunkSize - 2) and bottomTint:
		var tileTint = bottomTint.get(hex_data.type, Color(1, 1, 1))
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
	for key in World.Biomes.textures:
		var entry = World.Biomes.textures[key]
		if entry.material != texture:
			continue
		var map = entry.map
		var currentT = map.get(tint_key)
		if currentT:
			return currentT
		var new_texture = texture.duplicate()
		new_texture.albedo_color = tint
		World.Biomes.textures[tint_key] = new_texture
		return new_texture
	return texture
