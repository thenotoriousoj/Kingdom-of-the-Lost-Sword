extends Node

class_name Hex_Mapper
var meshy: Meshy
var tileSize
var maxDifference = 1
var relVertices = [
	'right',
	'bottom_right',
	'bottom_left',
	'left',
	'top_left',
	'top_right'
]
var relVector = [
	'br',
	'b',
	'bl',
	'tl',
	't',
	'tr'
]
#var relVector = [
#		Vector2i(1, 0 + offset),
#		Vector2i(0, 1),
#		Vector2i(-1, 0 + offset),
#		Vector2i(-1, -1 + offset),
#		Vector2i(0, -1),
#		Vector2i(1, -1 + offset)
#	]
func _init(tile_size) -> void:
	meshy = Meshy.new()
	tileSize = tile_size
	maxDifference += tileSize
	
func GetVertices(origin, vertex1, vertex2):
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
func getWallMesh(hex):
	var has_geometry = false
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var corners = hex.corners
	for i in range(6):
		var plus = i + 1
		if plus > 5: plus = 0
		var anchorTile = hex.neighbor[relVector[i]]
		var anchor1 = hex.vertices[relVertices[i]]['2']
		var anchor2 = hex.vertices[relVertices[plus]]['1']
		var height1 = anchorTile + anchor1
		var height2 = anchorTile + anchor2
		if (corners[i].y - height1 > .01 or corners[plus].y - height2 > .01):
			var up1 = corners[i] 
			var up2 = corners[plus]
			up1.y = height1
			up2.y = height2
			meshy.Wall_Mesh(st, corners[i], corners[plus], up1, up2, hex.tile_data.attributes.side.scale)
			has_geometry=true
			
	st.generate_normals()
	return {
	"tool": st,
	"has_geometry": has_geometry
}
