extends Area

func _ready():
	set_process(false)

func _on_DamageArea_body_entered(body):
	set_process(true)
	
func _on_DamageArea_body_exited(body):
	set_process(false)
	
func _process(delta):
	if Game.player.health <= 0.0:
		# feels a bit dumb I have to do this to prevent this 
		# from running for an extra frame upon respawn.
		set_process(false)
		return
	Game.player.health -= 1.5