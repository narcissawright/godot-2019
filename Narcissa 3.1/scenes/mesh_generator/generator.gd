extends Spatial
onready var birdy = $'WorldEnvironment/BirdEye'
onready var mesh_instance = $'Level/Mesh'
var data : Dictionary = {
		'vertex' : [],
		'normal' : [],
		'color' : [],
		'index' : []
	}
var st = SurfaceTool.new()

func _ready():
	Game.UI.update_topmsg("Hello World")
	Game.UI.fadein()
	Game.cam.current = false
	Game.cam = birdy
	Game.player.lockplayerinput = false
	call_deferred("begin_generation")
	
func begin_generation():
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	initial_quad()
	extrude_down()
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
	st.index()
	st.generate_normals()
	var arr_mesh = st.commit()
	arr_mesh.surface_set_name(0, 'Surface')
	mesh_instance.mesh = arr_mesh

	notify_decorator()
	
func notify_decorator():
	Game.decorator.connect("decoration_complete", self, "decoration_complete")
	Game.decorator.begin_generation()
	Game.decorator.set_process(true)
	
func decoration_complete():
	Game.cam.current = false
	Game.cam = Game.player.get_node("Camera")
	Game.cam.current = true
	Game.player.lockplayer = false