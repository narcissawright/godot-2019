extends Spatial
var total_time = 0.0
onready var item_node = get_parent().get_node('MeshInstance')
onready var lights = $'Lights'
onready var area = $'Area'
var is_obtained = false
var local_edge_lines

func _process(delta):
	total_time += delta
	item_node.rotate_y(deg2rad(2))
	if !is_obtained:
		item_node.translate(Vector3(0, sin(total_time) / 100.0, 0))
	else:
		local_edge_lines.material_override.set_shader_param("eye_position",Game.UI.ItemCam.global_transform.origin)

func _item_get(node, item):
	if node.name == 'Player' and Game.current_item == null:
		Game.UI.update_topmsg("You got the " + item.capitalize() + ".")
		call_deferred('die_item', item)

func die_item(item):
	area.free()
	lights.free()
	Game.current_item = item
	var node = get_parent()
	node.area.free() # PARENT node requires a node reference called 'area' or else this breaks.
	node.get_parent().remove_child(node)
	is_obtained = true
	local_edge_lines = item_node.get_node('EdgeLines')
	local_edge_lines.material_override = local_edge_lines.material_override.duplicate()
	local_edge_lines.material_override.set_shader_param("opacity", 0.5)
	item_node.translation = Vector3(0,1,0)
	item_node.remove_from_group('has_edge_lines')
	Game.UI.obtain_item(node)

func _enable_light(body):
	lights.show()

func _disable_light(body):
	lights.hide()
