extends Spatial

func _ready():
	Game.UI.fadein()
	Game.player.lockplayer = false
	Game.player.lockplayerinput = false
