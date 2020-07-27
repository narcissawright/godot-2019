extends Spatial
onready var meshinstance = $"MeshInstance"
onready var target = $"Target"
var checkerboard = load('res://materials/checkerboard.tres')
var wall_mat = load('res://materials/wall_mat.tres')

# Find Normal from 3 vertices
func get_normal(x, y, z):
	return (x-y).cross(x-z).normalized()

func generate(border, player_spawn):
	
	for child in meshinstance.get_children():
		child.free()
	
	border.remove(1)
	
	# set up arrays
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	
	# wall height constant
	var wall_height = 5
	var uvs = PoolVector2Array()
	
	# obtain vertices and normals for the walls
	for i in range(border.size() - 1):
		var v1 = Vector3(border[i].x, wall_height, border[i].y)
		var v2 = Vector3(border[i+1].x, 0, border[i+1].y)
		var v3 = Vector3(border[i].x, 0, border[i].y)
		vertices.push_back(v1)
		vertices.push_back(v2)
		vertices.push_back(v3)
		
		var uv_length = v2.distance_to(v3)
		uvs.push_back(Vector2(0, wall_height))
		uvs.push_back(Vector2(uv_length, 0))
		uvs.push_back(Vector2(0, 0))
		
		var normal = get_normal(v2,v1,v3)
		normals.push_back(normal)
		normals.push_back(normal)
		normals.push_back(normal)
		v1 = Vector3(border[i].x, wall_height, border[i].y)
		v2 = Vector3(border[i+1].x, wall_height, border[i+1].y)
		v3 = Vector3(border[i+1].x, 0, border[i+1].y)
		vertices.push_back(v1)
		vertices.push_back(v2)
		vertices.push_back(v3)
		
		uvs.push_back(Vector2(0, wall_height))
		uvs.push_back(Vector2(uv_length, wall_height))
		uvs.push_back(Vector2(uv_length, 0))
		
		normal = get_normal(v2,v1,v3)
		normals.push_back(normal)
		normals.push_back(normal)
		normals.push_back(normal)
	
	# set surface
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# clear the arrays
	arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	vertices = PoolVector3Array()
	normals = PoolVector3Array()
	uvs = PoolVector2Array()
	
	# calculate floor triangles
	var floor_tris = Geometry.triangulate_polygon(border)
	
	# obtain vertices and normals for the floor
	for i in range(floor_tris.size() / 3):
		var v1 = Vector3(border[floor_tris[i*3]].x, 0, border[floor_tris[i*3]].y)
		var v2 = Vector3(border[floor_tris[i*3+1]].x, 0, border[floor_tris[i*3+1]].y)
		var v3 = Vector3(border[floor_tris[i*3+2]].x, 0, border[floor_tris[i*3+2]].y)
		vertices.push_back(v1)
		vertices.push_back(v2)
		vertices.push_back(v3)
		uvs.push_back(Vector2(border[floor_tris[i*3]].x, border[floor_tris[i*3]].y))
		uvs.push_back(Vector2(border[floor_tris[i*3+1]].x, border[floor_tris[i*3+1]].y))
		uvs.push_back(Vector2(border[floor_tris[i*3+2]].x, border[floor_tris[i*3+2]].y))
		var normal = get_normal(v3,v2,v1)
		normals.push_back(normal)
		normals.push_back(normal)
		normals.push_back(normal)
	
	# set surface
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# apply mesh
	meshinstance.mesh = arr_mesh
	meshinstance.mesh.surface_set_material(0, checkerboard)
	meshinstance.mesh.surface_set_material(1, checkerboard)
	meshinstance.create_trimesh_collision()
	
	var spawn = $'../Spawns/0'
	spawn.translation = Vector3(player_spawn.x, 0, player_spawn.y)
	target.translation = Vector3(player_spawn.x + 2.0, 1.0, player_spawn.y)
	#target2.translation = Vector3(player_spawn.y, 1.0, player_spawn.x)
