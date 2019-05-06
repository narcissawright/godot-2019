extends VBoxContainer
var hp_bar_length = 500
onready var hp_bar = $'hp_container/hp_bar'
onready var hp_loss = $'hp_container/hp_loss'

func update_meter(what:String, value:float):
	if what == "health":
		hp_bar_length = round(value * 5.0)
		if hp_bar.rect_size.x < 0:
			set_bar(hp_bar, 0)
		if hp_bar_length < hp_bar.rect_size.x:
			set_bar(hp_bar, hp_bar_length)
		else:
			set_bar(hp_loss, hp_bar_length)

func set_bar(obj, value):
	if value <= 0:
		#9Patches can't be 0 size, so I hide them.
		obj.visible = false
		obj.rect_size.x = 2
	else:
		obj.visible = true
		obj.rect_size.x = value

func _process(t):
	if hp_bar.rect_size.x < hp_bar_length:
		set_bar(hp_bar, min(hp_bar.rect_size.x + 5, hp_bar_length))
	if hp_loss.rect_size.x > hp_bar_length:
		set_bar(hp_loss, max(hp_loss.rect_size.x - 5, hp_bar_length))