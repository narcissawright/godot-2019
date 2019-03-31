extends MeshInstance
var total_time = 0.0
var edge_lines

func _ready():
	edge_lines = Game.decorator.create_edge_lines(mesh)
	add_child(edge_lines)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	total_time += delta
	if (Game.cam.global_transform.origin - global_transform.origin).length() < 0.5:
		pickup()
	rotate_y(deg2rad(2))
	translate(Vector3(0, sin(total_time) / 100.0, 0))
	edge_lines.material_override.set_shader_param("eye_position",Game.cam.global_transform.origin)

func pickup():
	Game.player.item_obtained("StrafeHelm")
	Game.UI.update_topmsg('Strafe Helm acquired.')
	Game.UI.get_node("StrafeHelmOverlay").enable()
	get_parent().call_deferred('free')