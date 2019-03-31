extends Sprite

var paused = false

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") and !Game.player.lockplayerinput:
		if (paused):
			Game.player.lockplayer = true
			paused = false
			hide()
			get_tree().paused = false
			Game.save_and_quit()
		else:
			paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			show()
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if (paused):
			paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			hide()