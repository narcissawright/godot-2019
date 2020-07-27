tool
extends Spatial

# editor tool
export var clear:bool = false setget clear

export var gen1:bool = false setget generate
export var gen2:bool = false setget generate2
#export var door_a := Vector3(-20,0,-20) setget position_door_a
#export var door_b := Vector3(0,0,-20) setget position_door_b

# 2D
var grid_size = 32
var rects = []
var border_points = []
var s_point = Vector2()
var player_spawn = Vector2()

# 3D
var checkerboard = load('res://materials/checkerboard.tres')
var wall_mat = load('res://materials/wall_mat.tres')
var blue_stucco = load('res://materials/blue_stucco.tres')

var door_frame_size = Vector3(0.1, 2.1, 1.1)


#func position_door_a(where):
#	door_a = where
#	$'DoorA'.translation = where
#func position_door_b(where):
#	door_b = where
#	$'DoorB'.translation = where


func rotate_to_2d(v1, v2, v3) -> Basis:
	
	var normal = get_normal(v1, v2, v3)
	
	var new_v1 = Vector3(0,0,0)
	var new_v2 = v2 - v1
	var new_v3 = v3 - v1
	
	var new_axis_x = new_v2.normalized()
	var new_axis_y = new_axis_x.cross(normal).normalized()
	var new_axis_z = normal
	
	var rotation_matrix = Basis(new_axis_x, new_axis_y, new_axis_z)
	
	return rotation_matrix
	
#	var rotated_v1 = rotation_matrix.xform_inv(new_v1)
#	var rotated_v2 = rotation_matrix.xform_inv(new_v2)
#	var rotated_v3 = rotation_matrix.xform_inv(new_v3)
#
#	var v1_2d = Vector2(rotated_v1.x, rotated_v1.y)
#	var v2_2d = Vector2(rotated_v2.x, rotated_v2.y)
#	var v3_2d = Vector2(rotated_v3.x, rotated_v3.y)
	


# rectangular
# L
# T
# hex
# oct


func generate2(f):
	clear_map()
	
	rotate_to_2d(Vector3(13,0,3), Vector3(10,0,5), Vector3(13,4,3))
	
	var room = {
		"room_id": 0,
		"material_list": ["checkerboard"],
		"border_points": [],
		"materials": [],
		"wall_obj": []
	}
#	var v1 = room.border_points[1]
#	var v2 = room.border_points[2]
#	var length = v1.distance_to(v2)
#	var door_distance_from_corner_min = 1.0
#	var door_width = 1.1
#	var valid_range = length - (door_distance_from_corner_min * 2.0)
#	var lerp_pos_center = rand_range(0.0, (valid_range/length) + 0.5)
#	var ratio = (door_width / 2.0) / length
#
#	var pos_left = v1.linear_interpolate(v2, lerp_pos_center - ratio)
#	var pos_center = v1.linear_interpolate(v2, lerp_pos_center)
#	var pos_right = v1.linear_interpolate(v2, lerp_pos_center + ratio)
#
#
#	var door = {
#		"what":"door", 
#		"pos_left": pos_left,
#		"pos_center": pos_center,
#		"pos_right": pos_right,
#		"height": 2.2,
#		"width": door_width 
#	}
#
#	room.wall_obj.push_back(door)



	var room_length = rand_range(3.0, 10.0)
	var room_width = rand_range(3.0, 10.0)
	var axis_1 = Vector2(randf(), randf()).normalized()
	var axis_2 = axis_1.tangent()
	axis_1 *= room_length
	axis_2 *= room_width
	if randi() % 2 == 0:
		axis_2 = -axis_2
	if randi() % 2 == 0:
		axis_1 = -axis_1
	
	#print("axis_1: ", axis_1, "  axis_2: ", axis_2)
	
	
	#starting point
	room.border_points.push_back(Vector2.ZERO)
	#line segment 1
	room.border_points.push_back(axis_1)
	room.materials.push_back(0)
	room.wall_obj.push_back({})
	#line segment 2
	room.border_points.push_back(axis_1 + axis_2)
	room.materials.push_back(0)
	room.wall_obj.push_back({})
	#line segment 3
	room.border_points.push_back(axis_2)
	room.materials.push_back(0)
	room.wall_obj.push_back({})
	#line segment 4
	room.border_points.push_back(Vector2.ZERO)
	room.materials.push_back(0)
	room.wall_obj.push_back({})

	var total_rooms = 1
	
	asdf_generate(room)

