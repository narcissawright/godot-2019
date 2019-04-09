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

const max_iterations = 4
var bezier_point_positions = []

func _ready():
	call_deferred("begin_generation")

func begin_generation():
	tree.begin(Mesh.PRIMITIVE_TRIANGLES)
	lines.begin(Mesh.PRIMITIVE_LINES)
	lines(Vector3(), Vector3.UP, 0)
	done()

func slerp(v1 : Vector3, v2 : Vector3, t : float) -> Vector3:
	# thanks Nisovin
    var theta = v1.angle_to(v2)
    return v1.rotated(v1.cross(v2).normalized(), theta * t)

func lines(initial_pos, rotation_axis, iteration):
	var bezier = Curve3D.new()
	var max_branch_length = 5.0
	var min_branch_length = 1.0
	var branch_length = max_branch_length * (1.0 - (iteration / max_iterations))
	var rand_size_variance = randf() - 0.5
	branch_length = clamp(branch_length + rand_size_variance, min_branch_length, max_branch_length)
	var branch_scale = (branch_length - min_branch_length) / (max_branch_length - min_branch_length)
	var new_branch_chance = 0.8
	var min_bezier_points = 2
	var max_bezier_points = 4
	var slerp_amount = 0.1
	var bezier_points = min_bezier_points + round(branch_scale * (max_bezier_points - min_bezier_points))
	# need some kind of spherical space-filling thing
	for i in range (bezier_points):
		var inout = Vector3()
		var curve_amount = 0.3
		inout.x = (randf() - 0.5) * curve_amount
		inout.y = 1.0/float(bezier_points) * branch_length / 3
		inout.z = (randf() - 0.5) * curve_amount
		inout = inout.rotated(rotation_axis, PI / 2)
#		if inout.length() != 0:
#			var inout_slerped = slerp(inout.normalized(), Vector3.DOWN, slerp_amount)
#			inout = inout_slerped * inout.length()
		var pos = Vector3()
		var prior_out = Vector3()
		if i != 0:
			prior_out = bezier.get_point_out(i-1)
		pos.x = prior_out.x + ((randf() - 0.5) * (float(i) / 2 / bezier_points))
		pos.y = float(i) / bezier_points * branch_length
		pos.z = prior_out.z + ((randf() - 0.5) * (float(i) / 2 / bezier_points))
		pos = pos.rotated(rotation_axis, PI / 2)
		pos += initial_pos
#		if pos.length() != 0:
#			var pos_slerped = slerp(pos.normalized(), Vector3.DOWN, slerp_amount)
#			pos = pos_slerped * pos.length()
		bezier_point_positions.append(pos)
		bezier.add_point(pos, -inout, inout)
		lines.add_color(ColorN('blue'))
		lines.add_vertex(pos - inout)
		lines.add_color(ColorN('red'))
		lines.add_vertex(pos + inout)
		if (i == bezier_points - 1) and iteration < max_iterations:
			# BRANCH
			var x_total = 0.0
			var z_total = 0.0
			for i in range (bezier_point_positions.size()):
				x_total += bezier_point_positions[i].x
				z_total += bezier_point_positions[i].z
			var best_dir = -Vector3(x_total, 0, z_total).normalized()
			
			lines.add_color(ColorN('orange'))
			lines.add_vertex(pos)
			lines.add_color(ColorN('orange'))
			lines.add_vertex(pos + best_dir)
			
			
			
			var new_rotation_axis = best_dir #.rotated(rotation_axis, PI / 2)
			lines(pos, new_rotation_axis, iteration+1)
			if randf() < new_branch_chance:
				# BRANCH
				x_total = 0.0
				z_total = 0.0
				for i in range (bezier_point_positions.size()):
					x_total += bezier_point_positions[i].x
					z_total += bezier_point_positions[i].z
				best_dir = -Vector3(x_total, 0, z_total).normalized()
			
				new_rotation_axis = best_dir #.rotated(rotation_axis, PI / 2)
				lines(pos, new_rotation_axis, iteration+1)
	
	var lavender = Color(1,0.85,1)
	var green = Color(0, 0.3, 0)
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


func _input(event):
	if Input.is_action_just_pressed("q"):
		for i in range(0, tree_instance.get_child_count()):
			tree_instance.get_child(i).queue_free()
		bezier_point_positions = []
		begin_generation()

func done():
	var mesh_pos = Vector3(15, 0, -15)
	
	var arr_mesh_lines = lines.commit()
	arr_mesh_lines.surface_set_name(0, 'Surface')
	lines_instance.mesh = arr_mesh_lines
	lines_instance.translation = mesh_pos
	
