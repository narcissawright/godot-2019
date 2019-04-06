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
	
func begin_generation():
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var root_origin = Vector3(0,0,0)
	var v = Vector3.LEFT
	var vertex_data = []
	for i in range (6):
		st.add_color(ColorN('brown'))
		var new_v = v.rotated(Vector3.UP, i+1 * PI / 3)
		var scatter = Vector3(randf(), 0, randf()).normalized() / 3
		new_v += scatter
		vertex_data.append(new_v)
		st.add_vertex(new_v)
	for i in range (6):
		st.add_color(ColorN('brown'))
		var new_v = vertex_data[i] * 0.8
		new_v.y += 0.75
		var scatter = Vector3(randf(), 0, randf()).normalized() / 3
		new_v += scatter
		st.add_vertex(new_v)

	for i in range (6):
		st.add_index(i)
		st.add_index(i+6)
		st.add_index(i+1)
		if i != 5:
			st.add_index(i+1)
			st.add_index(i+6)
			st.add_index(i+7)
		else:
			st.add_index(i)
			st.add_index(i+1)
			st.add_index(i-5)
			
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
	
func done():
	st.generate_normals()
	var arr_mesh = st.commit()
	arr_mesh.surface_set_name(0, 'Surface')
	var mesh_instance = $'MeshInstance'
	mesh_instance.mesh = arr_mesh
	mesh_instance.translation = Vector3(15, 0, -15)