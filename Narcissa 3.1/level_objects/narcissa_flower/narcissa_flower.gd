extends MeshInstance
signal plucked
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
	
func hover(is_hovering):
	if is_hovering:
		set_material_override(unshaded)
	else:
		set_material_override(null)
	