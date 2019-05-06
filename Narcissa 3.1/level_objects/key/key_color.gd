extends Spatial
export(String) var color = 'white'
const common = preload("res://code/common.gd")
onready var mesh_instance = $'MeshInstance'
onready var area = $'MeshInstance/Area'
onready var mat = preload('res://materials/toonshader.tres')

func _ready():
	area.connect("body_entered", $floating_item, '_item_get', [color + '_key'])
	var dupe = mat.duplicate()
	dupe.set_shader_param('use_color_override', true)
	dupe.set_shader_param('color_override', common.colorvalue(color))
	mesh_instance.set_surface_material(0, dupe)