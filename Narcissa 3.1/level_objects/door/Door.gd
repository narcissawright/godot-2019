extends MeshInstance
var no_hover = 0
var unlocking = false 
const common = preload("res://code/common.gd")
onready var mat = load('res://level_objects/door/door_material.tres')
var lit_mat
var color_name

func _ready():
	mat = mat.duplicate()
	color_name = get_parent().color
	var color_value = common.colorvalue(color_name)
	mat.albedo_color = color_value
	lit_mat = mat.duplicate()
	lit_mat.emission_enabled = true
	lit_mat.emission = mat.albedo_color
	lit_mat.emission_energy = 0.1
	set_surface_material(0, mat)
	get_parent().get_node('Frame').set_surface_material(0, mat)
	set_process(false)

func interact():
	if !unlocking:
		if Game.current_item == color_name + '_key':
			var cap_name = color_name.capitalize()
			Game.UI.update_topmsg("You use the " + cap_name + " Key.")
			unlock()
		elif Game.current_item == 'skeleton_key':
			Game.UI.update_topmsg('You use the Skeleton Key.')
			unlock()
		else:
			Game.UI.update_topmsg("You don't have the appropriate key.")

func unlock():
	unlocking = true
	Game.UI.remove_current_item()
	no_hover = 20
	set_process(true)

func hover(is_hovering):
	# first time this runs, it lags.
	# i might procrastinate on this because:
	# when godot switches to Vulkan I think dealing with this crap will be much easier.
	if is_hovering:
		set_material_override(lit_mat)
	else:
		set_material_override(null)
	
func _process(delta):
	if unlocking:
		translation.y -= 0.04
		no_hover += 1
		if no_hover > 50: # after moving down 2 units, free it
			set_material_override(null)
			queue_free()
