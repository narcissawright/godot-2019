extends Control

onready var file_button = preload("FileSelectButton.tscn")
onready var file_buttons:Array = []
onready var file_buttons_node = $'FileButtons'
onready var playtime_node = $'FileButtons/TimePlayed'
onready var sfx = $'sfx'
var cursor_pos:int = 0
var time_elapsed:float = 0.0

func _ready():
	$ControllerInfo.text = Game.detect_joypads()
	var dir = Directory.new()
	var file = File.new()
	if dir.open('user://') == OK:
		dir.list_dir_begin(true) # skip navigational
		var path:String = dir.get_next()
		while path != '':
			var playtime = 0.0
			if file.file_exists('user://' + path + '/stats.save'):
				file.open('user://' + path + '/stats.save', File.READ)
				playtime = file.get_var()
				file.close()
			file_buttons.append({
				'name': path, 
				'instance': file_button.instance(), 
				'playtime': playtime 
			})
			file_buttons.back().instance.get_node('Text').bbcode_text = "[center]" + path + "[/center]"
			path = dir.get_next()

	for i in range (file_buttons.size()):
		file_buttons[i].instance.margin_top = i * 60
		file_buttons_node.add_child(file_buttons[i].instance)
	
	file_buttons.append({
		'name': 'New Game', 
		'instance': file_button.instance(),
		'playtime': -1.0
	})
	file_buttons.back().instance.get_node('Text').bbcode_text = "[center]New Game[/center]"
	if file_buttons.size() > 1:
		file_buttons.back().instance.margin_top = (file_buttons.size() * 60) - 30
	file_buttons_node.add_child(file_buttons.back().instance)
	
	select(0)
	OS.move_window_to_foreground() # does this even work
	Game.scene = self
	Game.cam = $'Camera'

func _process(t):
	time_elapsed += t
	var flicker:float = 0.5
	if fmod(time_elapsed, 0.5) > 0.25:
		flicker = 0.55
	file_buttons[cursor_pos].instance.get_node('ColorRect').modulate.a = flicker
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
		if file_buttons[cursor_pos].playtime == -1.0:
			print ("Make Name")
		else:
			Game.start_game(file_buttons[cursor_pos].name)
			Game.playtime = file_buttons[cursor_pos].playtime
			exit_scene()

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
	file_buttons[pos].instance.get_node('ColorRect').modulate.a = 0.1
	file_buttons[pos].instance.get_node('Text').modulate.a = 0.5
	
func select(pos):
	file_buttons[pos].instance.get_node('Text').modulate.a = 1.0
	if file_buttons[pos].playtime >= 0.0:
		playtime_node.visible = true
		playtime_node.margin_top = file_buttons[pos].instance.margin_top
		playtime_node.get_node("Text").bbcode_text = "[center]" + Game.readable_playtime(file_buttons[pos].playtime) + "[/center]"
	else:
		playtime_node.visible = false
	
func exit_scene():
	call_deferred('free')
	set_process (false)
	Game.scene = null # without this, scene sometimes becomes a SpatialMaterial ... VERY WEIRD ...