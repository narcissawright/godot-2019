extends Spatial
export(String) var color = 'white'
onready var mesh_instance = $'MeshInstance'
onready var area = $'MeshInstance/Area'
onready var mat = preload('res://level_objects/key/key_mat.tres')

func _ready():
	area.connect("body_entered", $floating_item, '_item_get', ['skeleton_key'])
	var dupe = mat.duplicate()
	dupe.set_shader_param('light_color', ColorN('white'))
	mesh_instance.set_surface_material(0, dupe)