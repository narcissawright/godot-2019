extends Control

onready var symbol_bg = preload("name_entry_key.tscn")
onready var sfx = $'../sfx'
var chosen_name = ''
onready var name_node = $'name'
onready var keyboard = $'Keyboard'
var passed_time = 0.0
var cursor_pos = Vector2(0,0)
onready var lit_tex = preload('name_entry_key_highlighted.png')
onready var unlit_tex = preload('name_entry_key.png')
var up_held = 0.0
var down_held = 0.0
var left_held = 0.0
var right_held = 0.0
var B_held = 0.0
var prior_pos = Vector2(0,0)

const MAX_NAME_LENGTH = 16
const HOLD_DELAY = 0.3
const HOLD_REDELAY = 0.066666666

var key_layout:Array = [
	['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
	['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'],
	['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '@', '#', '_', '&', '!', '?', '.', ',', '\'', '(', ')', '*', 'â€“', '+', '/'],
]

#var key_layout:Array = [
#	['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', ' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'],
#	['n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', ' ', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
#	['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', 'í ¼í½†'],
#	['!', '@', '#', '$', '%', '^', '&', '*', '+', '=', 'â€“', '~', '.', ',', '!', '?', '(', ')', '[', ']', '<', '>', '{', '}', "'", '"', '/']
#]

func _ready():
	set_process(false)
	set_process_input(false)
	for i in range (key_layout.size()):
		for j in range (key_layout[i].size()):
			var instance = symbol_bg.instance()
			instance.position.y = ((i+1) * 44) + 10
			instance.position.x = (j * 44)
			instance.get_child(0).text = key_layout[i][j]
			keyboard.add_child(instance)
			
func activate():
	visible = true
	chosen_name = ''
	set_process(true)
	set_process_input(true)
	update_key()
	
func update_key():
	keyboard.get_child(prior_pos.x + (26 * prior_pos.y)).texture = unlit_tex
	keyboard.get_child(prior_pos.x + (26 * prior_pos.y)).get_child(0).modulate = Color('3a54a8')
	keyboard.get_child(cursor_pos.x + (26 * cursor_pos.y)).texture = lit_tex
	keyboard.get_child(cursor_pos.x + (26 * cursor_pos.y)).get_child(0).modulate = Color(1,1,1)
	prior_pos = cursor_pos
	
func _process(t):
	passed_time += t
	if fmod(passed_time, 0.5) > 0.25:
		name_node.bbcode_text = chosen_name + '[color=#303040]|[/color]'
	else:
		name_node.bbcode_text = chosen_name + '[color=#404050]|[/color]'
		
	if Input.is_action_just_pressed('B'):
		if len(chosen_name) == 0:
			deactivate()
		else:
			chosen_name = chosen_name.substr(0, len(chosen_name) - 1)
			sfx.play_sound('down')
	if Input.is_action_pressed('B'):
		if len(chosen_name) != 0:
			B_held += t
			if B_held > HOLD_DELAY:
				chosen_name = chosen_name.substr(0, len(chosen_name) - 1)
				B_held = HOLD_DELAY - HOLD_REDELAY
				sfx.play_sound('down')
	else:
		B_held = 0.0
	
	if Input.is_action_just_pressed('ui_up'):
		try('up')
	if Input.is_action_pressed('ui_up'):
		up_held += t
		if up_held > HOLD_DELAY:
			try('up')
			up_held = HOLD_DELAY - HOLD_REDELAY
	else:
		up_held = 0.0
			
	if Input.is_action_just_pressed('ui_down'):
		try('down')
	if Input.is_action_pressed('ui_down'):
		down_held += t
		if down_held > HOLD_DELAY:
			try('down')
			down_held = HOLD_DELAY - HOLD_REDELAY
	else:
		down_held = 0.0
		
	if Input.is_action_just_pressed('ui_left'):
		try('left')
	if Input.is_action_pressed('ui_left'):
		left_held += t
		if left_held > HOLD_DELAY:
			try('left')
			left_held = HOLD_DELAY - HOLD_REDELAY
	else:
		left_held = 0.0
		
	if Input.is_action_just_pressed('ui_right'):
		try('right')
	if Input.is_action_pressed('ui_right'):
		right_held += t
		if right_held > HOLD_DELAY:
			try('right')
			right_held = HOLD_DELAY - HOLD_REDELAY
	else:
		right_held = 0.0
		
	if Input.is_action_just_pressed('A'):
		if len(chosen_name) < MAX_NAME_LENGTH:
			var key = keyboard.get_child(cursor_pos.x + (26 * cursor_pos.y)).get_child(0).text
			if len(chosen_name) == 0 and key == ' ':
				print("Space first")
			elif chosen_name.substr(len(chosen_name) - 1, 1) == ' ' and key == ' ':
				print("Double Space")
			else:
				chosen_name = chosen_name + key
				sfx.play_sound('up')

	if Input.is_action_just_pressed("PLUS"):
		chosen_name = chosen_name.strip_edges()
		if len(chosen_name) > 2:
			var dir = Directory.new()
			Game.data = {
				"id": str(OS.get_unix_time()) + rand_string(),
				"name": chosen_name,
				"playtime": 0.0
			}
			Game.make_dir('user://' + Game.data.id)
			get_parent().start_game()
			free()

func rand_string() -> String:
	var rand_string:String
	var options := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	for i in range (5):
		rand_string += options[randi() % 36]
	return rand_string

#func _input(event):
#	if event is InputEventKey:
#		if len(chosen_name) < MAX_NAME_LENGTH:
#			if event.is_pressed() and event.is_echo() == false:
#				var key = event.unicode
#				var keySymbol = char(key)
#				if key >= 32 and key <= 126: #proper range
#					chosen_name += keySymbol

func try(dir):
	match dir:
		'up':
			cursor_pos.y -= 1
		'down':
			cursor_pos.y += 1
		'left':
			cursor_pos.x -= 1
		'right':
			cursor_pos.x += 1
	if cursor_pos.y < 0:
		cursor_pos.y = 2;
	elif cursor_pos.y > 2:
		cursor_pos.y = 0
	if cursor_pos.x < 0:
		cursor_pos.x = 25
	elif cursor_pos.x > 25:
		cursor_pos.x = 0
	update_key()
	sfx.play_sound('update_key')

func deactivate():
	cursor_pos = Vector2(0,0)
	get_parent().activate()
	visible = false
	set_process(false)