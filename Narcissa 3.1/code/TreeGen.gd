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

const max_iterations:int = 4
var bezier_point_positions:Array = []
var total_branches:int = 0
var max_branches:int = 50
var vertex_data = []

var line_queue:Array = []

func _ready():
	call_deferred("begin_generation")

func run_line_queue(iteration):
	var current_queue = line_queue.duplicate()
	line_queue = []
	for i in range (current_queue.size()):
		lines(current_queue[i].pos, current_queue[i].grow_dir, iteration)
	if iteration < max_iterations:
		run_line_queue(iteration + 1)

func begin_generation():
	tree.begin(Mesh.PRIMITIVE_TRIANGLES)
	lines.begin(Mesh.PRIMITIVE_LINES)
	line_queue.append({'pos': Vector3(), 'grow_dir': Vector3.UP, 'iteration':0})
	run_line_queue(0)
	draw_shadow()
	done()

func get_hull(passed_point = Vector2(0,0)) -> PoolVector2Array:
	var point_cloud = PoolVector2Array()
	point_cloud.append(passed_point)
	for i in range (bezier_point_positions.size() - 1):
		point_cloud.append(Vector2(bezier_point_positions[i].x, bezier_point_positions[i].z))
	return Geometry.convex_hull_2d(point_cloud)
	
func get_hull_area(hull:PoolVector2Array) -> float:
	var add:float = 0.0
	var sub:float = 0.0
	for i in range (hull.size() - 1):
		add += hull[i].x * hull[i+1].y
		sub += hull[i+1].x * hull[i].y
	var area:float = abs(add - sub) / 2.0
	return area

func draw_shadow():
	var hull:PoolVector2Array = get_hull()
	for i in range (hull.size() - 1):
		lines.add_color(ColorN('orange'))
		lines.add_vertex(Vector3(hull[i].x, 0, hull[i].y))
		lines.add_color(ColorN('orange'))
		lines.add_vertex(Vector3(hull[i+1].x, 0, hull[i+1].y))
		
func slerp(v1:Vector3, v2:Vector3, t:float) -> Vector3:
	# thanks Nisovin
    var theta = v1.angle_to(v2)
    return v1.rotated(v1.cross(v2).normalized(), theta * t)

func lines(initial_pos:Vector3, grow_dir:Vector3, iteration:int):
	var rot_axis: = Vector3.UP.cross(grow_dir).normalized()
	if (grow_dir == Vector3.UP):
		rot_axis = Vector3.UP
	var dot:float = Vector3.UP.dot(grow_dir)
	var rot_amt:float = (-(dot - 1) / 2) * PI
	
	var bezier: = Curve3D.new()
	var max_branch_length:float = 10.0
	var min_branch_length:float = 6.0
	var branch_length:float = max_branch_length * (1.0 - (float(iteration) / float(max_iterations)))
	var rand_size_variance:float = randf() - 0.5
	branch_length = clamp(branch_length + rand_size_variance, min_branch_length, max_branch_length)
	var branch_scale:float = (branch_length - min_branch_length) / (max_branch_length - min_branch_length)
	var new_branch_chance:float = 0.7
	var min_bezier_points:int = 2
	var max_bezier_points:int = 3
	var bezier_point_count:int = min_bezier_points + round(branch_scale * float(max_bezier_points - min_bezier_points))
	var loop_count:int = bezier_point_count + (1 + (randi() % (max_iterations - iteration)))
#	var long_branch_cutoff:int = 3
#	if iteration > long_branch_cutoff:
#		loop_count = bezier_point_count
	
	for i in range (loop_count):
		var inout = Vector3()
		var curve_amount = 0.3
		inout.x = (randf() - 0.5) * curve_amount
		inout.y = 1.0 / float(loop_count) * branch_length / 3
		inout.z = (randf() - 0.5) * curve_amount
		if not rot_axis.is_normalized():
			print(rot_axis)
		inout = inout.rotated(rot_axis, rot_amt)
		
		var pos = Vector3()
		var prior_out = Vector3()
		if i != 0:
			prior_out = bezier.get_point_out(i-1)
		pos.x = prior_out.x + ((randf() - 0.5) * curve_amount) #(float(i) / 2 / loop_count))
		pos.y = (float(i) / float(loop_count - 1)) * branch_length
		pos.z = prior_out.z + ((randf() - 0.5) * curve_amount) #(float(i) / 2 / loop_count))
		pos = pos.rotated(rot_axis, rot_amt)
		pos += initial_pos
		
		bezier_point_positions.append(pos)
		bezier.add_point(pos, -inout, inout)
		
