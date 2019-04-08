extends Spatial

var data : Dictionary = {
		'vertex' : [],
		'normal' : [],
		'color' : [],
		'index' : []
	}
var lines = SurfaceTool.new()
onready var lines_instance = $'Lines'
var tree = SurfaceTool.new()
onready var tree_instance = $'Tree'

func _ready():
	call_deferred("begin_generation")

func begin_generation():
	var verts = lines()
	mesh(verts)
	done()

func lines():
	lines.begin(Mesh.PRIMITIVE_LINES)
	var bezier = Curve3D.new()
	var lavender = Color(1,0.85,1)
	var green = Color(0, 0.3, 0)
	var brown = ColorN('brown')
	var tree_height = float(11 + (randi() % 6))
	var tree_points = float(3 + (randi() % 3))
	
	for i in range (tree_points):
		var inout = Vector3()
		inout.x = (randf() - 0.5) / 5
		inout.y = 1.0/float(tree_points) * tree_height / 3
		inout.z = (randf() - 0.5) / 5
		
		var pos = Vector3()
		var prior_out = Vector3()
		if i != 0:
			prior_out = bezier.get_point_out(i-1)
		
		pos.x = prior_out.x + ((randf() - 0.5) * (float(i) / 2 / tree_points))
		pos.y = float(i) / tree_points * tree_height
		pos.z = prior_out.z + ((randf() - 0.5) * (float(i) / 2 / tree_points))
		bezier.add_point(pos, -inout, inout)
		
		lines.add_color(ColorN('blue'))
		lines.add_vertex(pos-inout)
		lines.add_color(ColorN('red'))
		lines.add_vertex(pos+inout)
	
	var verts = bezier.tessellate()
	for v in range (verts.size()):
		if v % 2 == 0 and v != 0:
			lines.add_color(green)
		else:
			lines.add_color(lavender)
		lines.add_vertex(verts[v])
		if v != 0 and v != verts.size() - 1:
			if v % 2 == 1:
				lines.add_color(green)
			else:
				lines.add_color(lavender)
			lines.add_vertex(verts[v])
	
	
	var prior_y = 0.0
	var total_branches = ceil(tree_height / 2.0)
	var branches = 0 
	var branch_arr = []
	for i in range (total_branches):
		branch_arr.append(i)
	var max_height = verts[verts.size()-1].y
	var min_height = max_height / 2.2
	var total_range = max_height - min_height
	var skip = floor(tree_points / 2.0)
	for i in range (total_branches):
		var height = total_range * (float(i) / float(total_branches)) + min_height
		var branch_pos = bezier.interpolate(skip, (float(i) / float(total_branches)))
		var amt = branch_arr[randi() % branch_arr.size()]
		branch_arr.erase(amt)
		var rotate_axis = Vector3.LEFT.rotated(Vector3.UP, amt)
		make_branch(branch_pos, rotate_axis)
		
		
		
#	for v in range (verts.size()):
#		if verts[v].y > min_height:
#			var perc = (verts[v].y - min_height) / total
#			if perc > float(branches) / float(total_branches):
#				var amt = branch_arr[randi() % branch_arr.size()]
#				branch_arr.erase(amt)
#				var rotate_axis = Vector3.LEFT.rotated(Vector3.UP, amt)
#				branches += 1
#				make_branch(verts[v], rotate_axis)

	return verts

func make_branch(start_pos, rotate_axis):

	var bezier = Curve3D.new()
	var lavender = Color(1,0.85,1)
	var green = Color(0, 0.3, 0)
	var branch_length = float(3 + (randi() % 2))
	var tree_points = float(3 + (randi() % 1))
	var rotate_amt = (PI / 2) - (randf() * (PI / 3))
	for i in range (tree_points):
		var inout = Vector3()
		inout.x = (randf() - 0.5) / 5
		inout.y = 1.0/float(tree_points) * branch_length / 3
		inout.z = (randf() - 0.5) / 5
		inout = inout.rotated(rotate_axis, rotate_amt)
		var pos = Vector3()
		var prior_out = Vector3()
		if i != 0:
			prior_out = bezier.get_point_out(i-1)
		pos.x = prior_out.x + ((randf() - 0.5) * (float(i) / 2 / tree_points))
		pos.y = float(i) / tree_points * branch_length
		pos.z = prior_out.z + ((randf() - 0.5) * (float(i) / 2 / tree_points))
		pos = pos.rotated(rotate_axis, rotate_amt)
		pos += start_pos
		bezier.add_point(pos, -inout, inout)
		
		lines.add_color(ColorN('blue'))
		lines.add_vertex(pos-inout)
		lines.add_color(ColorN('red'))
		lines.add_vertex(pos+inout)
		
	var verts = bezier.tessellate()
	for v in range (verts.size()):
		if v % 2 == 0 and v != 0:
			lines.add_color(green)
		else:
			lines.add_color(lavender)
		lines.add_vertex(verts[v])
		if v != 0 and v != verts.size() - 1:
			if v % 2 == 1:
				lines.add_color(green)
			else:
				lines.add_color(lavender)
			lines.add_vertex(verts[v])

