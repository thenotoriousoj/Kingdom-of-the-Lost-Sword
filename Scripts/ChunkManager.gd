extends Node

class_name ChunkManager
signal chunk_changed(new_chunk: Dictionary)
signal chunk_generated(data)
signal hex_changed(new_hex: Dictionary)

var worldSeed
var player
var playerLoc
var render_distance
var physics_distance
var tile_size: Dictionary
var chunk_size: Dictionary
var active_chunks = {}
var cached_chunks = {}
var current_chunk := Vector2i(999999, 999999)
var chunk_queue: Array = []
var initialChunkLoaded = false
var max_tasks_per_frame = 1
var elevation_noise := FastNoiseLite.new()
var humidity_noise := FastNoiseLite.new()
var world_grid
var st = SurfaceTool.new()
var Map = preload("res://Scripts/Map_Manager.gd")
var tile_generator
@onready var chunk_scene = preload("res://Scenes/WorldGen/chunk.tscn")
var completed_chunks: Array = []


func _init(inputSeed : int, playerCharacter, renderDistance : int, physic: int,chunk_Size : int, tileSize : float, worldGrid):
	worldSeed = inputSeed
	player = playerCharacter
	render_distance = renderDistance
	physics_distance = physic
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
	elevation_noise.frequency = .015
	humidity_noise.seed = worldSeed
	humidity_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	humidity_noise.frequency = .015
	world_grid = worldGrid
	_spawnplayer(Vector2i(4,4))
	connect("chunk_generated", Callable(self, "handle_chunk_generated"))
	
func _spawnplayer(center: Vector2i):
	var offset = center.x % 2
	var centerV = elevation_noise.get_noise_2d(center.x,  center.y) * (20 * tile_size.value)
	var tl = elevation_noise.get_noise_2d(center.x - 1,  center.y - 1 + offset) * (20 * tile_size.value)
	var t = elevation_noise.get_noise_2d(center.x,  center.y - 1) * (20 * tile_size.value)
	var tright = elevation_noise.get_noise_2d(center.x + 1,  center.y - 1 + offset) * (20 * tile_size.value)
	var br = elevation_noise.get_noise_2d(center.x + 1,  center.y + offset) * (20 * tile_size.value)
	var b = elevation_noise.get_noise_2d(center.x - 1, center.y + offset) * (20 * tile_size.value)
	var bl = elevation_noise.get_noise_2d(center.x - 1, center.y + offset) * (20 * tile_size.value)
	var totalSpawnHeight = 100
	totalSpawnHeight += (tl + t + centerV) / 3
	totalSpawnHeight += (tright + t + centerV) / 3
	totalSpawnHeight += (tright + br + centerV) / 3
	totalSpawnHeight += (b + br + centerV) / 3
	totalSpawnHeight += (b + bl + centerV) / 3
	totalSpawnHeight += (tl + bl + centerV) / 3
	totalSpawnHeight /= 6
	return Vector3(center.x, totalSpawnHeight, center.y)

func _process(_delta):
	if player == null:
		return
	var q: int = round(player.global_position.x / (tile_size.w))
	var parity = ((q % 2) + 2) % 2
	var z_offset_global = parity * (tile_size.h / 2.0)
	var r = round(((player.global_position.z - z_offset_global) / tile_size.h))
	var newplayerLoc = Vector2i(q, r)
	if newplayerLoc != playerLoc:
		playerLoc = newplayerLoc
		var playerTile = world_grid.get(newplayerLoc, null) 
		if playerTile != null:
			emit_signal("hex_changed", playerLoc, playerTile)
			
	var new_chunk = get_chunk(player.global_position)
	processChunkQueue()
	if new_chunk != current_chunk:
		current_chunk = new_chunk
		update_chunks(new_chunk)
		if active_chunks.get(new_chunk) != null:
			emit_signal("chunk_changed", active_chunks.get(new_chunk).data)

func get_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(floor(pos.x / chunk_size.w), floor(pos.z / chunk_size.h))

func update_chunks(center: Vector2i):
	var to_unload = active_chunks.duplicate()
	for x in range(center.x - render_distance, center.x + render_distance + 1):
		for z in range(center.y - render_distance, center.y + render_distance + 1):
			var key = Vector2i(x, z)
			if to_unload.has(key):
				to_unload.erase(key)
			else:
				chunk_queue.append({
					"type": "load",
					"x": x,
					"z": z
				})
	for key in to_unload:
		chunk_queue.append({ "type": "unload", "chunk": key })
		
func spawn_chunk(cx: int, cz: int):
	var key = Vector2i(cx, cz)
	if active_chunks.has(key):
		return
	if cached_chunks.has(key):
		var cached_chunk = cached_chunks[key]
		var chunk = chunk_scene.instantiate()
		chunk.data = cached_chunk.data
		chunk.fromCache = true
		add_child(chunk)
		active_chunks[key] = chunk
	else:	
		generate_chunk(cx , cz)

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
			unload_chunk(task["chunk"])
func unload_chunk(key):
	if active_chunks.has(key) and is_instance_valid(active_chunks[key]):
		var chunk = active_chunks[key]
		cached_chunks[key] = {
			"data": chunk.data
		}
		chunk.queue_free()
		active_chunks.erase(key)
func generate_chunk(cx: int, cz: int):
	var chunkSeed = get_chunk_seed(cx, cz)
	var map = Map.new(chunkSeed)
	var chunkData = map.generateChunkData(cx, cz, elevation_noise, humidity_noise, chunk_size, tile_size, world_grid)
	# IMPORTANT: defer signal back to main thread
	call_deferred("on_chunk_generated", chunkData)
func on_chunk_generated(data):
	emit_signal("chunk_generated", data)
func handle_chunk_generated(data):
	var key = Vector2i(data.position.chunk.x, data.position.chunk.y)
	if active_chunks.has(key):
		return
	var chunk = chunk_scene.instantiate()
	chunk.data = data
	add_child(chunk)
	active_chunks[key] = chunk
	if (key == Vector2i(0, 0)):
		initialChunkLoaded = true
