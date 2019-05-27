extends Control

onready var file_button = preload("FileSelectButton.tscn")
onready var file_buttons_node = $'FileButtons'
onready var playtime_node = $'FileButtons/TimePlayed'
onready var name_entry = $'NameEntry'
onready var controller_info = $'ControllerInfo'
onready var sfx = $'sfx'

var file_buttons:Array = []
var cursor_pos:int = 0
var time_elapsed:float = 0.0

func _ready():
	controller_info.text = Game.detect_joypads()
	var dir = Directory.new()
	var file = File.new()
	if dir.open('user://') == OK:
		dir.list_dir_begin(true) # skip navigational
		var path:String = dir.get_next()
		while path != '':
			if file.file_exists('user://' + path + '/data.save'):
				file.open('user://' + path + '/data.save', File.READ)
				var userdata = JSON.parse(file.get_line()).result
				file.close()
				file_buttons.append({
					'id': userdata.id,
					'name': userdata.name, 
					'instance': file_button.instance(), 
					'playtime': userdata.playtime
				})
				file_buttons.back().instance.get_node('Text').bbcode_text = "[center]" + userdata.name + "[/center]"
			else:
				file_buttons.append({
					'id': null,
					'name': '[color:#1111FF]Corrupt Save[/color]', 
					'instance': file_button.instance(), 
					'playtime': -1.0
				})
				file_buttons.back().instance.get_node('Text').bbcode_text = "[center][color=#FF1111]Corrupt Save[/color][/center]"
			path = dir.get_next()

	for i in range (file_buttons.size()):
		file_buttons[i].instance.margin_top = i * 60
		file_buttons_node.add_child(file_buttons[i].instance)
	
	file_buttons.append({
		'id': 'new_game', 
		'instance': file_button.instance(),
		'playtime': -1.0
	})
	file_buttons.back().instance.get_node('Text').bbcode_text = "[center]New Game[/center]"
	if file_buttons.size() > 1:
		file_buttons.back().instance.margin_top = (file_buttons.size() * 60) - 30
	file_buttons_node.add_child(file_buttons.back().instance)
	file_buttons.append({
		'id': 'quit', 
		'instance': file_button.instance(),
		'playtime': -1.0
	})
	file_buttons.back().instance.get_node('Text').bbcode_text = "[center]Quit[/center]"
	file_buttons.back().instance.margin_top = file_buttons[file_buttons.size()-2].instance.margin_top + 60
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
#	if Input.is_action_just_pressed("B") or Input.is_action_just_pressed('ui_cancel'):
#		get_tree().quit()
	if Input.is_action_just_pressed("ui_up"):
		if cursor_pos == 0:
			sfx.play_sound('error')
		else:
			deselect(cursor_pos)
			cursor_pos -= 1
			select(cursor_pos)
			sfx.play_sound('up')
	if Input.is_action_just_pressed("ui_down"):
		if cursor_pos >= file_buttons.size() - 1:
			sfx.play_sound('error')
		else:
			deselect(cursor_pos)
			cursor_pos += 1
			select(cursor_pos)
			sfx.play_sound('down')
	if Input.is_action_just_pressed("ui_accept"):
		if file_buttons[cursor_pos].id == 'new_game':
			deactivate()
		elif file_buttons[cursor_pos].id == 'quit':
			get_tree().quit()
		else:
			if file_buttons[cursor_pos].id != null:
				Game.data = {
					"id": file_buttons[cursor_pos].id,
					"name": file_buttons[cursor_pos].name,
					"playtime": file_buttons[cursor_pos].playtime
				}
				start_game()
				
func start_game():
	$'Background'.free() # over 9000 errors if I don't do this.
	Game.start_game()
	call_deferred('free')
	set_process (false)
	Game.scene = null # without this, scene sometimes becomes a SpatialMaterial ... VERY WEIRD ...

func deactivate():
	name_entry.activate()
	file_buttons_node.visible = false
	controller_info.visible = false
	set_process(false)
	
func activate():
	file_buttons_node.visible = true
	controller_info.visible = true
	set_process(true)

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