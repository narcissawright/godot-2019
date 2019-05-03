extends Camera
const common = preload("res://code/common.gd") # common functions
const player_height_offset = Vector3(0, 1.5, 0)
const move_speed = 0.04

func _process(delta):
	var pushdir:Vector2 = common.deadzone(2, 3)
	if pushdir.length_squared() > 0.0:
		var varying:Vector3 = self.global_transform.origin
		var target:Vector3 = Game.player.global_transform.origin + player_height_offset
		varying = (varying - target).normalized()
		var cross:Vector3 = varying.cross(Vector3.UP).normalized()
		varying = varying.rotated(Vector3.UP, -pushdir.x * move_speed)
		if (pushdir.y > 0.0 and varying.y > 0.0) or ((pushdir.y < 0.0 and varying.y < 0.0)):
			pushdir.y *= 1.0 - abs(varying.y)
		varying = varying.rotated(cross, pushdir.y * move_speed)
		varying.y = clamp(varying.y, -0.85, 0.85)
		varying *= 3.0
		varying += target
		look_at_from_position(varying, target, Vector3.UP)
		#rotation.x = clamp(Game.cam.rotation.x, deg2rad(-85), deg2rad(85))
		
func reset_cam():
	print("Resetcam")
	