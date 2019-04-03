extends Spatial
const common = preload("res://code/common.gd")

func create_uvs(index, level):
	# UV UNWRAP:
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(level.mesh, index)
	mdt.set_material(load("res://materials/ice_new.tres"))

	var shared_edges = {}
	for i in range (mdt.get_edge_count()):
		var v1_i = mdt.get_edge_vertex(i, 0)
		var v2_i = mdt.get_edge_vertex(i, 1)
		var v1 = mdt.get_vertex(v1_i)
		var v2 = mdt.get_vertex(v2_i)
		var arr = [v1, v2]
		arr.sort()
		#upd_dict(shared_edges, arr, i)
	
	var is_face_set = [] # has a face been added to an island yet
	for face in range (mdt.get_face_count()):
		is_face_set.push_back(false) # set all faces to unset
		
		# all of my sad, failed, uv unwrap code.
	# the island code works though
	# as in, grouping faces by island
	# but, actually unwrapping is a nightmare.
	
#	var islands = [] # islands of faces
#	for face in range (mdt.get_face_count()): # start looping all faces
#		if is_face_set[face]: # if set
#			continue # skip to next iteration
#		var island = [face] # begin composing an island
#		var adjacent_check = true 
#		while adjacent_check: # continue checking adjacent faces
#			var e1 = mdt.get_face_edge(face, 0) # Edge 1
#			var e2 = mdt.get_face_edge(face, 1) # Edge 2
#			var e3 = mdt.get_face_edge(face, 2) # Edge 3
#			var edge_arr = [e1, e2, e3]
#			for j in range (edge_arr.size()): # loop over the 3 edges
#				var v1_i = mdt.get_edge_vertex(edge_arr[j], 0) # find vertex indices
#				var v2_i = mdt.get_edge_vertex(edge_arr[j], 1)
#				var v1 = mdt.get_vertex(v1_i) # and then find the vertex coordinates
#				var v2 = mdt.get_vertex(v2_i)
#				var arr = [v1, v2] # add the coordinate to array
#				arr.sort() # and sort it. sorted array is the shared_edges dict key
#				for k in range (shared_edges[arr].size()): # loop over the values in the dict
#					if shared_edges[arr][k] != edge_arr[j]: # if it finds a shared edge,
#						edge_arr.push_back(shared_edges[arr][k]) # add it to the edge array
#			var edge_faces = []
#			for j in range (edge_arr.size()): # loop over the edge array
#				edge_faces.push_back(mdt.get_edge_faces(edge_arr[j])) # and add all faces
#			edge_faces = common.flatten(edge_faces) # make it a 1D array
#			for j in range (edge_faces.size()): # and loop over it
#				if island.has(edge_faces[j]) == false: # if the island doesn't have the face
#					island.push_back(edge_faces[j]) # add it to the island
#			is_face_set[face] = true # this face is done
#			adjacent_check = false 
#			for j in range (island.size()):
#				if is_face_set[island[j]] == false:
#					face = island[j] # this face hasn't been checked yet
#					adjacent_check = true # so we're not done
#					break
#		islands.push_back(island) # add the island to the list of islands
#
#	var shared_verts = {}
#	for i in range (mdt.get_vertex_count()):
#		var pos = mdt.get_vertex(i)
#		upd_dict(shared_verts, pos, i)
#	print(shared_verts)
#	var position_uv_dict = {}
#	print (islands)
#	for island in range (islands.size()): # for each island...
#		print ("island " + str(island))
#		var face = 0
#		var normal = mdt.get_face_normal(face)
#		var new_axis_x = Vector3(0,0,0)
#		var setting_UVs = true
#		var completed_faces = []
#		var island_offset = Vector3(0,0,0)
#		var v1 = mdt.get_face_vertex(islands[island][face], 0) # get the 3 vertices
#		var v2 = mdt.get_face_vertex(islands[island][face], 1)
#		var v3 = mdt.get_face_vertex(islands[island][face], 2)
#
#		while setting_UVs: 
#			var vert_arr = [v1, v2, v3]
#			var vert_positions = []
#			for j in range (3): # for each vertex
#				var pos = mdt.get_vertex(vert_arr[j]) # get xyz position
#				vert_positions.push_back(pos)  # add position to position array
#			vert_positions.sort()
#			#print("VERTPOS: " + str(vert_positions))
#
#			var uv_set_count = 0
#			var vert_with_uv = []
#			for j in range (vert_positions.size()):
#				if position_uv_dict.has(vert_positions[j]): # check if any of their UVs have already been set
#					uv_set_count += 1
#					vert_with_uv.push_back(vert_positions[j])
#
#			if uv_set_count == 0:
#				island_offset = -vert_positions[0]
#				var new_vert_positions = []
#				for i in range (vert_positions.size()):
#					new_vert_positions.push_back(vert_positions[i] + island_offset)
#
#				new_axis_x = new_vert_positions[2].normalized()
#
#				var rotation_matrix = Basis(new_axis_x, new_axis_x.cross(normal).normalized(), normal)
#				var scalar = 0.2
#				var vertex_2d_positions = []
#
#				for i in range (new_vert_positions.size()):
#					var rotated_vert = rotation_matrix.xform_inv(new_vert_positions[i]) # + vert_positions[0]
#
#					var vert_2d = Vector2(rotated_vert.x, rotated_vert.y)
#					for k in range (shared_verts[vert_positions[i]].size()): # check if shared:
#						var index = shared_verts[vert_positions[i]][k]
#						mdt.set_vertex_uv(index, vert_2d * scalar)
#						position_uv_dict[vert_positions[i]] = mdt.get_vertex_uv(index)
#						print ("set UV #" + str(index) + " @ " + str(mdt.get_vertex_uv(index)))
#
#			elif uv_set_count == 2:
#				var final_vert = vert_positions.duplicate()
#				final_vert.erase(vert_with_uv[0])
#				final_vert.erase(vert_with_uv[1])
#				final_vert = final_vert[0]
#
#				var normal_diff = mdt.get_face_normal(face) - normal
#				normal = (normal + normal_diff).normalized()
#				new_axis_x = (new_axis_x + normal_diff).normalized()
#
#				island_offset = -vert_with_uv[0]
#
#				#var uv0 = position_uv_dict[vert_with_uv[0]]
##					var uv1 = position_uv_dict[vert_with_uv[1]]
##					var uv0to1 = uv1 - uv0
##					var axis_aligned = Vector3(uv0to1.x, 0, 0)
###					var angle = uv0to1.angle_to(axis_aligned)
###					var blah = final_vert - vert_with_uv[0]
###					new_axis_x = blah.rotated(normal, angle).normalized()
##					new_axis_x = axis_aligned
#
#				var rotation_matrix = Basis(new_axis_x, new_axis_x.cross(normal).normalized(), normal)
#				var scalar = 0.2
#				var vertex_2d_positions = []
#
#				var rotated_vert = rotation_matrix.xform_inv(final_vert + island_offset)
#				var vert_2d = Vector2(rotated_vert.x, rotated_vert.y)
#				#vert_2d += uv0
#				for k in range (shared_verts[final_vert].size()): # check if shared:
#					var index = shared_verts[final_vert][k]
#					mdt.set_vertex_uv(index, vert_2d * scalar)
#					position_uv_dict[final_vert] = mdt.get_vertex_uv(index)
#					print ("set UV #" + str(index) + " @ " + str(mdt.get_vertex_uv(index)))
#
#			elif uv_set_count == 1:
#				print ("I don't know how this happened, but I must fix it.")
#			elif uv_set_count == 3:
#				print ("no work to be done.")
#
#			completed_faces.push_back(face)
#
#			var faceset = false
#			for new_face in range (islands[island].size()):
##				if completed_faces.has(islands[island][new_face]):
##					continue
#				var has = 0
#				v1 = mdt.get_face_vertex(new_face, 0)
#				v2 = mdt.get_face_vertex(new_face, 1)
#				v3 = mdt.get_face_vertex(new_face, 2)
#				if position_uv_dict.has(mdt.get_vertex(v1)):
#					has += 1
#				if position_uv_dict.has(mdt.get_vertex(v2)):
#					has += 1
#				if position_uv_dict.has(mdt.get_vertex(v3)):
#					has += 1
#				if has == 2:
#					face = new_face
#					print ("face set: " + str(new_face))
#					faceset = true
#					break
#
#			if faceset == false:
#				setting_UVs = false


	# here's an earlier attempt at UV unwrapping, which sort-of works.
	# different normals are disconnected though, and it seems 
	# sometimes it fails to unwrap a face altogether.
	for face in range (mdt.get_face_count()):
		if is_face_set[face]:
			continue
		var normal = mdt.get_face_normal(face) # Face Normal
		var adjacent_check = true
		var faces = []
		var f_i = face
		while adjacent_check:
			var e1 = mdt.get_face_edge(f_i, 0) # Edge 1
			var e2 = mdt.get_face_edge(f_i, 1) # Edge 2
			var e3 = mdt.get_face_edge(f_i, 2) # Edge 3
			var e1_f = mdt.get_edge_faces(e1) # Edge 1 Faces
			var e2_f = mdt.get_edge_faces(e2) # Edge 2 Faces
			var e3_f = mdt.get_edge_faces(e3) # Edge 3 Faces
			var edge_faces = []
			edge_faces.push_back(e1_f)
			edge_faces.push_back(e2_f)
			edge_faces.push_back(e3_f)
			edge_faces = common.flatten(edge_faces)

			var adjacent_faces = []
			for i in range (edge_faces.size()):
				adjacent_faces.push_back(edge_faces[i])
			for i in range (adjacent_faces.size()):
				if mdt.get_face_normal(adjacent_faces[i]).dot(normal) < 0.99:
					pass
				elif faces.has(adjacent_faces[i]) == false:
					faces.push_back(adjacent_faces[i])

			is_face_set[f_i] = true
			var is_there_checking_to_do = false
			for i in range (faces.size()):
				if is_face_set[faces[i]] == false:
					f_i = faces[i]
					is_there_checking_to_do = true
			if is_there_checking_to_do == false:
				adjacent_check = false

		var vi_array = [] # vertex indices
		for i in range (faces.size()):
			if vi_array.has(mdt.get_face_vertex(faces[i], 0)) == false:
				vi_array.push_back(mdt.get_face_vertex(faces[i], 0))
			if vi_array.has(mdt.get_face_vertex(faces[i], 1)) == false:
				vi_array.push_back(mdt.get_face_vertex(faces[i], 1))
			if vi_array.has(mdt.get_face_vertex(faces[i], 2)) == false:
				vi_array.push_back(mdt.get_face_vertex(faces[i], 2))

		var vert_positions = []
		for i in range (vi_array.size()):
			vert_positions.push_back(mdt.get_vertex(vi_array[i]))
		var pos_copy = vert_positions.duplicate()
		pos_copy.sort()
		var new_vert_positions = []
		for i in range (vert_positions.size()):
			new_vert_positions.push_back(vert_positions[i] - pos_copy[0])

		# New axes for rotation
		var new_axis_x = new_vert_positions[1].normalized()
		var new_axis_y = new_axis_x.cross(normal).normalized()
		var new_axis_z = normal

		var rotation_matrix = Basis(new_axis_x, new_axis_y, new_axis_z)
		var scalar = 0.2
		# Vertices post-rotation
		var vertex_2d_positions = []
		for i in range (new_vert_positions.size()):
			var rotated_vert = rotation_matrix.xform_inv(new_vert_positions[i])
			var vert_2d = Vector2(rotated_vert.x, rotated_vert.y)
			mdt.set_vertex_uv(vi_array[i], vert_2d * scalar)

	level.mesh.surface_remove(index)
	mdt.commit_to_surface(level.mesh)
	level.mesh.surface_set_name(level.mesh.get_surface_count() - 1, "Ice")