func mesh(verts):
	tree.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertex_data = []
	var init_thickness = (randf() * 0.5) + 0.3
	for k in range (verts.size()):
		for i in range (6):
			tree.add_color(ColorN('brown'))
			var thickness = init_thickness - ((float(k) / float(verts.size())) * init_thickness / 2)
			# I need to not rotate around Vector3.UP but the normal plane of the curve at that point.
			var new_v = (Vector3.LEFT * thickness).rotated(Vector3.UP, i+1 * PI / 3) + verts[k]
			vertex_data.append(new_v)
			tree.add_vertex(new_v)
		if k != verts.size() - 1:
			for i in range (6):
				var j = i + (6*k);
				tree.add_index(j)
				tree.add_index(j+6)
				tree.add_index(j+1)
				if i != 5:
					tree.add_index(j+1)
					tree.add_index(j+6)
					tree.add_index(j+7)
				else:
					tree.add_index(j)
					tree.add_index(j+1)
					tree.add_index(j-5)

#func second_attempt():
#	st.begin(Mesh.PRIMITIVE_LINES)
#	var total_control_points = floor(randf() * 3) + 3.0
#	var tree_height = 10
#	var control_points = [Vector3(0,-0.01,0)]
#	for i in range (1, total_control_points):
#		var randx = (randf() - 0.5) * 4 * (float(i) / total_control_points)
#		var randy = (float(i) / total_control_points) * tree_height + (randf() - 0.5)
#		var randz = (randf() - 0.5) * 4 * (float(i) / total_control_points)
#		control_points.append(Vector3(randx,randy,randz))
#	#draw_bezier(control_points, "red")
#	var d1_size = control_points.size() - 1
#	var d1 = []
#	for i in range (d1_size):
#		d1.append(d1_size * (control_points[i+1] - control_points[i]))
#	#draw_bezier(d1, "green")
#	var d2_size = d1.size() - 1
#	var d2 = []
#	for i in range (d2_size):
#		d2.append(d2_size * (d1[i+1] - d1[i]))
#	var density = get_density(d2)
#	draw_bezier(control_points, density)
#	done()
#func get_density(control_points):
#	var max_range = 100.0
#	var density = []
#	for i in range (max_range):
#		var midpoints = control_points.duplicate()
#		while midpoints.size() != 1:
#			var new_midpoints = []
#			for j in range (midpoints.size() - 1):
#				new_midpoints.append(midpoints[j].linear_interpolate(midpoints[j+1], float(i) / max_range))
#			midpoints = new_midpoints
#		density.append(midpoints[0].length())
#	return density
#func draw_bezier(control_points, density):
#	var max_range = 100.0
#	for i in range (max_range):
#		var midpoints = control_points.duplicate()
#		while midpoints.size() != 1:
#			var new_midpoints = []
#			for j in range (midpoints.size() - 1):
#				new_midpoints.append(midpoints[j].linear_interpolate(midpoints[j+1], float(i) / max_range))
#			midpoints = new_midpoints
#		var bezier_point = midpoints[0]
#		st.add_color(Color(density[i] / 50.0, 0, 1 - (density[i] / 50.0), 1))
#		st.add_vertex(bezier_point)
#		if i != 0 and i != max_range-1:
#			st.add_color(Color(density[i] / 50.0, 0, 1 - (density[i] / 50.0), 1))
#			st.add_vertex(bezier_point)

func _input(event):
	if Input.is_action_just_pressed("q"):
		for i in range(0, tree_instance.get_child_count()):
			tree_instance.get_child(i).queue_free()
		begin_generation()

func done():
	var mesh_pos = Vector3(15, 0, -15)
	
	var arr_mesh_lines = lines.commit()
	arr_mesh_lines.surface_set_name(0, 'Surface')
	lines_instance.mesh = arr_mesh_lines
	lines_instance.translation = mesh_pos
	
	tree.generate_normals()
	var arr_mesh_tree = tree.commit()
	arr_mesh_tree.surface_set_name(0, 'Surface')
	tree_instance.mesh = arr_mesh_tree
	tree_instance.translation = mesh_pos
	Game.decorator.generate_edge_lines(tree_instance)
	tree_instance.create_trimesh_collision()
	Game.UI.update_topmsg("Press Q for a new tree!")