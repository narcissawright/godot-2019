extends CSGCombiner
var t = 0.0

func _process(d):
	t += d
	if t > 1.0:
		var arr_mesh = get_meshes()[1]
		var arrays = arr_mesh.surface_get_arrays(0)
		set_process(false)
		#for v in range (0, arrays[ArrayMesh.ARRAY_VERTEX], 3):
		#	print(arrays[ArrayMesh.ARRAY_VERTEX][v])
		#for v in range (0, arr_mesh[ArrayMesh.ARRAY_VERTEX], 3):
		#	print(arr_mesh[ArrayMesh.ARRAY_VERTEX][v])
		#var st = SurfaceTool.new()
		#st.create_from(arr_mesh, 0)
		#set_process(false)

#		st.index()
#		arr_mesh = st.commit()
#		get_parent().find_node('Mesh').mesh = arr_mesh
#		visible = false;
#		var mdt = MeshDataTool.new()
#		mdt.create_from_surface(arr_mesh, 0)
#		Game.UI.update_topmsg('There are ' + str(mdt.get_face_count()) + ' faces on the mesh.')
#		set_process(false)