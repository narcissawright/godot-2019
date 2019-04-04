extends Area

func _ready():
	set_process(false)

func _on_DamageArea_body_entered(body):
	set_process(true)
	
func _on_DamageArea_body_exited(body):
	set_process(false)
	
func _process(delta):
	Game.player.health -= 1.5