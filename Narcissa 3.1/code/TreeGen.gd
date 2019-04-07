extends Spatial

var data : Dictionary = {
		'vertex' : [],
		'normal' : [],
		'color' : [],
		'index' : []
	}
var st = SurfaceTool.new()

func _ready():
	call_deferred("begin_generation")
	
func first_attempt():
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertex_data = []
	var verts = 0
	var faces = 0
	var maxloop = 10
	for k in range (maxloop):
		for i in range (6):
			st.add_color(ColorN('brown'))
			var new_v
			if vertex_data.size() >= 6:
				new_v = vertex_data[i + (k-1)*6] * 0.85
				var scatter = Vector3(randf()-0.5, 0, randf()-0.5).normalized() / (5 + k)
				new_v += scatter
			else:
				new_v = Vector3.LEFT.rotated(Vector3.UP, i+1 * PI / 3)
				var scatter = Vector3(randf()-0.5, 0, randf()-0.5).normalized() / 5
				new_v += scatter
			new_v.y = k
			vertex_data.append(new_v)
			st.add_vertex(new_v)
			verts += 1
			
		if k != maxloop-1:
			for i in range (6):
				var j = i + (6*k);
				st.add_index(j)
				st.add_index(j+6)
				st.add_index(j+1)
				faces += 1
				if i != 5:
					st.add_index(j+1)
					st.add_index(j+6)
					st.add_index(j+7)
					faces += 1
				else:
					st.add_index(j)
					st.add_index(j+1)
					st.add_index(j-5)
					faces += 1
					
	print (verts)
	print (faces)
	done()
	
func begin_generation():
	var total_control_points = floor(randf() * 4) + 3.0
	var tree_height = 10
	var control_points = [Vector3(0,0,0)]
	
	for i in range (1, total_control_points):
		var randx = (randf() - 0.5) * 4
		var randy = (float(i) / total_control_points) * tree_height + (randf() - 0.5)
		var randz = (randf() - 0.5) * 4
		control_points.append(Vector3(randx,randy,randz))
		
	st.begin(Mesh.PRIMITIVE_LINES)
	var max_range = 100.0
	for i in range (max_range):
		#var zero_one_interpolate = control_point_0.linear_interpolate(control_point_1, float(i)/max_range)
		#var one_two_interpolate = control_point_1.linear_interpolate(control_point_2, float(i)/max_range)
		#var bezier_point = zero_one_interpolate.linear_interpolate(one_two_interpolate, float(i)/max_range)
		
		var midpoints = control_points.duplicate()
		while midpoints.size() != 1:
			var new_midpoints = []
			for j in range (midpoints.size() - 1):
				new_midpoints.append(midpoints[j].linear_interpolate(midpoints[j+1], float(i) / max_range))
			midpoints = new_midpoints
		
		var bezier_point = midpoints[0]
		st.add_vertex(bezier_point)
		if i != 0 and i != max_range-1:
			st.add_vertex(bezier_point)
	done()

func initial_quad():
	create_triangle(Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1))
	create_triangle(Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(-1, 0, -1))

func create_triangle(v0, v1, v2):
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)
	data.vertex.append(v0)
	data.vertex.append(v1)
	data.vertex.append(v2)

func extrude_down():
	var vertex_array_size = data.vertex.size()
	for v in range (0, vertex_array_size, 3):
		var v0 = data.vertex[v] - Vector3(0, 0.1, 0)
		var v1 = data.vertex[v+1] - Vector3(0, 0.1, 0)
		var v2 = data.vertex[v+2] - Vector3(0, 0.1, 0)
		create_triangle(v0, v2, v1) # note the reversed winding order to make front face bottom

func _input(event):
	if Input.is_action_pressed("q"):
		begin_generation()

func done():
	#st.generate_normals()
	var arr_mesh = st.commit()
	arr_mesh.surface_set_name(0, 'Surface')
	var mesh_instance = $'MeshInstance'
	mesh_instance.mesh = arr_mesh
	mesh_instance.translation = Vector3(15, 0, -15)