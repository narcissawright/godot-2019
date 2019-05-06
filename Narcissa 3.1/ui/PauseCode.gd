extends Control

var paused:bool = false
onready var options = $'bg/TextSelect'
var position:int = 0
var pos_min:int = 0
var pos_max:int = 2

func _process(delta):
	if Input.is_action_just_pressed("PLUS"):
		if (paused):
			unpause()
		else:
			position = 0
			paused = true
			Game.player.lockplayerinput = true
			show()
	if paused:
		if Input.is_action_just_pressed('A'):
			perform(position)
		if Input.is_action_just_pressed('ui_up'):
			if position > pos_min:
				position -= 1
		elif Input.is_action_just_pressed('ui_down'):
			if position < pos_max:
				position += 1
				
		var splitoptions:PoolStringArray = options.bbcode_text.split('\n')
		for i in range (pos_max+1):
			if i == position:
				splitoptions[i+1] = splitoptions[i+1].replacen('#808080', '#ffffff')
			else:
				splitoptions[i+1] = splitoptions[i+1].replacen('#ffffff', '#808080')
		options.bbcode_text = splitoptions.join('\n')

func unpause():
	paused = false
	Game.player.lockplayerinput = false
	hide()

func perform(option):
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