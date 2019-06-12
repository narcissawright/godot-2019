extends Camera
const common = preload("res://code/common.gd") # common functions
var player_height_offset = Vector3(0, 1.20, 0)
const move_speed = 0.04
var resetting = false
var cam_reset_frame = 0.0
const cam_reset_time = 8.0 #frames @ 60fps
onready var body = $'../Body'
var current_zoom_type:String = 'medium'
var current_zoom_value:float = 3.0

onready var sphere_collider = preload('res://player/camera_sphere.tres')
var shape

const zoom_levels:Dictionary = {
		"near": 1.6,
		"medium": 2.8,
		"far": 4.0
	}

func nlerp(start:Vector3, end:Vector3, percent:float) -> Vector3:
#	... Guess I don't need this bit:
#	while abs(start.dot(end)) > 0.999:
#		start = (start + Vector3(rand_range(0.05, -0.05), rand_range(0.05, -0.05), rand_range(0.05, -0.05))).normalized()
	return lerp(start,end,percent).normalized()

func _ready():
	shape = PhysicsShapeQueryParameters.new()
	shape.collide_with_areas = false
	shape.collision_mask = 1
	shape.set_shape(sphere_collider)

func collider():
	var space_state = get_world().direct_space_state
	shape.transform = global_transform
	var result = space_state.get_rest_info(shape)
	
	if not result.empty(): # no collision
		Game.UI.update_topmsg("Collision")
		print(result)

func _process(delta):
	
	collider()
	
	if Input.is_action_just_pressed('R3'):
		match current_zoom_type:
			"medium":
				current_zoom_type = 'near'
			"near":
				current_zoom_type = 'far'
			"far":
				current_zoom_type = 'medium'
	
	if current_zoom_value != zoom_levels[current_zoom_type]:
		current_zoom_value = lerp(current_zoom_value, zoom_levels[current_zoom_type], 0.33)
		if abs(current_zoom_value - zoom_levels[current_zoom_type]) < 0.05:
			current_zoom_value = zoom_levels[current_zoom_type]
	
	var pushdir:Vector2 = common.deadzone(2, 3)
	var target:Vector3 = Game.player.global_transform.origin + player_height_offset
	var varying:Vector3 = self.global_transform.origin
	
	if resetting:
		#var goal_pos = Vector3(1,0.25,0).rotated(Vector3.UP, body.rotation.y).normalized()
		var goal_pos = Vector3(0,0.25,-1).rotated(Vector3.UP, body.rotation.y).normalized()
		var difference = (varying-target).normalized()
		varying = nlerp(difference, goal_pos, 1.0 / (cam_reset_time - cam_reset_frame))
		cam_reset_frame += 1.0
		varying = (varying * current_zoom_value) + target
		look_at_from_position(varying, target, Vector3.UP)
		if cam_reset_frame >= cam_reset_time:
			resetting = false
			cam_reset_frame = 0
	
	elif pushdir.length_squared() > 0.0:
		varying = (varying - target).normalized()
		var cross:Vector3 = varying.cross(Vector3.UP).normalized()
		varying = varying.rotated(Vector3.UP, -pushdir.x * move_speed)
		if (pushdir.y > 0.0 and varying.y > 0.0) or ((pushdir.y < 0.0 and varying.y < 0.0)):
			pushdir.y *= 1.0 - abs(varying.y)
		varying = varying.rotated(cross, pushdir.y * move_speed)
		varying.y = clamp(varying.y, -0.85, 0.85)
		varying *= current_zoom_value
		varying += target
		look_at_from_position(varying, target, Vector3.UP)
	
	else:
		varying = (varying-target).normalized() * current_zoom_value + target
		look_at_from_position(varying, target, Vector3.UP)

func reset_cam():
	if not resetting:
		resetting = true