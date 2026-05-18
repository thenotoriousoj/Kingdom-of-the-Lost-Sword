extends Node

class_name Meshy
func Hex_Mesh_Array(tileSize: int, tile_data: Dictionary):
	# Array must be done in the following order [right, br, bl, left, tl, tr]
	var heightMap = [tile_data.vertices.right, tile_data.vertices.bottom_right, tile_data.vertices.bottom_left, tile_data.vertices.left, tile_data.vertices.top_left, tile_data.vertices.top_right]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var uv_scale =tile_data.tile_data.attributes.scale
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
	if tile_data.tile_data.attributes.point != 0:
		center.y += tileSize * tile_data.tile_data.attributes.point
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
func Wall_Mesh(st: SurfaceTool, a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3, scale: float = 1.0) -> void:
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