#		lines.add_color(ColorN('blue'))
#		lines.add_vertex(pos - inout)
#		lines.add_color(ColorN('red'))
#		lines.add_vertex(pos + inout)
		
		if (i == bezier_point_count - 1 or i == loop_count - 1) and iteration + 1 < max_iterations:
			if total_branches < max_branches:
				branch(pos, grow_dir, iteration)
				if randf() < new_branch_chance:
					branch(pos, grow_dir, iteration)
	
	var grey = Color(0.6, 0.6, 0.7)
	var dark_grey = Color(0.175, 0.125, 0.125)
	var verts = bezier.tessellate()
	mesh(verts, iteration)
#
#	for v in range (verts.size()):
#		if v % 2 == 0 and v != 0:
#			lines.add_color(grey)
#		else:
#			lines.add_color(dark_grey)
#		lines.add_vertex(verts[v])
#		if v != 0 and v != verts.size() - 1:
#			if v % 2 == 1:
#				lines.add_color(grey)
#			else:
#				lines.add_color(dark_grey)
#			lines.add_vertex(verts[v])

func branch(pos, grow_dir, iteration):
	var hull = get_hull()
	var hull_area = get_hull_area(hull)
	var new_grow_dir = grow_dir
	for i in range (5):
		var variance:Vector3 = Vector3(randf()-0.5, randf()-0.25, randf()-0.5) * 2
		var new_test_dir = (grow_dir + variance).normalized()
		var new_projection = bezier_point_positions.back() + new_test_dir
		var position_2D = Vector2(new_projection.x, new_projection.z)
		var new_hull = get_hull_area(get_hull(position_2D))
		if new_hull > hull_area or (i == 4 and new_grow_dir == grow_dir):
			hull_area = new_hull
			new_grow_dir = new_test_dir
#	lines.add_color(ColorN('orange'))
#	lines.add_vertex(pos)
#	lines.add_color(ColorN('orange'))
#	lines.add_vertex(pos + (new_grow_dir / 3))
	line_queue.append({'pos': pos, 'grow_dir': new_grow_dir, 'iteration':iteration + 1})
	total_branches += 1

func mesh(verts, iteration):
	var offset = vertex_data.size()
	#var init_thickness = (randf() * 0.5) + 0.3
	var init_thickness = 0.7 * (1.0 - (float(iteration) / (float(max_iterations) - 0.5)))
	for k in range (verts.size()):
		var angle_vector:Vector3
		if k == 0:
			angle_vector = verts[k] - verts[k+1]
		elif k == verts.size() - 1:
			angle_vector = verts[k - 1] - verts[k]
		else:
			angle_vector = (verts[k-1] - verts[k]).linear_interpolate(verts[k] - verts[k+1], 0.5)
		
		angle_vector = -angle_vector.normalized()
		var cross = angle_vector.cross(Vector3.LEFT).normalized()
		var first_point = angle_vector.rotated(cross, PI / 2)
		
		for i in range (6):
			tree.add_color(ColorN('brown'))
			var thickness = init_thickness - ((float(k) / float(verts.size())) * init_thickness / 2)
			# I need to not rotate around Vector3.UP but the normal plane of the curve at that point.
			var new_v = (first_point * thickness).rotated(angle_vector, i+1 * PI / 3) + verts[k]
			vertex_data.append(new_v)
			tree.add_vertex(new_v)
		if k != verts.size() - 1:
			for i in range (6):
				var j = i + (6*k);
				tree.add_index(j + offset)
				tree.add_index(j+6 + offset)
				tree.add_index(j+1 + offset)
				if i != 5:
					tree.add_index(j+1 + offset)
					tree.add_index(j+6 + offset)
					tree.add_index(j+7 + offset)
				else:
					tree.add_index(j + offset)
					tree.add_index(j+1 + offset)
					tree.add_index(j-5 + offset)


func _input(event):
	if Input.is_action_just_pressed("q"):
		for i in range(0, tree_instance.get_child_count()):
			tree_instance.get_child(i).queue_free()
		bezier_point_positions = []
		total_branches = 0
		vertex_data = []
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