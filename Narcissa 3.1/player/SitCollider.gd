extends Area

func _on_SitCollider_body_entered(body):
	print("entered.")
	print (body)

func _on_SitCollider_body_exited(body):
	print("exited.")
