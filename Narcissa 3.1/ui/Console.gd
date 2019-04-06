extends Control
onready var textbox = $"TypeHere"
onready var messages = $"Messages"
var typed_msg = ''
var elapsed_time = 0.0
var open = false
var first_time_open = true
const SPECIAL_COLOR = "#808080"

func _input(event):
	if open and event is InputEventKey:
		if event.is_pressed() and event.is_echo() == false:
			var key = event.unicode
			var keySymbol = char(key)
			if key >= 32 and key <= 126: #proper range for my font
				typed_msg += keySymbol
			if Input.is_key_pressed(KEY_ENTER) and textbox.get_total_character_count() > 1:
				messages.bbcode_text += '\n' + timestamp()
				if (check_special_msg(typed_msg) == false):
					messages.bbcode_text += parse_msg(typed_msg)
				typed_msg = ''
			if Input.is_key_pressed(KEY_BACKSPACE):
				typed_msg = typed_msg.substr(0, typed_msg.length() - 1)

func timestamp():
	return '[color=#404040]' + Game.readable_playtime() + '- [/color]'

func update_console(msg):
	messages.bbcode_text += '\n' + timestamp() + '[color=' + SPECIAL_COLOR + ']' + msg + '[/color]'

func _process(delta):
	if open:
		if first_time_open:
			first_time_open = false
			first_time_open()
		elapsed_time += delta
		var color_string = "[color=#505080]|[/color]"
		if sin(elapsed_time * 5) > 0:
			color_string = "[color=#202050]|[/color]"
		textbox.bbcode_text = parse_msg(typed_msg) + color_string

func first_time_open():
	messages.bbcode_text += '\n' + timestamp()
	messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']COMMAND LIST: /fps, /clear, /quit, /aabb[/color]'

func parse_msg(msg):
	msg = msg.replace('[', '[' + '\u00A0') # sanitize bbcode
	#msg = msg.replace('*red*', '[color=#ff3535]')
	#msg = msg.replace('*blue*', '[color=#5555ff]')
	return msg
	
func check_special_msg(msg):
	match msg:
		"/aabb":
			if Game.DRAW_CURRENT_AABB == true:
				Game.DRAW_CURRENT_AABB = false;
				messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* AABBs hidden.[/color]'
			else:
				Game.DRAW_CURRENT_AABB = true;
				messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* AABBs shown.[/color]'
			return true
		"/quit", "/exit":
			Game.save_and_quit()
			messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* Quitting.[/color]'
			return true
		"/clear":
			messages.bbcode_text = ''
			return true
		"/fps":
			if Game.UI.fps == false:
				Game.UI.fps = true
				messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* Frames per second displayed.[/color]'
			else:
				Game.UI.fps = false
				messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* Frames per second hidden.[/color]'
			return true
		"/timescale":
			if Game.player.timescale == 100:
				Game.player.timescale = 1;
				messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* 1x timescale.[/color]'
			else:
				Game.player.timescale = 100;
				messages.bbcode_text += '[color=' + SPECIAL_COLOR + ']* 100x timescale.[/color]'
			return true
	return false