func asdf_generate(room):
	# for each line segment:
	var wall_height = 4.0
	
	# set up arrays
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var vertices = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	
	for i in range (room.border_points.size() - 1):
		var vertex_array = []
		if room.wall_obj[i].size() > 0:
			print("Wall Object!! Do other logic!")
		else:
			var p1 = room.border_points[i]
			var p2 = room.border_points[i+1]
			vertex_array.push_back(Vector3(p1.x, 0, p1.y))
			vertex_array.push_back(Vector3(p1.x, wall_height, p1.y))
			vertex_array.push_back(Vector3(p2.x, wall_height, p2.y))
			vertex_array.push_back(Vector3(p2.x, 0, p2.y))
			vertex_array.push_back(Vector3(p1.x, 0, p1.y))
		var rotation_matrix = rotate_to_2d(vertex_array[1], vertex_array[2], vertex_array[3])
		var vertex_array_2d = []
		for j in range (vertex_array.size()):
			var rotated = rotation_matrix.xform_inv(vertex_array[j])
			var vertex_2d = Vector2(rotated.x, rotated.y)
			vertex_array_2d.push_back(vertex_2d)
		var polygon_2d = vertex_array_2d.duplicate()
		
		var triangle_indices = Geometry.triangulate_polygon(polygon_2d)
		print (triangle_indices)
		var arraymesh_vertices = PoolVector3Array()
		for j in range (vertex_array_2d.size()):
			vertex_array_2d[i] -= vertex_array_2d[0]
		for j in range (triangle_indices.size() / 3):
			vertex_array
			vertices.push_back(vertex_array[j])
			vertices.push_back(vertex_array[j+1])
			vertices.push_back(vertex_array[j+2])
			var normal = get_normal(vertex_array[j], vertex_array[j+1], vertex_array[j+2])
			normals.push_back(normal)
			normals.push_back(normal)
			normals.push_back(normal)
			uvs.push_back(vertex_array_2d[j])
			uvs.push_back(vertex_array_2d[j+1])
			uvs.push_back(vertex_array_2d[j+2])
	
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
	
	
	var border = room.border_points
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
	var meshinstance = $"MeshInstance"
	meshinstance.mesh = arr_mesh
	meshinstance.mesh.surface_set_material(0, blue_stucco)
	meshinstance.mesh.surface_set_material(1, checkerboard)
	meshinstance.create_trimesh_collision()

func generate3_mesh(room):
	pass


func make_wall_new(border_points):
	pass


	
func make_door_wall(point1:Vector2, point2:Vector2, door_left:Vector2, door_right:Vector2, door_height:float) -> Dictionary:
	
	
	var wall_height = 4.0

	var vertices = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()

	var v1 = Vector3(point1.x, wall_height, point1.y)
	var v2 = Vector3(point2.x, 0, point2.y)
	var v3 = Vector3(point1.x, 0, point1.y)
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
	v1 = Vector3(point1.x, wall_height, point1.y)
	v2 = Vector3(point2.x, wall_height, point2.y)
	v3 = Vector3(point2.x, 0, point2.y)
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
	
	return {"vertices": vertices, "uvs": uvs, "normals": normals}


func make_flat_wall(point1:Vector2, point2:Vector2) -> Dictionary:
	var wall_height = 4.0

	var vertices = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()

	var v1 = Vector3(point1.x, wall_height, point1.y)
	var v2 = Vector3(point2.x, 0, point2.y)
	var v3 = Vector3(point1.x, 0, point1.y)
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
	v1 = Vector3(point1.x, wall_height, point1.y)
	v2 = Vector3(point2.x, wall_height, point2.y)
	v3 = Vector3(point2.x, 0, point2.y)
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
	
	return {"vertices": vertices, "uvs": uvs, "normals": normals}
	
func generate2_mesh(room):
	
	var border = room.border_points
	print(border)
	
	var meshinstance = $"MeshInstance"
	
	# set up arrays
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	var uvs = PoolVector2Array()
	
	# wall height constant
	var wall_height = 5
	var door_width = 1.1
	var door_height = 2.2
	
	# obtain vertices and normals for the walls
	for i in range(border.size() - 1):
		
		if room.wall_obj[i].size() > 0:
			if room.wall_obj[i].what == 'door':
				var wall_data = make_door_wall(border[i], border[i+1], room.wall_obj[i].pos_left, room.wall_obj[i].pos_right, room.wall_obj[i].height)
				vertices.append_array(wall_data.vertices)
				uvs.append_array(wall_data.uvs)
				normals.append_array(wall_data.normals)
		else:
			var wall_data = make_flat_wall(border[i], border[i+1])
			vertices.append_array(wall_data.vertices)
			uvs.append_array(wall_data.uvs)
			normals.append_array(wall_data.normals)
	
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
	meshinstance.mesh.surface_set_material(0, blue_stucco)
	meshinstance.mesh.surface_set_material(1, checkerboard)
	meshinstance.create_trimesh_collision()

