extends MeshInstance
signal plucked
var no_hover = 0
var edge_lines
onready var unshaded = preload('res://level_objects/narcissa_flower/unshaded.tres')
onready var shaded = preload('res://level_objects/narcissa_flower/Material.material')
onready var pop = $'pop'

func _ready():
	set_process(false)

func interact():
	Game.player.health += 5 * scale.y
	Game.UI.update_topmsg("You plucked the flower.")
	pop.pitch_scale = (1 / scale.y) * 1.3
	pop.play()
	var index = get_index()
	emit_signal("plucked", index)
	
func hover():
	#mesh.surface_set_material(0, unshaded)
	set_material_override(unshaded)
	no_hover = 1
	set_process(true)
	
func _process(delta):
	#rotation.y.slerp (  , 1.0 )
	if no_hover == 0:
		set_material_override(null)
		set_process(false)
		return
	no_hover -= 1