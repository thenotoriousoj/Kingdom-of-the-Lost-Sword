extends Node

class_name World_Grid
var tile= {}
var chunk = {}
var ElevationMap = FastNoiseLite.new()
var HumidityMap = FastNoiseLite.new()
var HexGrid = {}
var ChunkGrid = {}
var ElevationGrid = {}
var HumidityGrid = {}
var TerrainGrid = {}
var Biomes: BiomeManager
var HeightMultiplier = 15
func _init(worldSeed, chunkSize, tileSize) -> void:
	ElevationMap.seed = worldSeed
	ElevationMap.noise_type = FastNoiseLite.TYPE_PERLIN
	ElevationMap.frequency = .015
	HumidityMap.seed = _humidityseed(worldSeed)
	HumidityMap.noise_type = FastNoiseLite.TYPE_PERLIN
	HumidityMap.frequency = .015
	tile.size = tileSize
	tile.width = tileSize * 1.5
	tile.height = tileSize * sqrt(3)
	chunk.size = chunkSize
	chunk.width = tile.width * chunkSize
	chunk.height = tile.height * chunkSize
	Biomes = BiomeManager.new(worldSeed)
	HeightMultiplier *= tileSize
	
func _humidityseed(worldSeed: int):
	var hashedSeed = hash(str(worldSeed))
	return hashedSeed
func getHex(Coordinate: Vector2i):
	if !HexGrid.get(Coordinate.x): HexGrid[Coordinate.x] = {}
	return HexGrid[Coordinate.x].get(Coordinate.y)

func retrieveChunkData(chunk_x, chunk_z):
	if !ChunkGrid.get(chunk_x): ChunkGrid[chunk_x] = {}
	var chunkData = ChunkGrid[chunk_x].get(chunk_z)
	if chunkData: return chunkData
	else:
		return generateChunkData(chunk_x, chunk_z)
		
func generateChunkData(cx, cz):
	var chunk_data = {
		'position': {
			"chunk": Vector2i(cx, cz),
			"hex": Vector2i(cx * chunk.size, cz * chunk.size),
			'actual': Vector3(cx * chunk.width, 0, cz * chunk.height)
			},
		}
	chunk_data['biome'] = getChunkBiome(cx, cz)
	generateChunkHeightMap(cx, cz)
	if !ChunkGrid.get(cx): ChunkGrid[cx] = {}
	ChunkGrid[cx][cz] = chunk_data
	for x in chunk.size:
		for z in chunk.size:
			var hx = chunk.size * cx + x
			var hz = chunk.size * cz + z
			generateTileData(cx, cz, x, z, hx, hz)
	return chunk_data
func generateChunkHeightMap(cx, cz):
	for x in chunk.size + 2:
		x -= 1
		for z in chunk.size + 2:
			z -= 1
			var wx = x + (chunk.size * cx)
			var wz = z + (chunk.size * cz)
			if !TerrainGrid.get(wx): TerrainGrid[wx] = {}
			if TerrainGrid[wx].get(wz): continue
			if !HumidityGrid.get(wx): HumidityGrid[wx] = {}
			if !ElevationGrid.get(wx): ElevationGrid[wx] = {}
			var Humidity = HumidityGrid[wx].get(wz)
			if !Humidity:
				Humidity = (HumidityMap.get_noise_2d(wx, wz) + 1) / 2
				HumidityGrid[wx][wz] = Humidity
			
			var Elevation = ElevationGrid[wx].get(wz)
			if !Elevation:
				Elevation = (ElevationMap.get_noise_2d(wx, wz) + 1) / 2
				ElevationGrid[wx][wz] = Elevation
			var terrainMultiplier = Biomes.getTerrainMultiplier(Elevation, Humidity)
			var terrain = Elevation * HeightMultiplier * terrainMultiplier
			TerrainGrid[wx][wz] = terrain
func getChunkBiome(cx, cz):
	var x = cx * chunk.size
	var z = cz * chunk.size
	if !ChunkGrid.get(x): ChunkGrid[x] = {}
	var chunkData = ChunkGrid[x].get(z)
	if chunkData: 
		return chunkData.biome
	else:
		var half_chunk = round(chunk.size / 2)
		var chunk_CenterX = x + half_chunk
		var chunk_CenterZ = z + half_chunk
		if !HumidityGrid.get(chunk_CenterX): HumidityGrid[chunk_CenterX] = {}
		var Humidity = HumidityGrid[chunk_CenterX].get(chunk_CenterZ)
		if !Humidity:
			Humidity = (HumidityMap.get_noise_2d(chunk_CenterX, chunk_CenterZ) + 1) / 2
			HumidityGrid[chunk_CenterX][chunk_CenterZ] = Humidity
		if !ElevationGrid.get(chunk_CenterX): ElevationGrid[chunk_CenterX] = {}
		var Elevation = ElevationGrid[chunk_CenterX].get(chunk_CenterZ)
		if !Elevation:
			Elevation = (ElevationMap.get_noise_2d(chunk_CenterX, chunk_CenterZ) + 1) / 2
			ElevationGrid[chunk_CenterX][chunk_CenterZ] = Elevation
		return Biomes.generateBiome(chunk_CenterX, chunk_CenterZ, Humidity, Elevation)
func generateTileData(cx, cz, x, z, hx, hz):
	var hex_data = {}
	var biome = ChunkGrid[cx][cz].biome
	hex_data.tile_data = Biomes.generateTile(biome)
	hex_data.hex_position = Vector2i(hx, hz)
	#hex_data.chunk_position = Vector2i(x, z)
	var x_pos = x * tile.width
	var z_pos = z * tile.height + (x % 2) * (tile.height / 2)
	var y_pos = TerrainGrid[hx][hz]
	var offset = x % 2
	
	hex_data.position = Vector3(x_pos, y_pos, z_pos)
	hex_data.neighbor = getSurroundingTerrainData(hx, hz, offset)
	hex_data.terrainData = TerrainGrid[hx][hz] / (ElevationGrid[hx][hz] * HeightMultiplier)
	if !HexGrid.get(hx): HexGrid[hx] = {}
	hex_data.vertices = {}
	HexGrid[hx][hz] = hex_data
	return hex_data
	
func getSurroundingTerrainData(hx, hz, offset):
	return {
		"tl":  TerrainGrid[hx-1][hz-1+offset],
		"t": TerrainGrid[hx][hz-1],
		"tr": TerrainGrid[hx+1][hz-1+offset],
		"br": TerrainGrid[hx+1][hz+offset],
		"b": TerrainGrid[hx][hz+1],
		"bl": TerrainGrid[hx-1][hz+offset] 
	}
