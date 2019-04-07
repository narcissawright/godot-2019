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
	st.begin(Mesh.PRIMITIVE_LINES)
	var bezier = Curve3D.new()
	var lavender = Color(1,0.85,1)
	var green = Color(0, 0.3, 0)
	var tree_height = 10.0
	
	var randx = (randf() - 0.5)
	var randy = tree_height * (1 / 3) + (randf() - 0.5)
	var randz = (randf() - 0.5)
	bezier.add_point(Vector3(), Vector3(0, -1, 0), Vector3(randx, randy, randz))
	
	randx = (randf() - 0.5)
	randy = tree_height * (2 / 3) + (randf() - 0.5)
	randz = (randf() - 0.5)
	bezier.add_point(Vector3(0, tree_height, 0), Vector3(randx, randy, randz))
	
	var verts = bezier.tessellate()
	for v in range (verts.size()):
		if v % 2 == 0 and v != 0:
			st.add_color(green)
		else:
			st.add_color(lavender)
		st.add_vertex(verts[v])
		if v != 0 and v != verts.size() - 1:
			if v % 2 == 1:
				st.add_color(green)
			else:
				st.add_color(lavender)
			st.add_vertex(verts[v])
	done()
	
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
	
func second_attempt():
	st.begin(Mesh.PRIMITIVE_LINES)
	var total_control_points = floor(randf() * 3) + 3.0
	var tree_height = 10
	var control_points = [Vector3(0,-0.01,0)]
	for i in range (1, total_control_points):
		var randx = (randf() - 0.5) * 4 * (float(i) / total_control_points)
		var randy = (float(i) / total_control_points) * tree_height + (randf() - 0.5)
		var randz = (randf() - 0.5) * 4 * (float(i) / total_control_points)
		control_points.append(Vector3(randx,randy,randz))
	#draw_bezier(control_points, "red")
	var d1_size = control_points.size() - 1
	var d1 = []
	for i in range (d1_size):
		d1.append(d1_size * (control_points[i+1] - control_points[i]))
	#draw_bezier(d1, "green")
	var d2_size = d1.size() - 1
	var d2 = []
	for i in range (d2_size):
		d2.append(d2_size * (d1[i+1] - d1[i]))
	var density = get_density(d2)
	draw_bezier(control_points, density)
	done()
func get_density(control_points):
	var max_range = 100.0
	var density = []
	for i in range (max_range):
		var midpoints = control_points.duplicate()
		while midpoints.size() != 1:
			var new_midpoints = []
			for j in range (midpoints.size() - 1):
				new_midpoints.append(midpoints[j].linear_interpolate(midpoints[j+1], float(i) / max_range))
			midpoints = new_midpoints
		density.append(midpoints[0].length())
	return density
func draw_bezier(control_points, density):
	var max_range = 100.0
	for i in range (max_range):
		var midpoints = control_points.duplicate()
		while midpoints.size() != 1:
			var new_midpoints = []
			for j in range (midpoints.size() - 1):
				new_midpoints.append(midpoints[j].linear_interpolate(midpoints[j+1], float(i) / max_range))
			midpoints = new_midpoints
		var bezier_point = midpoints[0]
		st.add_color(Color(density[i] / 50.0, 0, 1 - (density[i] / 50.0), 1))
		st.add_vertex(bezier_point)
		if i != 0 and i != max_range-1:
			st.add_color(Color(density[i] / 50.0, 0, 1 - (density[i] / 50.0), 1))
			st.add_vertex(bezier_point)

func _input(event):
	if Input.is_action_just_pressed("q"):
		begin_generation()

func done():
	#st.generate_normals()
	var arr_mesh = st.commit()
	arr_mesh.surface_set_name(0, 'Surface')
	var mesh_instance = $'MeshInstance'
	mesh_instance.mesh = arr_mesh
	mesh_instance.translation = Vector3(15, 0, -15)
	Game.UI.update_topmsg("Press Q for new curves!")