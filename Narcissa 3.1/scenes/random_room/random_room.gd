extends Spatial

onready var meshgen = $"MeshGen"
onready var map = $"Canvas/Map"

func _ready():
	map.generate()
	Game.UI.fadein()
	Game.player.lockplayer = false
	Game.player.lockplayerinput = false

func _input(event):
	if event.is_action_pressed("MINUS"): #Space
		map.generate()
		Game.respawn()
