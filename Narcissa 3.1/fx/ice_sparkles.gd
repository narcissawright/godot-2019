extends CanvasLayer
const common = preload("res://code/common.gd")
var sprite = preload("res://fx/AnimatedSparkle.tscn")
var sparkles = []
var verts # set by Decorator
var trios # set by Decorator

func _ready():
	new_sparkles()

func new_sparkles():
	var total_area = 0.0
	var area_list = []

	for i in range (0, trios.size(), 3):
		var v1 = Game.cam.unproject_position(verts[trios[i]])
		var v2 = Game.cam.unproject_position(verts[trios[i+1]])
		var v3 = Game.cam.unproject_position(verts[trios[i+2]])
		v1.x = clamp(v1.x, 0.0, Game.max_x)
		v1.y = clamp(v1.y, 0.0, Game.max_y)
		v2.x = clamp(v2.x, 0.0, Game.max_x)
		v2.y = clamp(v2.y, 0.0, Game.max_y)
		v3.x = clamp(v3.x, 0.0, Game.max_x)
		v3.y = clamp(v3.y, 0.0, Game.max_y)

		if Game.cam.is_position_behind(verts[trios[i]]):
			v1 = Vector2(Game.max_x - v1.x, Game.max_y - v1.y)
		if Game.cam.is_position_behind(verts[trios[i+1]]):
			v2 = Vector2(Game.max_x - v2.x, Game.max_y - v2.y)
		if Game.cam.is_position_behind(verts[trios[i+2]]):
			v3 = Vector2(Game.max_x - v3.x, Game.max_y - v3.y)

		var area = common.tri_area(Vector3(v1.x, v1.y, 0), Vector3(v2.x, v2.y, 0), Vector3(v3.x, v3.y, 0))
		total_area += area
		area_list.push_back(total_area)

	if total_area == 0.0:
		return
	var sparkle_total = ceil(total_area / 10000)
	#Game.UI.stats_line_2 = str(sparkle_total) + " ice sparkles."
	while sparkle_total - sparkles.size() > 0:
		var a = randf() * total_area
		for i in range (area_list.size()):
			if a < area_list[i]:
				var pos = common.sample_tri(verts[trios[i*3]], verts[trios[(i*3)+1]], verts[trios[(i*3)+2]])
				var normal = common.get_normal(verts[trios[i*3]], verts[trios[(i*3)+1]], verts[trios[(i*3)+2]])
				pos -= normal/10
				var sparkle = get_sparkle()
				sparkle.translation = pos
				sparkle.frame = 0
				sparkles.push_back(sparkle)
				break

var sparkle_pool = []

func get_sparkle():
	if sparkle_pool.empty():
		var sparkle = sprite.instance()
		add_child(sparkle)
		return sparkle
	else:
		return sparkle_pool.pop_back()

func free_sparkle(sparkle):
	sparkle_pool.append(sparkle)

func _process(delta):
	if sparkles.size() == 0 and randi() % 10 == 0:
		new_sparkles()
		return
	for i in range (sparkles.size()):
		if sparkles[i].playing == false and randi() % 10 == 0:
			sparkles[i].play()
		elif sparkles[i].frame == 10 and randi() % 10 == 0:
			free_sparkle(sparkles[i])
			sparkles.remove(i)
			new_sparkles()
			break