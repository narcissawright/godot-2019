extends Control

var paused = false

func _ready():
	set_process(false)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if (paused):
			Game.player.lockplayer = true
			paused = false
			hide()
			#get_tree().paused = false
			Game.save_and_quit()
		else:
			paused = true
			Game.player.lockplayerinput = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			#get_tree().paused = true
			show()
			#set_process(true)
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if (paused):
			paused = false
			Game.player.lockplayerinput = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			#get_tree().paused = false
			hide()