extends Node

class_name ChunkManager
signal chunk_changed(new_chunk: Vector2i)
signal player_ready(position: Vector3, player)

var worldSeed
var player
var render_distance
var tile_size: Dictionary
var chunk_size: Dictionary
var activeChunks = {}
var current_chunk := Vector2i(999999, 999999)
var chunk_queue: Array = []
var max_tasks_per_frame = 1
var elevation_noise := FastNoiseLite.new()
var humidity_noise := FastNoiseLite.new()
var world_grid
var st = SurfaceTool.new()
var currentplayerTile
var Map = preload("res://Scripts/Map_Manager.gd")
var tile_generator
@onready var chunk_scene = preload("res://Scenes/WorldGen/chunk.tscn")

var completed_chunks: Array = []

func _init(inputSeed : int, playerCharacter, renderDistance : int, chunk_Size : int, tileSize : float, worldGrid):
	worldSeed = inputSeed
	player = playerCharacter
	render_distance = renderDistance
	tile_size = {
		'value': tileSize,
		'w': tileSize * 1.5,
		'h': tileSize * sqrt(3)
	}
	chunk_size = {
		'value': chunk_Size,
		'w': tile_size.w * chunk_Size,
		'h': tile_size.h * chunk_Size
		}
	elevation_noise.seed = worldSeed
	elevation_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	elevation_noise.frequency = .03
	humidity_noise.seed = worldSeed
	humidity_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	humidity_noise.frequency = .03
	world_grid = worldGrid
	tile_generator = Map.new(worldSeed)
	_spawnplayer(Vector2i(4,4))
func _spawnplayer(center: Vector2i):
	var offset = center.x % 2
	var centerV = elevation_noise.get_noise_2d(center.x,  center.y) * (20 * tile_size.value) + (20 * tile_size.value)
	var tl = elevation_noise.get_noise_2d(center.x - 1,  center.y - 1 + offset) * (20 * tile_size.value) + (20 * tile_size.value)
	var t = elevation_noise.get_noise_2d(center.x,  center.y - 1) * (20 * tile_size.value) + (20 * tile_size.value)
	var tright = elevation_noise.get_noise_2d(center.x + 1,  center.y - 1 + offset) * (20 * tile_size.value) + (20 * tile_size.value)
	var br = elevation_noise.get_noise_2d(center.x + 1,  center.y + offset) * (20 * tile_size.value) + (20 * tile_size.value)
	var b = elevation_noise.get_noise_2d(center.x - 1, center.y + offset) * (20 * tile_size.value) + (20 * tile_size.value)
	var bl = elevation_noise.get_noise_2d(center.x - 1, center.y + offset) * (20 * tile_size.value) + (20 * tile_size.value)
	var totalSpawnHeight = 0
	totalSpawnHeight += (tl + t + centerV) / 3
	totalSpawnHeight += (tright + t + centerV) / 3
	totalSpawnHeight += (tright + br + centerV) / 3
	totalSpawnHeight += (b + br + centerV) / 3
	totalSpawnHeight += (b + bl + centerV) / 3
	totalSpawnHeight += (tl + bl + centerV) / 3
	totalSpawnHeight /= 6

	return Vector3(center.x, totalSpawnHeight + 30, center.y)

func _process(_delta):
	if player == null:
		return
	var q: int = round(player.global_position.x / (tile_size.w))
	var z_offset = (q % 2) * (tile_size.h / 2.0)
	var r = round((player.global_position.z - z_offset) / tile_size.h)
	var playerLoc = Vector2i(q, r)
	if world_grid.has(playerLoc):
		var newplayerTile = world_grid[playerLoc]
		if (currentplayerTile != newplayerTile):
			print('Players Hex Location: (', q, ', ', r, ') Hex Type: ', newplayerTile)
			currentplayerTile = newplayerTile
	var new_chunk = get_chunk(player.global_position)
	processChunkQueue()
	process_completed_chunks()
	if new_chunk != current_chunk:
		current_chunk = new_chunk
		emit_signal("chunk_changed", new_chunk)
		update_chunks(new_chunk)

func get_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(floor(pos.x / chunk_size.w), floor(pos.z / chunk_size.h))

func update_chunks(center: Vector2i):
	var new_active = {}
	for x in range(center.x - render_distance, center.x + render_distance + 1):
		for z in range(center.y - render_distance, center.y + render_distance + 1):
			var key = Vector2i(x, z)
			if activeChunks.has(key):
				new_active[key] = activeChunks[key]
				activeChunks.erase(key)
			else:
				chunk_queue.append({
					"type": "load",
					"x": x,
					"z": z
				})
	for key in activeChunks:
		chunk_queue.append({
			"type": "unload",
			"chunk": key
		})
	activeChunks = new_active
	
func spawn_chunk(cx: int, cz: int):
	var key = Vector2i(cx, cz)
	if activeChunks.has(key):
		return
	var chunkSeed = get_chunk_seed(cx, cz)
	var chunk = chunk_scene.instantiate()
	chunk.Map = tile_generator
	chunk.tileSize = tile_size
	chunk.cx = cx
	chunk.cz = cz
	chunk.elevation_map = elevation_noise
	chunk.humidity = (humidity_noise.get_noise_2d(cx, cz) + 1) / 2
	chunk.chunk_Seed = chunkSeed
	chunk.chunk_size = chunk_size
	chunk.worldGrid = world_grid
	add_child(chunk)
	activeChunks[key] = chunk
	
func get_chunk_seed(cx: int, cz: int) -> int:
	var hashedSeed = hash(str(worldSeed, "_", cx, "_", cz))
	return hashedSeed

func processChunkQueue():
	var tasks_to_run = min(max_tasks_per_frame, chunk_queue.size())
	for i in range(tasks_to_run):
		var task = chunk_queue.pop_front()
		execute_task(task)
	return
func execute_task(task):
	match task["type"]:
		'load':
			spawn_chunk(task['x'], task['z'])
		'unload':
			var key = task['chunk']
			var chunk = activeChunks.get(key)
			if chunk and is_instance_valid(chunk):
				chunk.queue_free()
			activeChunks.erase(key)
			
func process_completed_chunks():
	while completed_chunks.size() > 0:
		var data = completed_chunks.pop_front()
		var key = Vector2i(data.position.x, data.position.z)
		if activeChunks.has(key):
			continue
		var chunk = chunk_scene.instantiate()
		chunk.chunk_data = data
		add_child(chunk)
		activeChunks[key] = chunk
