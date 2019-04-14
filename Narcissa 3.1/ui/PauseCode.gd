extends Control

var paused = false
onready var clickdot = $'../ClickDot'

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if (paused):
			paused = false
			Game.player.lockplayerinput = false
			clickdot.rect_position = Vector2((Game.max_x / 2) - 1, (Game.max_y / 2) - 1)
			hide()
		else:
			paused = true
			Game.player.lockplayerinput = true
			show()
	if paused:
		if Input.is_action_just_released('left_click'):
			check(clickdot.rect_position, true)
		if event is InputEventMouseMotion:
			var mouse_movement = event.relative
			clickdot.rect_position.x = clamp(clickdot.rect_position.x + mouse_movement.x, 0, Game.max_x - 2)
			clickdot.rect_position.y = clamp(clickdot.rect_position.y + mouse_movement.y, 0, Game.max_y - 2)
			check(clickdot.rect_position)
	# if quit:
#		Game.player.lockplayer = true
#		paused = false
#		hide()
#		Game.save_and_quit()
		
func check(pos:Vector2, click:bool=false):
	var testbox = $'testbox'
	var testbox_rect = Rect2(testbox.rect_position, testbox.rect_size)
	if testbox_rect.has_point(pos):
		if click:
			testbox.pressed = !testbox.pressed
			Game.UI.fps = testbox.pressed
		else:
			testbox.modulate = Color(0.5, 0.5, 1.0, 1.0)
	else:
		testbox.modulate = Color(1.0, 1.0, 1.0, 1.0)