extends Control

var raycast_left
var raycast_right
var enabled = false


# Called when the node enters the scene tree for the first time.
func _ready():
	margin_right = Game.max_x
	margin_bottom = Game.max_y
	
func _process(delta):
	if enabled:
		update()
	
func enable():
	if enabled == true:
		return
	enabled = true
	print("Helmet Enabled.")

func disable():
	if enabled == false:
		return
		
	enabled = false
	if is_instance_valid(raycast_left):
		raycast_left.free()
	if is_instance_valid(raycast_right):
		raycast_right.free()

func screenclamp (n):
	n.x = clamp(n.x, 20, Game.max_x - 20)
	n.y = clamp(n.y, 20, Game.max_y - 20)
	return n
	
func _draw():
	if enabled:
		var angles = [Vector2(1, 0.9).angle(), Vector2(1, -0.9).angle()]
		for i in range (angles.size()):
			var player_pos = Game.cam.global_transform
			var pos = Game.cam.global_transform
			pos.origin = Vector3(0,0,0)
			pos.origin += player_pos.origin + pos.rotated(Vector3.UP, angles[i]).translated(Vector3.FORWARD).origin
			pos.origin.y = Game.cam.global_transform.origin.y
			var point_3d = pos.origin
			var point_2d = Game.cam.unproject_position(point_3d)
			var player2d = Game.cam.unproject_position(Game.player.global_transform.origin)
			var dim_color = Color(1,1,1,0.05)
			var pressed_color = Color(0.85, 0.05, 0.05, 0.75)
			var interpolation_amount = 0.15
			if player2d.y < point_2d.y:
				player2d = Vector2(point_2d.x, 10000)
			draw_line ( point_2d, player2d, dim_color, 4.0, false )
			if i == 0 and Game.UI.up_pressed and Game.UI.left_pressed and Game.UI.right_pressed == false and Game.UI.down_pressed == false:
				draw_line ( point_2d, player2d, pressed_color, 2.0, false )
			if i == 1 and Game.UI.up_pressed and Game.UI.left_pressed == false and Game.UI.right_pressed and Game.UI.down_pressed == false:
				draw_line ( point_2d, player2d, pressed_color, 2.0, false )