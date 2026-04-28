extends Node

class_name ChunkManager
signal chunk_changed(new_chunk: Vector2i)

var worldSeed
var player
var distance
var chunkSize
var tileSize
var hexWidth
var hexHeight
var chunkWidth
var chunkHeight
var activeChunks = {}
var current_chunk := Vector2i(999999, 999999)
var chunk_queue: Array = []
var max_tasks_per_frame = 2
var elevation_noise := FastNoiseLite.new()
var world
var st = SurfaceTool.new()
var currentplayerTile
@onready var chunk_scene = preload("res://Scenes/WorldGen/chunk.tscn")
var thread_pool: Array = []
var completed_chunks: Array = []

func _init(inputSeed : int, playerCharacter, renderDistance : int, chunk_Size : int, tile_size : float, worldGrid):
	worldSeed = inputSeed
	player = playerCharacter
	distance = renderDistance
	chunkSize = chunk_Size
	tileSize = tile_size
	hexWidth = tileSize * 1.5
	hexHeight = tileSize * sqrt(3)
	chunkWidth = hexWidth * chunkSize
	chunkHeight = hexHeight * chunkSize
	elevation_noise.seed = worldSeed
	elevation_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	elevation_noise.frequency = .03
	world = worldGrid

	
func _process(_delta):
	if player == null:
		return
	var q: int = round(player.global_position.x / (1.5 * tileSize))
	var z_offset = (q % 2) * (sqrt(3) * tileSize / 2.0)
	var r = round((player.global_position.z - z_offset) / (sqrt(3) * tileSize))
	var playerLoc = Vector2i(q, r)
	if world.has(playerLoc):
		var newplayerTile = world[playerLoc]
		if (currentplayerTile != newplayerTile):
			print('Players Hex Location: (', q, ', ', r, ') Hex Type: ', newplayerTile)
			currentplayerTile = newplayerTile
	var new_chunk = get_chunk(player.global_position)
	processChunkQueue()
	if new_chunk != current_chunk:
		current_chunk = new_chunk
		emit_signal("chunk_changed", new_chunk)
		update_chunks(new_chunk)

func get_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(floor(pos.x / chunkWidth), floor(pos.z / chunkHeight))

func update_chunks(center: Vector2i):
	var load_list: Array = []

	for x in range(center.x - distance, center.x + distance + 1):
		for z in range(center.y - distance, center.y + distance + 1):
			var key = Vector2i(x, z)
			if activeChunks.has(key):
				continue
			var dx = x - center.x
			var dz = z - center.y
			var dist_sq = dx * dx + dz * dz
			if (dist_sq > distance * distance):
				continue
			load_list.append({
				"x": x,
				"z": z,
				"dist": dist_sq
			})
	# 🔥 sort closest first
	load_list.sort_custom(func(a, b):
		return a["dist"] < b["dist"]
	)
	# add to queue in priority order
	for item in load_list:
		chunk_queue.append({
			"type": "load",
			"x": item["x"],
			"z": item["z"]
		})
	unload_far_chunks(center)
	
func spawn_chunk(cx: int, cz: int):
	var key = Vector2i(cx, cz)
	if activeChunks.has(key):
		return
	var chunk = chunk_scene.instantiate()

	chunk.chunk_x = cx
	chunk.chunk_z = cz
	chunk.worldGrid = world
	chunk.chunkSeed = get_chunk_seed(cx, cz)
	chunk.position = Vector3(cx * chunkWidth, 0, cz * chunkHeight)
	chunk.chunkSize = chunkSize
	chunk.tileSize = tileSize
	chunk.tileWidth = hexWidth
	chunk.tileHeight = hexHeight
	chunk.elevation_noise = elevation_noise
	add_child(chunk)
	chunk.generate()
	
	activeChunks[key] = chunk
	
func unload_far_chunks(center: Vector2i):
	for key in activeChunks.keys():
		var dx = key.x - center.x
		var dz = key.y - center.y

		if dx * dx + dz * dz > distance * distance:
			chunk_queue.append({
				"type": "unload",
				"chunk": key
			})
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
