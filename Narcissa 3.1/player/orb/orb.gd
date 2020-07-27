extends Spatial

onready var pos = $'Position'
onready var ig = $'debug_draw' #immediate geometry
onready var mesh = $'Position/Mesh'
onready var light = $'Position/OmniLight'
onready var tween = $'Position/Tween'
onready var sfx = $'collision_sfx'
onready var cursor = $'orb_canvas/cursor'

var power = 0.0
var orb_seek_range = 7.0
var state:String # ready, charging, launched

# physics
var velocity = Vector3()
var initial_impulse = Vector3()

var launch_time:float = 0.0
const MAX_LAUNCH_TIME = 4.0

var target_list = []
var target_dir = Vector3()

func change_state(new_state:String, launch_dir:=Vector3()):
	state = new_state
	match state:
		"ready":
			power = 0.0
			launch_time = 0.0
			
			visible = false
			cursor.target_list = []
			cursor.update()
			
			set_process(false)
			set_physics_process(false)
			
		"charge":
			tween.interpolate_property(light, "light_energy", 0, 0.75, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.interpolate_property(mesh, "scale", Vector3(0.2,0.2,0.2), Vector3(0.8,0.8,0.8), 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.interpolate_property(mesh.get_surface_material(0), 'shader_param/transparency', 0.0, 1.0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			
			visible = true
			
			set_process(true)
			set_physics_process(false)
		
		"launch":
			tween.stop_all()
			if power < 0.2:
				change_state("ready")
			else:
				if power > 1.0:
					power = 1.0
				
				#populate_target_list()
				var speed = clamp(1.0 / power, 1.0, 2.5)
				initial_impulse = launch_dir * 7.0 * speed
				
				set_physics_process(true)

func _ready():
	change_state("ready")

func _process(t):
	if state == 'charge':
		power += t
		pos.global_transform = Game.player.orb_pos.global_transform
	
	if state == 'ready':
		cursor.target_list = []
	else:
		target_dir = new_obtain_targets()
		cursor.target_list = target_list
		
	cursor.update()
	#debug_draw2()
	
func debug_draw2():
	ig.clear()
	for i in range (target_list.size()):
		var t_pos = target_list[i].target_pos
		var aabb_pos = target_list[i].aabb.position
		var aabb_end = target_list[i].aabb.end
		var aabb_size = target_list[i].aabb.size

		ig.begin(Mesh.PRIMITIVE_LINES)
		ig.set_color(Color(1,0,0))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, 0, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, 0, 0))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, 0, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, aabb_size.y, 0))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, 0, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, 0, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, 0, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, 0))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, 0, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, 0, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, aabb_size.y, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, aabb_size.y, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, aabb_size.y, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, 0))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, 0, aabb_size.z))
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, aabb_size.y, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, 0, aabb_size.z))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, 0, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(0, aabb_size.y, aabb_size.z))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, 0, aabb_size.z))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, aabb_size.z))
		
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, 0))
		ig.add_vertex(t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, aabb_size.z))
		
		
		ig.end()
	
# only during Launch
func _physics_process(t):
	launch_time += t
	if launch_time > MAX_LAUNCH_TIME:
		change_state("ready")
	else:
		if initial_impulse != Vector3(0,0,0):
			velocity = initial_impulse
			initial_impulse = Vector3(0,0,0)
		else:
			var v_length = clamp(velocity.length(), 3.0, 10.0)
			velocity += (target_dir / (3.0 * (1.0 / power)))
			if velocity.length() > v_length:
				velocity = velocity.normalized() * v_length
		
		var frame_movement = velocity * t
		var space_state = get_world().direct_space_state
		var from = pos.global_transform.origin
		var to = from + frame_movement
		# collision flag: 1 = walls, 16 = enemies
		var result = space_state.intersect_ray(from, to, [], 17)
		if result.size() > 0:
			sfx.play()
			change_state("ready")
		pos.translation += frame_movement

# runs every frame while orb is charging or launched
func new_obtain_targets() -> Vector3:
	target_list = []
	var orb_pos = pos.global_transform.origin
	var target_nodes = get_tree().get_nodes_in_group("target")
	
	var seek_index = -1 # -1 for not seeking
	var shortest = orb_seek_range
	
	for i in range(target_nodes.size()):
		
		var target_pos = target_nodes[i].global_transform.origin
		var length = (orb_pos - target_pos).length()
		var parent = target_nodes[i].get_parent()
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(orb_pos, target_pos, [], 1)
		var blocked = false
		if result.size() > 0:
			blocked = true
		
		var target_info = {
			"node": target_nodes[i],
			"aabb" : parent.get_aabb(), # sadly have to use parent to find the aabb size
			"name": parent.name,
			"target_pos": target_pos,
			"length": length,
			"blocked": blocked,
			"move_vector": -(orb_pos - target_pos).normalized(),
			"seeking" : false
		}
		
		target_list.append(target_info)
		
		if length < shortest and !blocked:
			shortest = length
			seek_index = i
			
	if seek_index > -1:
		target_list[seek_index].seeking = true
	
	if seek_index > -1:
		return (target_list[seek_index].move_vector)
	else:
		return Vector3()



# I need to be populating this once per frame maybe
# I hope get_nodes_in_group isnt costly
#func populate_target_list():
#	target_list = []
#	var target_node_list = get_tree().get_nodes_in_group("targetable")
#	for i in range(target_node_list.size()):
#		var target_info = {
#			"node": target_node_list[i],
#
#			# I don't like how I am reliant on a particular node structure to obtain this info:
#			"size" : target_node_list[i].get_parent().get_aabb().size,
#			"name": target_node_list[i].get_parent().name,
#
#			"pos": target_node_list[i].global_transform.origin
#		}
#		target_list.append(target_info)
#
#func choose_target():
#	ig.clear()
#	var nearest_target = -1
#	var shortest = 7.0
#	var draw_list = []
#
#	for i in range (target_list.size()):
#		var start = pos.global_transform.origin
#		var end = target_list[i].pos
#		var length = (start-end).length()
#		var space_state = get_world().direct_space_state
#		var result = space_state.intersect_ray(start, end, [], 1)
#		var blocked = false
#		if result.size() > 0:
#			#print(result.collider.get_parent().name)
#			blocked = true
#
#		draw_list.append({
#			"orb_pos" : start,
#			"target_pos" : end,
#			"length" : length,
#			"blocked" : blocked,
#			"move_vector" : -(start-end).normalized(),
#			"nearest_target" : false
#		})
#		if length < shortest and !blocked:
#			shortest = length
#			nearest_target = i 
#
#	if nearest_target > -1:
#		draw_list[nearest_target].nearest_target = true
#
##	debug_draw(draw_list)
#
#	cursor.draw_list = draw_list
#	cursor.update()
#
#	if nearest_target > -1:
#		return (draw_list[nearest_target].move_vector)
#	else:
#		return Vector3()
#
#func debug_draw(draw_list):
#	for i in range (draw_list.size()):
#		ig.begin(Mesh.PRIMITIVE_LINES)
#		if draw_list[i].nearest_target:
#			ig.set_color(Color(0.3,1,0.5))
#		elif draw_list[i].blocked == true:
#			ig.set_color(Color(1,0,0))
#		else:
#			ig.set_color(Color(0.4,0,0.8))
#		ig.add_vertex(draw_list[i].orb_pos)
#		ig.add_vertex(draw_list[i].target_pos)
#		ig.end()