#	tree.generate_normals()
#	var arr_mesh_tree = tree.commit()
#	arr_mesh_tree.surface_set_name(0, 'Surface')
#	tree_instance.mesh = arr_mesh_tree
#	tree_instance.translation = mesh_pos
#	Game.decorator.generate_edge_lines(tree_instance)
#	tree_instance.create_trimesh_collision()

	Game.UI.update_topmsg("Press Q for a new tree!")
	
	
	
#func lines_old():
#	lines.begin(Mesh.PRIMITIVE_LINES)
#	var bezier = Curve3D.new()
#	var lavender = Color(1,0.85,1)
#	var green = Color(0, 0.3, 0)
#	var tree_height = float(11 + (randi() % 6))
#	var tree_points = float(3 + (randi() % 3))
#
#	for i in range (tree_points):
#		var inout = Vector3()
#		inout.x = (randf() - 0.5) / 5
#		inout.y = 1.0/float(tree_points) * tree_height / 3
#		inout.z = (randf() - 0.5) / 5
#
#		var pos = Vector3()
#		var prior_out = Vector3()
#		if i != 0:
#			prior_out = bezier.get_point_out(i-1)
#
#		pos.x = prior_out.x + ((randf() - 0.5) * (float(i) / 2 / tree_points))
#		pos.y = float(i) / tree_points * tree_height
#		pos.z = prior_out.z + ((randf() - 0.5) * (float(i) / 2 / tree_points))
#		bezier.add_point(pos, -inout, inout)
#
#		lines.add_color(ColorN('blue'))
#		lines.add_vertex(pos-inout)
#		lines.add_color(ColorN('red'))
#		lines.add_vertex(pos+inout)
#
#	var verts = bezier.tessellate()
#	for v in range (verts.size()):
#		if v % 2 == 0 and v != 0:
#			lines.add_color(green)
#		else:
#			lines.add_color(lavender)
#		lines.add_vertex(verts[v])
#		if v != 0 and v != verts.size() - 1:
#			if v % 2 == 1:
#				lines.add_color(green)
#			else:
#				lines.add_color(lavender)
#			lines.add_vertex(verts[v])
#
#	var total_branches = ceil(tree_height / 2.0)
#	var branch_arr = []
#	for i in range (total_branches):
#		branch_arr.append(i)
#	var drawn_branches = 0
#
#	for i in range (tree_points - 1):
#		var current_height = float(i) / float(tree_points)
#		var next_height = float(i+1) / float(tree_points)
#		if (next_height) > 0.45:
#			var difference = next_height - current_height
#			var midpoint = next_height - (difference / 2.0)
#			var branches = float(total_branches) * (difference / 0.55)
#			#(midpoint - 0.65)
#			for j in range (branches):
#				var branch_pos = bezier.interpolate(i, float(j) / float(branches))
#				var amt = branch_arr[randi() % branch_arr.size()]
#				branch_arr.erase(amt)
#				var rotate_axis = Vector3.LEFT.rotated(Vector3.UP, amt)
#				make_branch(branch_pos, rotate_axis)
#				drawn_branches += 1
#
#	print (drawn_branches)
#	print (total_branches)
#	return verts
#
#func make_branch(start_pos, rotate_axis):
#
#	var bezier = Curve3D.new()
#	var lavender = Color(1,0.85,1)
#	var green = Color(0, 0.3, 0)
#	var branch_length = float(3 + (randi() % 2))
#	var tree_points = float(3 + (randi() % 1))
#	var rotate_amt = (PI / 2) - (randf() * (PI / 3))
#	for i in range (tree_points):
#		var inout = Vector3()
#		inout.x = (randf() - 0.5) / 5
#		inout.y = 1.0/float(tree_points) * branch_length / 3
#		inout.z = (randf() - 0.5) / 5
#		inout = inout.rotated(rotate_axis, rotate_amt)
#		var pos = Vector3()
#		var prior_out = Vector3()
#		if i != 0:
#			prior_out = bezier.get_point_out(i-1)
#		pos.x = prior_out.x + ((randf() - 0.5) * (float(i) / 2 / tree_points))
#		pos.y = float(i) / tree_points * branch_length
#		pos.z = prior_out.z + ((randf() - 0.5) * (float(i) / 2 / tree_points))
#		pos = pos.rotated(rotate_axis, rotate_amt)
#		pos += start_pos
#		bezier.add_point(pos, -inout, inout)
#
#		lines.add_color(ColorN('blue'))
#		lines.add_vertex(pos-inout)
#		lines.add_color(ColorN('red'))
#		lines.add_vertex(pos+inout)
#
#	var verts = bezier.tessellate()
#	for v in range (verts.size()):
#		if v % 2 == 0 and v != 0:
#			lines.add_color(green)
#		else:
#			lines.add_color(lavender)
#		lines.add_vertex(verts[v])
#		if v != 0 and v != verts.size() - 1:
#			if v % 2 == 1:
#				lines.add_color(green)
#			else:
#				lines.add_color(lavender)
#			lines.add_vertex(verts[v])

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