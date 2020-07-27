extends Control

var paused:bool = false
onready var options = $'bg/TextSelect'
var current_option:int = 0
var pos_min:int = 0
var pos_max:int = 2

func _process(t):
	if not paused and Input.is_action_just_pressed("PLUS"):
			current_option = 0
			paused = true
			Game.player.lockplayerinput = true
			show()
	elif paused:
		if Input.is_action_just_pressed('ui_accept'):
			perform(current_option)
			return
		
		if Input.is_action_just_pressed('ui_up'):
			if current_option > pos_min:
				current_option -= 1
				update_ui()
		elif Input.is_action_just_pressed('ui_down'):
			if current_option < pos_max:
				current_option += 1
				update_ui()
		
func update_ui():
	var splitoptions:PoolStringArray = options.bbcode_text.split('\n')
	for i in range (pos_max+1):
		if i == current_option:
			splitoptions[i+1] = splitoptions[i+1].replacen('#808080', '#ffffff')
		else:
			splitoptions[i+1] = splitoptions[i+1].replacen('#ffffff', '#808080')
	options.bbcode_text = splitoptions.join('\n')

func unpause():
	paused = false
	Game.player.lockplayerinput = false
	hide()

func perform(option:int):
	match option:
		0:
			unpause()
		1:
			pass
		2: 
			Game.player.lockplayer = true
			paused = false
			hide()
			Game.save_and_quit()
			set_process(false)
