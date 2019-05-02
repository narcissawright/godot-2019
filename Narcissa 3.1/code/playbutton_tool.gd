#Failure. controller unrecognized when not running.
tool
extends Node

func _input(event):
	print(str(randf()))
	if event is InputEventJoypadButton:
		print('u')
		if event.button_index == 10:
			var ev = InputEvent.new()
			ev.type = InputEvent.KEY
			ev.scancode = KEY_F5
			get_tree().input_event(ev)
			print ('F5')