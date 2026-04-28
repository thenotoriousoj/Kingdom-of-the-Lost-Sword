extends Node3D

var tileSize: float = 4
var heightMap: Array = []
var wallMap: Array = []
var texture = preload("res://Assets/Textures/PlainsTile.jpg")
var wall_texture = preload("res://Assets/Textures/MountainTile.jpg")
@onready var mesh_instance = $MeshInstance3D
@onready var collisionShape = $StaticBody3D/CollisionShape3D
func _ready(): 
	var mesh = generate_hex()
	mesh_instance.mesh = mesh
	var topMat = StandardMaterial3D.new()
	topMat.albedo_texture = texture
	var sidMat = StandardMaterial3D.new()
	sidMat.albedo_texture = wall_texture
	mesh.surface_set_material(0, topMat)
	mesh.surface_set_material(1, sidMat)
	#mesh_instance.material_override = mat
	finalize_collision()
	pass

func finalize_collision():
	var shape = mesh_instance.mesh.create_trimesh_shape()
	collisionShape.shape = shape
	
func generate_hex():
	# Array must be done in the following order [right, br, bl, left, tl, tr]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	
	var st_walls = SurfaceTool.new()
	st_walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_walls.set_smooth_group(-1)
	
	var center_uv = Vector2(0.5, 0.5)
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
		var x = cos(angles[i]) * radius
		var z = sin(angles[i]) * radius
		var y = 0
		if heightMap.size() == 6:
			y = heightMap[i]
		corners.append(Vector3(x, y, z))
		
	if heightMap.size() == 6: center.y = heightMap.reduce(func(acc, num): return acc + num) / 6
	# Build triangles (center → edge pairs)
	for i in range(6):
		var a = corners[i]
		var b = corners[(i + 1) % 6]
		var uv_a = Vector2(cos(angles[i]), sin(angles[i])) * 0.5 + Vector2(0.5, 0.5)
		var uv_b = Vector2(cos(angles[(i + 1) % 6]), sin(angles[(i + 1) % 6])) * 0.5 + Vector2(0.5, 0.5)
		# triangle
		st.set_uv(center_uv)
		st.add_vertex(center)
		st.set_uv(uv_a)
		st.add_vertex(a)
		st.set_uv(uv_b)
		st.add_vertex(b)
		
	if wallMap.size() == 6:
		for i in range(6):
			if (wallMap[i] > 0):
				var topA = corners[i]
				var topB = corners[(i + 1) % 6]

				# bottom points (same XZ, lower Y)
				var bottomY = min(topA.y, topB.y)

				#var bottomA = Vector3(topA.x, bottomY, topA.z)
				#var bottomB = Vector3(topB.x, bottomY, topB.z)
				var bottomA = Vector3(topA.x, bottomY - wallMap[i], topA.z)
				var bottomB = Vector3(topB.x, bottomY - wallMap[(i + 1) % 6], topB.z)

				# simple UVs for vertical stretch
				var scale = .3
				var uv_offset = Vector2(tileSize, tileSize) * 0.5 * scale
				var uv_topA = Vector2(0, 0) * scale - uv_offset
				var uv_topB = Vector2(1, 0) * scale - uv_offset
				var uv_bottomA = Vector2(0, 1) * scale - uv_offset
				var uv_bottomB = Vector2(1, 1) * scale - uv_offset
				# triangle 1
				st_walls.set_uv(uv_topA)
				st_walls.add_vertex(topA)
				st_walls.set_uv(uv_bottomA)
				st_walls.add_vertex(bottomA)
				st_walls.set_uv(uv_topB)
				st_walls.add_vertex(topB)
				# triangle 2
				st_walls.set_uv(uv_topB)
				st_walls.add_vertex(topB)
				st_walls.set_uv(uv_bottomA)
				st_walls.add_vertex(bottomA)
				st_walls.set_uv(uv_bottomB)
				st_walls.add_vertex(bottomB)
	st.generate_normals()
	st_walls.generate_normals()
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st_walls.commit_to_arrays())
	return mesh
