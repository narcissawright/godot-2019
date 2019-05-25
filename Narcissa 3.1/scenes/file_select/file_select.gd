extends Control

onready var file_button = preload("FileSelectButton.tscn")
onready var file_buttons:Array = []
onready var sfx = $'sfx'
var cursor_pos:int = 0
var time_elapsed:float = 0.0

func _ready():
	var dir = Directory.new()
	if dir.open('user://') == OK:
		dir.list_dir_begin(true) # skip navigational
		var path:String = dir.get_next()
		while path != '':
			file_buttons.append(file_button.instance())
			file_buttons[file_buttons.size() - 1].get_node('Text').bbcode_text = "[center]" + path + "[/center]"
			path = dir.get_next()
	else:
		print ("no user directory exists... somehow...")
	
	file_buttons.append(file_button.instance())
	file_buttons[file_buttons.size() - 1].get_node('Text').bbcode_text = "[center]New Game[/center]"
	for i in range (file_buttons.size()):
		file_buttons[i].margin_top = i * 60
		$FileButtons.add_child(file_buttons[i])
	select(0)
	
	connect("tree_exited", Game, "start_game")
	OS.move_window_to_foreground() # does this even work
	Game.scene = self
	Game.cam = $'Camera'

func _process(t):
	time_elapsed += t
	var flicker:float = 0.5
	if fmod(time_elapsed, 0.5) > 0.25:
		flicker = 0.55
	file_buttons[cursor_pos].get_node('ColorRect').modulate.a = flicker
	check_input()
	
func check_input():
	if Input.is_action_just_pressed("B") or Input.is_action_just_pressed('ui_cancel'):
		get_tree().quit()
	if Input.is_action_just_pressed("ui_up"):
		if cursor_pos == 0:
			sfx('error')
		else:
			deselect(cursor_pos)
			cursor_pos -= 1
			select(cursor_pos)
			sfx('up')
	if Input.is_action_just_pressed("ui_down"):
		if cursor_pos >= file_buttons.size() - 1:
			sfx('error')
		else:
			deselect(cursor_pos)
			cursor_pos += 1
			select(cursor_pos)
			sfx('down')
	if Input.is_action_just_pressed("ui_accept"):
		print(file_buttons[cursor_pos].get_node('Text').text)
	
func sfx(what):
	match what:
		'error':
			sfx.pitch_scale = 0.5
			sfx.volume_db = -20
			sfx.play()
		'up':
			sfx.volume_db = -16
			sfx.pitch_scale = 1.1
			sfx.play()
		'down':
			sfx.volume_db = -16
			sfx.pitch_scale = 1.0
			sfx.play()

func deselect(pos):
	file_buttons[pos].get_node('ColorRect').modulate.a = 0.1
	file_buttons[pos].get_node('Text').modulate.a = 0.5
	
func select(pos):
	file_buttons[pos].get_node('Text').modulate.a = 1.0
	
func exit_scene():
	call_deferred('free')
	set_process_input (false)
	set_process (false)
	Game.scene = null # without this, scene sometimes becomes a SpatialMaterial ... VERY WEIRD ...