func generate(state):
	clear_map()
	create_room()
	generate_mesh(border_points)
	
func clear(f):
	clear_map()
	
func clear_map():
	rects = []
	var meshinstance = $"MeshInstance"
	var spawn = $'../Spawns/0'
	for child in meshinstance.get_children():
		child.free()
	meshinstance.mesh = ArrayMesh.new()
	spawn.translation = Vector3()

func make_rect():
	# Create rectangle
	var w = 3 + (randi() % 15)
	var l = 3 + (randi() % 15)
	
	# find upper left corner
	var x = randi() % (grid_size - w - 1)
	var y = randi() % (grid_size - l - 1)
	
	return Rect2(x,y,w,l)

func slight_offset(dir):
	match dir:
		"up":
			return Vector2(0, -0.01)
		"down":
			return Vector2(0, 0.01)
		"left":
			return Vector2(-0.01, 0)
		"right":
			return Vector2(0.01, 0)

func create_room():
	rects.append(make_rect())
	player_spawn = rects[0].position + (rects[0].size * rand_range(0.2, 0.8))
	for i in range (1 + (randi() % 4)):
		var new_rect = make_rect()
		while new_rect.intersects(rects[0]) == false:
			new_rect = make_rect()
		rects.append(new_rect)
	var current_rect = start_point()
	s_point = rects[current_rect].position
	var trace_point = s_point
	border_points = [s_point]
	trace_border(trace_point, "right")
	
func trace_border(point, march_dir):
	#print("trace border: " + str(point) + " - heading " + march_dir)
	if border_points.back() == s_point && border_points.size() > 1:
		return
	if border_points.size() > 150: # clean this up later
		print("BAD ERROR, NEVER REACHED STARTING POINT??")
		return
	match march_dir:
		"right":
			for i in range (grid_size):
				point += Vector2.RIGHT
				if is_in_any_rect(point + slight_offset("right") + slight_offset("up")):
					border_points.append(point)
					trace_border(point, "up")
					return
				elif is_in_any_rect(point + slight_offset("right") + slight_offset("down")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "down")
					return
		"down":
			for i in range (grid_size):
				point += Vector2.DOWN
				if is_in_any_rect(point + slight_offset("down") + slight_offset("right")):
					border_points.append(point)
					trace_border(point, "right")
					return
				elif is_in_any_rect(point + slight_offset("down") + slight_offset("left")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "left")
					return
		"left":
			for i in range (grid_size):
				point += Vector2.LEFT
				if is_in_any_rect(point + slight_offset("left") + slight_offset("down")):
					border_points.append(point)
					trace_border(point, "down")
					return
				elif is_in_any_rect(point + slight_offset("left") + slight_offset("up")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "up")
					return
		"up":
			for i in range (grid_size):
				point += Vector2.UP
				if is_in_any_rect(point + slight_offset("up") + slight_offset("left")):
					border_points.append(point)
					trace_border(point, "left")
					return
				elif is_in_any_rect(point + slight_offset("up") + slight_offset("right")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "right")
					return

func start_point():
	#find upper left corner that is not shared
	for i in range (rects.size()):
		var x_in = is_in_any_rect(rects[i].position + slight_offset("left"))
		var y_in = is_in_any_rect(rects[i].position + slight_offset("up"))
		if !x_in and !y_in:
			return i
	print("ERROR - start_point() - no result found")

func is_in_any_rect(point):
	# is this point in any rect?
	for i in range (rects.size()):
		if rects[i].position.x <= point.x && rects[i].end.x >= point.x:
			if rects[i].position.y <= point.y && rects[i].end.y >= point.y:
				return true
	return false

# Find Normal from 3 vertices
func get_normal(x, y, z):
	return (x-y).cross(x-z).normalized()

	
	

func generate_mesh(border):
	
	var meshinstance = $"MeshInstance"
	var spawn = $'../Spawns/0'
	
	# set up arrays
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	var uvs = PoolVector2Array()
	
	# wall height constant
	var wall_height = 5
	
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
	meshinstance.mesh.surface_set_material(0, blue_stucco)
	meshinstance.mesh.surface_set_material(1, checkerboard)
	meshinstance.create_trimesh_collision()
	
	#spawn.translation = Vector3(player_spawn.x, 0, player_spawn.y)
